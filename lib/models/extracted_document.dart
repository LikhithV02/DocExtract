import 'dart:convert';

class ExtractedDocument {
  final String id;
  final String documentType;
  final String fileName;
  final Map<String, dynamic> extractedData;
  final DateTime createdAt;

  ExtractedDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.extractedData,
    required this.createdAt,
  });

  factory ExtractedDocument.fromJson(Map<String, dynamic> json) {
    return ExtractedDocument(
      id: json['id'] as String,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      extractedData: json['extracted_data'] is String
          ? jsonDecode(json['extracted_data'])
          : json['extracted_data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'file_name': fileName,
      'extracted_data': extractedData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getDisplayValue(String key) {
    final value = extractedData[key];
    if (value == null) return 'N/A';
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}
