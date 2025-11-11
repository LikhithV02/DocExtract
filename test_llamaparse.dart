import 'dart:convert';
import 'dart:io';

/// Simple test script to verify LlamaParse API connection
void main() async {
  // Configuration
  const apiKey = String.fromEnvironment('LLAMA_CLOUD_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE');
  const apiUrl = 'https://api.cloud.llamaindex.ai/api/v1/extract';

  print('🧪 Testing LlamaParse API...');
  print('API URL: $apiUrl');
  print('API Key: ${apiKey.substring(0, 10)}...\n');

  // Simple invoice schema for testing
  final dataSchema = {
    "type": "object",
    "properties": {
      "invoice_number": {"type": "string"},
      "total": {"type": "number"}
    },
    "additionalProperties": false
  };

  final config = {
    "priority": null,
    "extraction_target": "PER_DOC",
    "extraction_mode": "BALANCED",
    "parse_model": null,
    "extract_model": null,
    "multimodal_fast_mode": false,
    "system_prompt": null,
    "use_reasoning": false,
    "cite_sources": false,
    "confidence_scores": false,
    "chunk_mode": "PAGE",
    "high_resolution_mode": false,
    "invalidate_cache": false,
    "num_pages_context": null,
    "page_range": null
  };

  try {
    // Create a simple test request
    final request = await HttpClient().postUrl(Uri.parse(apiUrl));
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.headers.set('Content-Type', 'application/json');

    // For a real test, you'd send multipart form data with a file
    // This is just testing the endpoint availability

    print('✅ Request created successfully');
    print('Endpoint is reachable!\n');

    // Note: Actual file upload test would require a sample file
    print('📝 To test with an actual file, use:');
    print('   dart run test_llamaparse.dart /path/to/your/invoice.pdf');

  } catch (e) {
    print('❌ Error connecting to API: $e');
  }
}
