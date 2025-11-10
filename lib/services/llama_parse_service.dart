import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class LlamaParseService {
  final String apiKey;
  static const String baseUrl = 'https://api.cloud.llamaindex.ai/api/v1/extraction/run';

  LlamaParseService({required this.apiKey});

  /// Extract data from a document (government ID or invoice)
  Future<Map<String, dynamic>> extractDocument({
    required File? file,
    required Uint8List? fileBytes,
    required String fileName,
    required String documentType,
  }) async {
    try {
      final dataSchema = _getDataSchema(documentType);
      final config = _getExtractionConfig();

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      // Add headers
      request.headers['Authorization'] = 'Bearer $apiKey';

      // Add file
      if (kIsWeb && fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));
      } else if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ));
      } else {
        throw Exception('No file provided');
      }

      // Add data schema and config
      request.fields['data_schema'] = jsonEncode(dataSchema);
      request.fields['config'] = jsonEncode(config);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to extract document: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error extracting document: $e');
    }
  }

  /// Get data schema based on document type
  Map<String, dynamic> _getDataSchema(String documentType) {
    if (documentType == 'government_id') {
      return {
        "type": "object",
        "properties": {
          "full_name": {"type": "string", "description": "Full name on the ID"},
          "id_number": {"type": "string", "description": "ID number"},
          "date_of_birth": {"type": "string", "description": "Date of birth"},
          "gender": {"type": "string", "description": "Gender"},
          "address": {"type": "string", "description": "Address"},
          "issue_date": {"type": "string", "description": "Date of issue"},
          "expiry_date": {"type": "string", "description": "Date of expiry"},
          "nationality": {"type": "string", "description": "Nationality"},
          "document_type": {"type": "string", "description": "Type of ID document"}
        },
        "additionalProperties": false
      };
    } else if (documentType == 'invoice') {
      return {
        "type": "object",
        "properties": {
          "invoice_number": {"type": "string", "description": "Invoice number"},
          "invoice_date": {"type": "string", "description": "Invoice date"},
          "due_date": {"type": "string", "description": "Payment due date"},
          "vendor_name": {"type": "string", "description": "Vendor/seller name"},
          "vendor_address": {"type": "string", "description": "Vendor address"},
          "customer_name": {"type": "string", "description": "Customer/buyer name"},
          "customer_address": {"type": "string", "description": "Customer address"},
          "items": {
            "type": "array",
            "description": "List of items",
            "items": {
              "type": "object",
              "properties": {
                "description": {"type": "string"},
                "quantity": {"type": "number"},
                "unit_price": {"type": "number"},
                "total": {"type": "number"}
              }
            }
          },
          "subtotal": {"type": "number", "description": "Subtotal amount"},
          "tax": {"type": "number", "description": "Tax amount"},
          "total": {"type": "number", "description": "Total amount"},
          "currency": {"type": "string", "description": "Currency code"}
        },
        "additionalProperties": false
      };
    } else {
      return {
        "type": "object",
        "properties": {},
        "additionalProperties": false
      };
    }
  }

  /// Get extraction configuration
  Map<String, dynamic> _getExtractionConfig() {
    return {
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
  }
}
