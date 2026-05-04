import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import Busboy from "busboy";
import { v4 as uuidv4 } from "uuid";

const s3 = new S3Client({});
const BUCKET = process.env.S3_BUCKET;
const PREFIX = process.env.UPLOAD_PREFIX || "uploads/";

const ALLOWED_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
]);
const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

/**
 * Parses a multipart/form-data request body using Busboy.
 * Returns an object with file buffer, filename, and content type.
 */
function parseMultipart(event) {
  return new Promise((resolve, reject) => {
    const contentType =
      event.headers["content-type"] || event.headers["Content-Type"];

    const bb = Busboy({
      headers: { "content-type": contentType },
      limits: { fileSize: MAX_SIZE, files: 1 },
    });

    let fileBuffer = Buffer.alloc(0);
    let fileName = "";
    let mimeType = "";
    let truncated = false;

    bb.on("file", (_fieldname, stream, info) => {
      fileName = info.filename;
      mimeType = info.mimeType;

      stream.on("data", (chunk) => {
        fileBuffer = Buffer.concat([fileBuffer, chunk]);
      });

      stream.on("limit", () => {
        truncated = true;
      });
    });

    bb.on("finish", () => {
      if (truncated) {
        return reject(new Error("File exceeds maximum size of 10 MB"));
      }
      resolve({ buffer: fileBuffer, fileName, mimeType });
    });

    bb.on("error", reject);

    // Decode the body — API Gateway sends base64-encoded body for binary
    const body = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body);

    bb.end(body);
  });
}

/**
 * Parses a JSON body with base64-encoded image data.
 */
function parseJSON(event) {
  const body = JSON.parse(
    event.isBase64Encoded
      ? Buffer.from(event.body, "base64").toString()
      : event.body
  );

  const { image, filename, contentType } = body;

  if (!image || !filename || !contentType) {
    throw new Error("JSON body must include: image (base64), filename, contentType");
  }

  return {
    buffer: Buffer.from(image, "base64"),
    fileName: filename,
    mimeType: contentType,
  };
}

export const handler = async (event) => {
  console.log("Upload Lambda invoked", {
    method: event.requestContext?.http?.method,
    path: event.requestContext?.http?.path,
  });

  try {
    const contentType =
      event.headers?.["content-type"] || event.headers?.["Content-Type"] || "";

    let fileData;

    if (contentType.includes("multipart/form-data")) {
      fileData = await parseMultipart(event);
    } else if (contentType.includes("application/json")) {
      fileData = parseJSON(event);
    } else {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          error: "Unsupported Content-Type. Use multipart/form-data or application/json",
        }),
      };
    }

    // Validate MIME type
    if (!ALLOWED_TYPES.has(fileData.mimeType)) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          error: `File type '${fileData.mimeType}' not allowed. Allowed: jpg, png, gif, webp`,
        }),
      };
    }

    // Validate file size
    if (fileData.buffer.length > MAX_SIZE) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          error: "File exceeds maximum size of 10 MB",
        }),
      };
    }

    // Generate unique S3 key
    const ext = fileData.fileName.split(".").pop() || "bin";
    const key = `${PREFIX}${uuidv4()}.${ext}`;

    // Upload to S3
    await s3.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: fileData.buffer,
        ContentType: fileData.mimeType,
        ServerSideEncryption: "AES256",
        Metadata: {
          "original-filename": fileData.fileName,
        },
      })
    );

    console.log("Upload successful", { key, size: fileData.buffer.length });

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "Image uploaded successfully",
        key,
        size: fileData.buffer.length,
        contentType: fileData.mimeType,
      }),
    };
  } catch (err) {
    console.error("Upload failed", err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};
