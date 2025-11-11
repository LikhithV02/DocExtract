#!/bin/bash

# Test script for LlamaParse API
# Usage: ./test_api.sh YOUR_API_KEY /path/to/test/file.pdf

API_KEY="${1:-${LLAMA_CLOUD_API_KEY}}"
TEST_FILE="${2}"
API_URL="https://api.cloud.llamaindex.ai/api/v1/extraction/run"

echo "🧪 Testing LlamaParse API"
echo "=========================="
echo "API URL: $API_URL"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Usage: ./test_api.sh YOUR_API_KEY [test_file.pdf]"
    echo "   or: LLAMA_CLOUD_API_KEY=your_key ./test_api.sh [test_file.pdf]"
    exit 1
fi

echo "API Key: ${API_KEY:0:10}..."

# Simple invoice schema
DATA_SCHEMA='{
  "type": "object",
  "properties": {
    "seller_info": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "gstin": {"type": "string"}
      }
    },
    "summary": {
      "type": "object",
      "properties": {
        "grand_total": {"type": "number"}
      }
    }
  },
  "additionalProperties": false
}'

CONFIG='{
  "extraction_target": "PER_DOC",
  "extraction_mode": "BALANCED",
  "chunk_mode": "PAGE"
}'

if [ -z "$TEST_FILE" ]; then
    echo ""
    echo "⚠️  No test file provided - testing API endpoint availability only"
    echo ""

    # Test endpoint with OPTIONS or GET request
    echo "📡 Checking API endpoint..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $API_KEY" \
        "$API_URL")

    echo "HTTP Response Code: $HTTP_CODE"

    if [ "$HTTP_CODE" = "405" ] || [ "$HTTP_CODE" = "400" ]; then
        echo "✅ API endpoint is reachable (expects POST with file)"
    elif [ "$HTTP_CODE" = "401" ]; then
        echo "❌ Authentication failed - check your API key"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "❌ Endpoint not found - URL may be incorrect"
    else
        echo "ℹ️  Received response code: $HTTP_CODE"
    fi
else
    if [ ! -f "$TEST_FILE" ]; then
        echo "❌ Error: File not found: $TEST_FILE"
        exit 1
    fi

    echo "Test File: $TEST_FILE"
    echo ""
    echo "📤 Sending request to API..."
    echo ""

    # Make actual API call with file
    RESPONSE=$(curl -X POST "$API_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -F "file=@$TEST_FILE" \
        -F "data_schema=$DATA_SCHEMA" \
        -F "config=$CONFIG" \
        -w "\n%{http_code}" \
        2>/dev/null)

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    echo "HTTP Response Code: $HTTP_CODE"
    echo ""

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ SUCCESS! Extraction completed"
        echo ""
        echo "Response:"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    else
        echo "❌ Request failed"
        echo ""
        echo "Response:"
        echo "$BODY"
    fi
fi

echo ""
echo "=========================="
