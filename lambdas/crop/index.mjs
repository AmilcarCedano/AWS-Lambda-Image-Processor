import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3 = new S3Client({});
const BUCKET = process.env.S3_BUCKET;
const PROCESSED_PREFIX = process.env.PROCESSED_PREFIX || "processed/";

/**
 * Converts an S3 readable stream to a Buffer.
 */
async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

/**
 * Creates a circular SVG mask for the given dimensions.
 */
function createCircleMask(width, height) {
  const r = Math.min(width, height) / 2;
  return Buffer.from(
    `<svg width="${width}" height="${height}">
      <circle cx="${r}" cy="${r}" r="${r}" fill="white"/>
    </svg>`
  );
}

/**
 * Processes a single SQS record:
 * 1. Parses S3 event notification from the SQS message
 * 2. Downloads the original image from S3
 * 3. Resizes to 40x40 with cover fit
 * 4. Applies circular mask for transparent background
 * 5. Outputs PNG to processed/ prefix
 */
async function processRecord(record) {
  const sqsBody = JSON.parse(record.body);

  // S3 event notifications can contain multiple records
  const s3Records = sqsBody.Records || [];

  for (const s3Record of s3Records) {
    const srcBucket = s3Record.s3.bucket.name;
    const srcKey = decodeURIComponent(s3Record.s3.object.key.replace(/\+/g, " "));

    console.log("Processing image", { srcBucket, srcKey });

    // Download original image
    const getResult = await s3.send(
      new GetObjectCommand({ Bucket: srcBucket, Key: srcKey })
    );
    const imageBuffer = await streamToBuffer(getResult.Body);

    // Create circular mask
    const mask = createCircleMask(40, 40);

    // Resize and apply circular mask
    const processedImage = await sharp(imageBuffer)
      .resize(40, 40, { fit: "cover" })
      .composite([
        {
          input: mask,
          blend: "dest-in",
        },
      ])
      .png({ quality: 100 })
      .toBuffer();

    // Build output key: replace uploads/ prefix and add _circular suffix
    const originalName = srcKey.split("/").pop().split(".")[0];
    const outputKey = `${PROCESSED_PREFIX}${originalName}_circular.png`;

    // Upload processed image
    await s3.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: outputKey,
        Body: processedImage,
        ContentType: "image/png",
        ServerSideEncryption: "AES256",
        Metadata: {
          "source-key": srcKey,
          "dimensions": "40x40",
          "shape": "circular",
        },
      })
    );

    console.log("Processing complete", {
      srcKey,
      outputKey,
      outputSize: processedImage.length,
    });
  }
}

/**
 * Lambda handler — processes SQS batch with partial failure reporting.
 * Returns batchItemFailures so only failed messages are retried.
 */
export const handler = async (event) => {
  console.log(`Crop Lambda invoked with ${event.Records.length} records`);

  const batchItemFailures = [];

  for (const record of event.Records) {
    try {
      await processRecord(record);
    } catch (err) {
      console.error("Failed to process record", {
        messageId: record.messageId,
        error: err.message,
      });
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  // ReportBatchItemFailures — only failed messages go back to the queue
  return { batchItemFailures };
};
