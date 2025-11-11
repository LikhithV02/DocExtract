# LlamaParse API Integration Update

## Summary
Successfully fixed the LlamaParse API integration by updating from multipart/form-data to JSON format with base64-encoded files and implementing proper result polling.

## Test Results

### Invoice Extraction Test (Invoice.jpeg)
**Status:** ✅ SUCCESS

**Extracted Data:**
```json
{
  "seller_info": {
    "name": "Mathaji Jewellers & Bankers",
    "gstin": "29AINPR1733P1ZD"
  },
  "invoice_details": {
    "date": "18.08.2025",
    "bill_no": "11057"
  },
  "summary": {
    "grand_total": 10000.0
  }
}
```

**Extraction Metadata:**
- Pages extracted: 1
- Document tokens: 358
- Output tokens: 54

## API Endpoints

1. **Submit Extraction Job:**
   - Method: POST
   - URL: `https://api.cloud.llamaindex.ai/api/v1/extraction/run`
   - Format: JSON with base64-encoded file

2. **Get Extraction Result:**
   - Method: GET
   - URL: `https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}/result`
   - Returns: Extracted data

3. **Check Job Status:**
   - Method: GET
   - URL: `https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}`
   - Returns: Job status (PENDING/SUCCESS/ERROR)

## Changes Made

### 1. test_llamaparse.py
**Updated:** Lines 92-175
- Changed from multipart/form-data to JSON format
- Added base64 encoding for file data
- Implemented result polling with 30-attempt retry logic
- Added automatic extraction result retrieval

### 2. lib/services/llama_parse_service.dart
**Updated:** Lines 1-91
- Removed unused `kIsWeb` import
- Changed from `MultipartRequest` to JSON POST request
- Added base64 encoding: `base64Encode(bytes)`
- Implemented result polling loop (30 attempts, 2-second intervals)
- Returns extracted data directly from `result['data']`

### 3. lib/screens/document_type_selection_screen.dart
**Updated:** Lines 56-68
- Simplified data handling: `extractedData` now contains data directly
- Removed redundant null coalescing operator

## Request Format

```dart
{
  "data_schema": {
    "type": "object",
    "properties": { /* schema definition */ }
  },
  "config": {
    "extraction_target": "PER_DOC",
    "extraction_mode": "BALANCED",
    /* other config options */
  },
  "file": {
    "data": "<base64-encoded-file-content>",
    "mime_type": "image/jpeg" // or "application/pdf"
  }
}
```

## Response Format

### Initial Submission Response
```json
{
  "id": "job-id-uuid",
  "status": "PENDING",
  "extraction_agent": { /* agent details */ },
  "file": { /* file details */ }
}
```

### Extraction Result Response
```json
{
  "run_id": "run-id-uuid",
  "extraction_agent_id": "agent-id-uuid",
  "data": {
    /* extracted data matching the schema */
  },
  "extraction_metadata": {
    "usage": {
      "num_pages_extracted": 1,
      "num_document_tokens": 358,
      "num_output_tokens": 54
    }
  }
}
```

## Testing

Run the test script:
```bash
LLAMA_CLOUD_API_KEY=your_api_key python3 test_llamaparse.py Invoice.jpeg
```

Expected output:
- ✅ API endpoint reachable
- ✅ Extraction job submitted
- ✅ Result polling successful
- ✅ Extracted data displayed

## Flutter App Usage

The updated Flutter app now:
1. Converts file to bytes (works on web and mobile)
2. Encodes as base64
3. Sends JSON request to LlamaParse API
4. Polls for results every 2 seconds (max 60 seconds)
5. Returns extracted data to the UI

No changes needed in the UI screens - the data flow remains the same.

## Notes

- **Timeout:** 60 seconds (30 attempts × 2 seconds)
- **File Support:** JPEG, PNG, PDF
- **Platform Support:** Web, iOS, Android
- **Max File Size:** Limited by base64 encoding and API constraints
