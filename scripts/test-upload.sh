#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# Test Upload Script
# Usage: ./scripts/test-upload.sh <api-url> [image-path]
# Example: ./scripts/test-upload.sh https://abc123.execute-api.us-east-1.amazonaws.com ./test.jpg
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

API_URL=${1:-""}
IMAGE=${2:-""}

if [[ -z "$API_URL" ]]; then
  echo "❌ Error: API URL required"
  echo "Usage: ./scripts/test-upload.sh <api-url> [image-path]"
  echo ""
  echo "Get the URL with: cd terraform && terraform output -raw upload_url"
  exit 1
fi

# If no image provided, create a test image
if [[ -z "$IMAGE" ]]; then
  echo "📸 No image provided. Creating a test PNG..."
  # Create a minimal valid PNG (1x1 red pixel)
  printf '\x89PNG\r\n\x1a\n' > /tmp/test-image.png
  # Use ImageMagick if available, otherwise use a base64 approach
  if command -v convert &> /dev/null; then
    convert -size 100x100 xc:red /tmp/test-image.png
    IMAGE="/tmp/test-image.png"
  else
    echo "⚠️  ImageMagick not found. Using JSON+base64 method instead..."
    # Minimal 1x1 red PNG in base64
    BASE64_IMG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

    echo ""
    echo "🚀 Uploading via JSON+base64..."
    curl -v -X POST "${API_URL}/upload" \
      -H "Content-Type: application/json" \
      -d "{\"image\":\"${BASE64_IMG}\",\"filename\":\"test.png\",\"contentType\":\"image/png\"}"
    echo ""
    echo "✅ Done!"
    exit 0
  fi
fi

echo ""
echo "🚀 Uploading: $IMAGE"
echo "📡 To: ${API_URL}/upload"
echo ""

curl -v -X POST "${API_URL}/upload" \
  -F "image=@${IMAGE}"

echo ""
echo ""
echo "✅ Upload complete! Check S3 for the processed image."
