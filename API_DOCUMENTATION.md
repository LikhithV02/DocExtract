# DocExtract API Documentation

## Overview

**Version**: 2.0.0
**Base URL**: `http://localhost:8000`
**API Prefix**: `/api/v1`
**Framework**: FastAPI
**Database**: MongoDB
**Documentation**: Available at `/docs` (Swagger UI)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Extraction Endpoints](#extraction-endpoints)
3. [Documents Endpoints](#documents-endpoints)
4. [Statistics Endpoints](#statistics-endpoints)
5. [Utility Endpoints](#utility-endpoints)
6. [WebSocket](#websocket)
7. [Data Schemas](#data-schemas)
8. [Error Handling](#error-handling)

---

## Authentication

**Current Status**: No authentication required
All endpoints are publicly accessible. CORS is configured to allow all origins (`*`).

> **Note**: For production use, implement authentication headers and restrict CORS origins.

---

## Extraction Endpoints

### Extract Document Data

Extract structured data from uploaded documents using LlamaParse.

**Endpoint**: `POST /api/v1/extract`
**Tags**: extraction
**Content-Type**: `application/json`

#### Request Body

```json
{
  "file_data": "base64_encoded_file_content",
  "file_name": "document.pdf",
  "document_type": "invoice"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file_data | string | Yes | Base64 encoded file content |
| file_name | string | Yes | Original filename with extension |
| document_type | string | Yes | Type of document: `government_id` or `invoice` |

#### Response

**Status Code**: `200 OK`

```json
{
  "extracted_data": {
    // Structure varies by document_type
  },
  "file_name": "document.pdf"
}
```

#### Error Responses

- `400 Bad Request`: Invalid document_type or invalid Base64 data
- `500 Internal Server Error`: Extraction failed

#### Example: Invoice Extraction

**Request**:
```json
{
  "file_data": "JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PC...",
  "file_name": "invoice_2024.pdf",
  "document_type": "invoice"
}
```

**Response**:
```json
{
  "extracted_data": {
    "seller_info": {
      "name": "ABC Jewellers",
      "gstin": "29AABCU9603R1ZX",
      "contact_numbers": ["9876543210"]
    },
    "customer_info": {
      "name": "John Doe",
      "address": "123 Main St",
      "gstin": null
    },
    "invoice_details": {
      "date": "2024-01-15",
      "bill_no": "INV-001",
      "gold_price_per_unit": 6500.00
    },
    "line_items": [
      {
        "description": "Gold Ring",
        "weight": 10.5,
        "rate": 6500.00,
        "wastage_allowance_percentage": 8.0,
        "making_charges_percentage": 12.0,
        "amount": 78456.00,
        "hsn_code": "7113"
      }
    ],
    "summary": {
      "sub_total": 78456.00,
      "discount": 0,
      "taxable_amount": 78456.00,
      "sgst_percentage": 1.5,
      "sgst_amount": 1176.84,
      "cgst_percentage": 1.5,
      "cgst_amount": 1176.84,
      "grand_total": 80809.68
    },
    "payment_details": {
      "cash": 80809.68,
      "upi": 0,
      "card": 0
    },
    "total_amount_in_words": "Eighty Thousand Eight Hundred Nine Rupees and Sixty Eight Paise Only"
  },
  "file_name": "invoice_2024.pdf"
}
```

---

## Documents Endpoints

### Create Document

Save extracted document data to the database.

**Endpoint**: `POST /api/v1/documents`
**Tags**: documents
**Content-Type**: `application/json`

#### Request Body

```json
{
  "document_type": "invoice",
  "file_name": "invoice_2024.pdf",
  "extracted_data": {
    // Document data structure
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| document_type | string | Yes | `government_id` or `invoice` |
| file_name | string | Yes | Original filename |
| extracted_data | object | Yes | Extracted document data |

#### Response

**Status Code**: `201 Created`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "document_type": "invoice",
  "file_name": "invoice_2024.pdf",
  "extracted_data": { },
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Note**: Broadcasts `INSERT` event to WebSocket clients.

---

### List Documents

Retrieve documents with optional filtering and pagination.

**Endpoint**: `GET /api/v1/documents`
**Tags**: documents

#### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| document_type | string | - | Filter by type: `government_id` or `invoice` |
| limit | integer | 100 | Maximum number of documents to return |
| offset | integer | 0 | Number of documents to skip |

#### Response

**Status Code**: `200 OK`

```json
{
  "documents": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "document_type": "invoice",
      "file_name": "invoice_2024.pdf",
      "extracted_data": { },
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 42
}
```

#### Example Requests

```bash
# Get all documents
GET /api/v1/documents

# Get invoices only
GET /api/v1/documents?document_type=invoice

# Get with pagination
GET /api/v1/documents?limit=10&offset=20

# Get government IDs, paginated
GET /api/v1/documents?document_type=government_id&limit=50&offset=0
```

---

### Get Document by ID

Retrieve a specific document by its unique identifier.

**Endpoint**: `GET /api/v1/documents/{document_id}`
**Tags**: documents

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| document_id | string | Yes | Unique document UUID |

#### Response

**Status Code**: `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "document_type": "invoice",
  "file_name": "invoice_2024.pdf",
  "extracted_data": { },
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### Error Responses

- `404 Not Found`: Document does not exist

---

### Update Document

Update an existing document's data.

**Endpoint**: `PUT /api/v1/documents/{document_id}`
**Tags**: documents
**Content-Type**: `application/json`

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| document_id | string | Yes | Unique document UUID |

#### Request Body

```json
{
  "document_type": "invoice",
  "file_name": "invoice_2024_updated.pdf",
  "extracted_data": {
    // Updated document data
  }
}
```

#### Response

**Status Code**: `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "document_type": "invoice",
  "file_name": "invoice_2024_updated.pdf",
  "extracted_data": { },
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Note**:
- Broadcasts `UPDATE` event to WebSocket clients
- Preserves original `created_at` timestamp

#### Error Responses

- `404 Not Found`: Document does not exist

---

### Delete Document

Delete a document from the database.

**Endpoint**: `DELETE /api/v1/documents/{document_id}`
**Tags**: documents

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| document_id | string | Yes | Unique document UUID |

#### Response

**Status Code**: `200 OK`

```json
{
  "success": true,
  "message": "Document deleted successfully"
}
```

**Note**: Broadcasts `DELETE` event to WebSocket clients.

#### Error Responses

- `404 Not Found`: Document does not exist

---

## Statistics Endpoints

### Get Document Statistics

Retrieve aggregated statistics about stored documents.

**Endpoint**: `GET /api/v1/stats`
**Tags**: statistics

#### Response

**Status Code**: `200 OK`

```json
{
  "total": 150,
  "government_id": 45,
  "invoice": 105
}
```

| Field | Type | Description |
|-------|------|-------------|
| total | integer | Total number of documents |
| government_id | integer | Number of government ID documents |
| invoice | integer | Number of invoice documents |

---

## Utility Endpoints

### Root Endpoint

API metadata and information.

**Endpoint**: `GET /`

#### Response

**Status Code**: `200 OK`

```json
{
  "name": "DocExtract API",
  "version": "2.0.0",
  "status": "running",
  "docs": "/docs"
}
```

---

### Health Check

Check API and database health status.

**Endpoint**: `GET /health`

#### Response

**Status Code**: `200 OK`

```json
{
  "status": "healthy",
  "database": "connected"
}
```

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| status | string | `healthy` | API status |
| database | string | `connected`, `disconnected` | MongoDB connection status |

---

### CORS Preflight

Handle CORS preflight requests.

**Endpoint**: `OPTIONS /{path}`

#### Response

**Status Code**: `200 OK`

```json
{
  "status": "ok"
}
```

---

## WebSocket

### Real-time Document Updates

Subscribe to real-time document change notifications.

**Endpoint**: `ws://localhost:8000/ws/documents`
**Protocol**: WebSocket

#### Connection

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/documents');

ws.onopen = () => {
  console.log('Connected to document updates');
};

ws.onmessage = (event) => {
  const update = JSON.parse(event.data);
  console.log('Document update:', update);
};
```

#### Message Format

```json
{
  "event_type": "INSERT",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "document_type": "invoice",
    "file_name": "invoice.pdf",
    "extracted_data": { },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Event Types

| Event Type | Description | Data |
|------------|-------------|------|
| INSERT | New document created | Complete document object |
| UPDATE | Document updated | Updated document object |
| DELETE | Document deleted | Document ID string |

#### Example Messages

**INSERT Event**:
```json
{
  "event_type": "INSERT",
  "data": {
    "id": "abc-123",
    "document_type": "invoice",
    "file_name": "new_invoice.pdf",
    "extracted_data": { },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**UPDATE Event**:
```json
{
  "event_type": "UPDATE",
  "data": {
    "id": "abc-123",
    "document_type": "invoice",
    "file_name": "updated_invoice.pdf",
    "extracted_data": { },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**DELETE Event**:
```json
{
  "event_type": "DELETE",
  "data": "abc-123"
}
```

---

## Data Schemas

### Government ID Schema

Structure for government-issued identification documents.

```json
{
  "full_name": "John Doe",
  "id_number": "1234-5678-9012",
  "date_of_birth": "1990-01-15",
  "gender": "Male",
  "address": "123 Main Street, City, State, 12345",
  "issue_date": "2020-01-01",
  "expiry_date": "2030-01-01",
  "nationality": "Indian",
  "document_type": "Aadhaar"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| full_name | string | Yes | Full name as on document |
| id_number | string | Yes | Unique identification number |
| date_of_birth | string | Yes | DOB in YYYY-MM-DD format |
| gender | string | Yes | Male/Female/Other |
| address | string | Yes | Full address |
| issue_date | string | Yes | Issue date in YYYY-MM-DD format |
| expiry_date | string | No | Expiry date in YYYY-MM-DD format |
| nationality | string | Yes | Nationality |
| document_type | string | Yes | Type (Aadhaar, Passport, Driver's License, etc.) |

---

### Invoice Schema

Structure for invoice/bill documents.

```json
{
  "seller_info": {
    "name": "ABC Jewellers",
    "gstin": "29AABCU9603R1ZX",
    "contact_numbers": ["9876543210", "9876543211"]
  },
  "customer_info": {
    "name": "John Doe",
    "address": "123 Main St",
    "contact": "9876543210",
    "gstin": "29AABCU9603R1ZY"
  },
  "invoice_details": {
    "date": "2024-01-15",
    "bill_no": "INV-001",
    "gold_price_per_unit": 6500.00
  },
  "line_items": [
    {
      "description": "Gold Ring",
      "weight": 10.5,
      "rate": 6500.00,
      "wastage_allowance_percentage": 8.0,
      "making_charges_percentage": 12.0,
      "amount": 78456.00,
      "hsn_code": "7113"
    }
  ],
  "summary": {
    "sub_total": 78456.00,
    "discount": 0,
    "taxable_amount": 78456.00,
    "sgst_percentage": 1.5,
    "sgst_amount": 1176.84,
    "cgst_percentage": 1.5,
    "cgst_amount": 1176.84,
    "grand_total": 80809.68
  },
  "payment_details": {
    "cash": 80809.68,
    "upi": 0,
    "card": 0
  },
  "total_amount_in_words": "Eighty Thousand Eight Hundred Nine Rupees Only"
}
```

#### Seller Info

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Business name |
| gstin | string | Yes | GST Identification Number |
| contact_numbers | array[string] | Yes | Phone numbers |

#### Customer Info

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Customer name |
| address | string | No | Customer address |
| contact | string | No | Contact number |
| gstin | string | No | Customer GSTIN |

#### Invoice Details

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| date | string | Yes | Invoice date (YYYY-MM-DD) |
| bill_no | string | Yes | Invoice/Bill number |
| gold_price_per_unit | number | No | Gold price per unit |

#### Line Items

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| description | string | Yes | Item description |
| weight | number | Yes | Weight in grams |
| rate | number | Yes | Rate per unit |
| amount | number | Yes | Line item total |
| hsn_code | string | No | HSN classification code |
| wastage_allowance_percentage | number | No | Wastage percentage |
| making_charges_percentage | number | No | Making charges percentage |

#### Summary

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| sub_total | number | Yes | Subtotal amount |
| discount | number | No | Discount amount |
| taxable_amount | number | Yes | Taxable amount |
| sgst_percentage | number | No | SGST percentage |
| sgst_amount | number | No | SGST amount |
| cgst_percentage | number | No | CGST percentage |
| cgst_amount | number | No | CGST amount |
| grand_total | number | Yes | Grand total |

#### Payment Details

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| cash | number | Yes | Cash payment |
| upi | number | Yes | UPI payment |
| card | number | Yes | Card payment |

---

## Error Handling

### Standard Error Response

```json
{
  "detail": "Error message description"
}
```

### HTTP Status Codes

| Code | Status | Description |
|------|--------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request data |
| 404 | Not Found | Resource not found |
| 500 | Internal Server Error | Server error |

### Common Error Scenarios

#### Invalid Document Type
**Status**: `400 Bad Request`
```json
{
  "detail": "Invalid document type. Must be 'government_id' or 'invoice'"
}
```

#### Invalid Base64 Data
**Status**: `400 Bad Request`
```json
{
  "detail": "Invalid Base64 encoded data"
}
```

#### Document Not Found
**Status**: `404 Not Found`
```json
{
  "detail": "Document not found"
}
```

#### Extraction Failed
**Status**: `500 Internal Server Error`
```json
{
  "detail": "Document extraction failed"
}
```

---

## Rate Limiting

**Current Status**: No rate limiting implemented

> **Recommendation**: Implement rate limiting for production use to prevent abuse.

---

## CORS Configuration

**Allowed Origins**: `*` (all origins)
**Allowed Methods**: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`
**Allowed Headers**: `*`
**Allow Credentials**: `true`

> **Production Note**: Restrict CORS origins to specific domains for security.

---

## Development & Testing

### Interactive API Documentation

FastAPI provides automatic interactive API documentation:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### cURL Examples

#### Extract Document
```bash
curl -X POST "http://localhost:8000/api/v1/extract" \
  -H "Content-Type: application/json" \
  -d '{
    "file_data": "BASE64_ENCODED_DATA",
    "file_name": "invoice.pdf",
    "document_type": "invoice"
  }'
```

#### List Documents
```bash
curl "http://localhost:8000/api/v1/documents?limit=10&offset=0"
```

#### Get Document
```bash
curl "http://localhost:8000/api/v1/documents/550e8400-e29b-41d4-a716-446655440000"
```

#### Health Check
```bash
curl "http://localhost:8000/health"
```

---

## Support & Contact

For issues or questions:
- GitHub: [LikhithV02/DocExtract](https://github.com/LikhithV02/DocExtract)
- API Version: 2.0.0
- Last Updated: 2024

---

**Generated with Claude Code**
