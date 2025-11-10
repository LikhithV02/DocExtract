import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class LlamaParseService {
  final String apiKey;
  static const String baseUrl = 'https://api.cloud.llamaindex.ai/api/v1/extract';

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
        "additionalProperties": false,
        "properties": {
          "seller_info": {
            "description": "Information about the seller or issuer of the invoice.",
            "type": "object",
            "properties": {
              "name": {
                "description": "The name of the selling entity.",
                "type": "string"
              },
              "gstin": {
                "description": "Goods and Services Tax Identification Number of the seller.",
                "type": "string"
              },
              "contact_numbers": {
                "description": "An array of contact phone numbers for the seller.",
                "type": "array",
                "items": {"type": "string"}
              }
            },
            "required": ["name", "gstin", "contact_numbers"]
          },
          "customer_info": {
            "description": "Information about the customer or the entity being billed.",
            "type": "object",
            "properties": {
              "name": {
                "description": "The name of the customer.",
                "type": "string"
              },
              "address": {
                "description": "The billing address of the customer.",
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"}
                ]
              },
              "contact": {
                "description": "The contact number of the customer.",
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"}
                ]
              },
              "gstin": {
                "description": "Goods and Services Tax Identification Number of the customer.",
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"}
                ]
              }
            },
            "required": ["name", "address", "contact", "gstin"]
          },
          "invoice_details": {
            "description": "General details pertaining to the invoice.",
            "type": "object",
            "properties": {
              "date": {
                "description": "The date when the invoice was issued. Format: YYYY-MM-DD.",
                "type": "string"
              },
              "bill_no": {
                "description": "The unique invoice or bill number.",
                "type": "string"
              },
              "gold_price_per_unit": {
                "description": "The base price of gold per unit (e.g., per gram or 10 grams) at the time of invoice.",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              }
            },
            "required": ["date", "bill_no", "gold_price_per_unit"]
          },
          "line_items": {
            "description": "A list of individual items or products included in the invoice.",
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "description": {
                  "description": "A brief description of the item.",
                  "type": "string"
                },
                "hsn_code": {
                  "description": "Harmonized System of Nomenclature (HSN) code for the item.",
                  "anyOf": [
                    {"type": "string"},
                    {"type": "null"}
                  ]
                },
                "weight": {
                  "description": "The weight of the item, typically in grams or similar units.",
                  "type": "number"
                },
                "wastage_allowance_percentage": {
                  "description": "The percentage of wastage or allowance applied to the item.",
                  "anyOf": [
                    {"type": "number"},
                    {"type": "null"}
                  ]
                },
                "rate": {
                  "description": "The unit rate of the item before any additional charges or taxes.",
                  "type": "number"
                },
                "making_charges_percentage": {
                  "description": "The percentage of making charges applied to the item.",
                  "anyOf": [
                    {"type": "number"},
                    {"type": "null"}
                  ]
                },
                "amount": {
                  "description": "The total amount for this specific line item, including all charges but before overall discounts/taxes.",
                  "type": "number"
                }
              },
              "required": ["description", "hsn_code", "weight", "wastage_allowance_percentage", "rate", "making_charges_percentage", "amount"]
            }
          },
          "summary": {
            "description": "Summary of all financial calculations for the invoice.",
            "type": "object",
            "properties": {
              "sub_total": {
                "description": "The sum of all line item amounts before discounts and taxes.",
                "type": "number"
              },
              "discount": {
                "description": "The total discount applied to the invoice.",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              },
              "taxable_amount": {
                "description": "The amount on which taxes are calculated after discounts.",
                "type": "number"
              },
              "sgst_percentage": {
                "description": "State Goods and Services Tax (SGST) percentage.",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              },
              "sgst_amount": {
                "description": "The calculated amount of State Goods and Services Tax (SGST).",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              },
              "cgst_percentage": {
                "description": "Central Goods and Services Tax (CGST) percentage.",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              },
              "cgst_amount": {
                "description": "The calculated amount of Central Goods and Services Tax (CGST).",
                "anyOf": [
                  {"type": "number"},
                  {"type": "null"}
                ]
              },
              "grand_total": {
                "description": "The final total amount payable for the invoice, including all taxes and after all discounts.",
                "type": "number"
              }
            },
            "required": ["sub_total", "discount", "taxable_amount", "sgst_percentage", "sgst_amount", "cgst_percentage", "cgst_amount", "grand_total"]
          },
          "payment_details": {
            "description": "Details regarding the payment methods used for the invoice.",
            "type": "object",
            "properties": {
              "cash": {
                "description": "Amount paid via cash.",
                "type": "number"
              },
              "upi": {
                "description": "Amount paid via UPI (Unified Payments Interface).",
                "type": "number"
              },
              "card": {
                "description": "Amount paid via card (credit/debit).",
                "type": "number"
              }
            },
            "required": ["cash", "upi", "card"]
          },
          "total_amount_in_words": {
            "description": "The grand total amount written out in words.",
            "anyOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          }
        },
        "required": ["seller_info", "customer_info", "invoice_details", "line_items", "summary", "payment_details", "total_amount_in_words"]
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
