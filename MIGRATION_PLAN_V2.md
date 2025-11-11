# DocExtract v2.0 Migration Plan: FastAPI + MongoDB + Play Store Release

**Created:** 2025-11-11
**Status:** Approved and Ready for Implementation

---

## Executive Summary

This document outlines the complete migration plan for DocExtract from Supabase backend to a centralized FastAPI + MongoDB architecture, with deployment to VPS and Play Store release preparation.

### Key Decisions
- ✅ **No file storage** - Store only extracted data
- ✅ **Real-time WebSocket** - For instant sync across devices
- ✅ **VPS Deployment** - DigitalOcean/Linode
- ✅ **Start fresh** - No Supabase data migration
- ✅ **LlamaParse in backend** - Centralized extraction logic

---

## Current Architecture Analysis

### Existing Document Types

#### 1. Government ID (9 fields)
```json
{
  "full_name": "string",
  "id_number": "string",
  "date_of_birth": "string",
  "gender": "string",
  "address": "string",
  "issue_date": "string",
  "expiry_date": "string",
  "nationality": "string",
  "document_type": "string"
}
```

#### 2. Invoice (Indian GST Format - 7 sections)
```json
{
  "seller_info": {
    "name": "string",
    "gstin": "string",
    "contact_numbers": ["string"]
  },
  "customer_info": {
    "name": "string",
    "address": "string | null",
    "contact": "string | null",
    "gstin": "string | null"
  },
  "invoice_details": {
    "date": "YYYY-MM-DD",
    "bill_no": "string",
    "gold_price_per_unit": "number | null"
  },
  "line_items": [{
    "description": "string",
    "hsn_code": "string | null",
    "weight": "number",
    "wastage_allowance_percentage": "number | null",
    "rate": "number",
    "making_charges_percentage": "number | null",
    "amount": "number"
  }],
  "summary": {
    "sub_total": "number",
    "discount": "number | null",
    "taxable_amount": "number",
    "sgst_percentage": "number | null",
    "sgst_amount": "number | null",
    "cgst_percentage": "number | null",
    "cgst_amount": "number | null",
    "grand_total": "number"
  },
  "payment_details": {
    "cash": "number",
    "upi": "number",
    "card": "number"
  },
  "total_amount_in_words": "string | null"
}
```

---

## Phase 1: Backend Setup (FastAPI + MongoDB)

### Branch: `feature/backend-fastapi`

### Key Technology Decision: Using Official LlamaCloud SDK

**IMPORTANT:** This implementation will use the official `llama-cloud` Python SDK instead of manual HTTP requests.

**Why use the SDK?**
- ✅ **Type Safety:** Built-in type hints and Pydantic models
- ✅ **Authentication:** Automatic API key management
- ✅ **Reliability:** Built-in retries and error handling
- ✅ **Maintenance:** Automatically compatible with API updates
- ✅ **Developer Experience:** Better IDE support and documentation

**Package:** `llama-cloud==0.0.11` (not `llama_cloud_services`)

### 1.1 Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app + WebSocket setup
│   ├── config.py                  # Environment configuration
│   │
│   ├── models/                    # Pydantic models
│   │   ├── __init__.py
│   │   ├── document.py            # Base document model
│   │   ├── government_id.py       # Government ID data model
│   │   └── invoice.py             # Invoice data model with nested types
│   │
│   ├── schemas/                   # LlamaParse extraction schemas
│   │   ├── __init__.py
│   │   ├── government_id_schema.py
│   │   └── invoice_schema.py
│   │
│   ├── routes/                    # API endpoints
│   │   ├── __init__.py
│   │   ├── documents.py           # CRUD operations
│   │   ├── extraction.py          # LlamaParse extraction endpoint
│   │   └── stats.py               # Statistics endpoint
│   │
│   ├── services/                  # Business logic
│   │   ├── __init__.py
│   │   ├── database.py            # MongoDB connection & operations
│   │   ├── llamaparse.py          # LlamaParse API integration
│   │   └── websocket_manager.py   # WebSocket connection manager
│   │
│   └── utils/                     # Helper functions
│       ├── __init__.py
│       └── validators.py          # Custom validators
│
├── tests/                         # Test files
│   ├── __init__.py
│   ├── test_extraction.py
│   ├── test_api.py
│   └── test_websocket.py
│
├── .env.example                   # Environment variables template
├── .gitignore
├── requirements.txt               # Python dependencies
├── Dockerfile                     # Docker container
├── docker-compose.yml            # Docker Compose for local dev
└── README.md                      # Backend documentation
```

### 1.2 MongoDB Schema Design (Pydantic Models)

#### Complete Pydantic Model Structure

```python
# app/models/government_id.py
from pydantic import BaseModel, Field
from typing import Optional

class GovernmentIdData(BaseModel):
    """Government ID document data model"""
    full_name: str = Field(..., description="Full name on the document")
    id_number: str = Field(..., description="ID number")
    date_of_birth: str = Field(..., description="Date of birth")
    gender: str = Field(..., description="Gender")
    address: str = Field(..., description="Address")
    issue_date: str = Field(..., description="Issue date")
    expiry_date: Optional[str] = Field(None, description="Expiry date if applicable")
    nationality: str = Field(..., description="Nationality")
    document_type: str = Field(..., description="Type of government ID")


# app/models/invoice.py
from pydantic import BaseModel, Field
from typing import List, Optional

class SellerInfo(BaseModel):
    name: str
    gstin: str
    contact_numbers: List[str] = []

class CustomerInfo(BaseModel):
    name: str
    address: Optional[str] = None
    contact: Optional[str] = None
    gstin: Optional[str] = None

class InvoiceDetails(BaseModel):
    date: str  # YYYY-MM-DD format
    bill_no: str
    gold_price_per_unit: Optional[float] = None

class LineItem(BaseModel):
    description: str
    hsn_code: Optional[str] = None
    weight: float
    wastage_allowance_percentage: Optional[float] = None
    rate: float
    making_charges_percentage: Optional[float] = None
    amount: float

class InvoiceSummary(BaseModel):
    sub_total: float
    discount: Optional[float] = None
    taxable_amount: float
    sgst_percentage: Optional[float] = None
    sgst_amount: Optional[float] = None
    cgst_percentage: Optional[float] = None
    cgst_amount: Optional[float] = None
    grand_total: float

class PaymentDetails(BaseModel):
    cash: float = 0.0
    upi: float = 0.0
    card: float = 0.0

class InvoiceData(BaseModel):
    """Invoice document data model"""
    seller_info: SellerInfo
    customer_info: CustomerInfo
    invoice_details: InvoiceDetails
    line_items: List[LineItem]
    summary: InvoiceSummary
    payment_details: PaymentDetails
    total_amount_in_words: Optional[str] = None


# app/models/document.py
from pydantic import BaseModel, Field
from typing import Union, Literal
from datetime import datetime
from uuid import uuid4

class ExtractedDocument(BaseModel):
    """Main document model stored in MongoDB"""
    id: str = Field(default_factory=lambda: str(uuid4()))
    document_type: Literal["government_id", "invoice"]
    file_name: str
    extracted_data: Union[GovernmentIdData, InvoiceData]
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

#### MongoDB Collection Design

**Collection:** `extracted_documents`

**Indexes:**
```javascript
db.extracted_documents.createIndex({ "document_type": 1 })
db.extracted_documents.createIndex({ "created_at": -1 })
db.extracted_documents.createIndex({ "id": 1 }, { unique: true })
```

### 1.3 Core API Endpoints

#### REST API Routes

```python
# POST /api/v1/extract
# Request: { "file_data": "base64_string", "file_name": "string", "document_type": "government_id|invoice" }
# Response: { "extracted_data": {...}, "file_name": "string" }

# POST /api/v1/documents
# Request: { "document_type": "string", "file_name": "string", "extracted_data": {...} }
# Response: { "id": "uuid", "created_at": "iso_datetime", ...document }

# GET /api/v1/documents
# Query params: ?document_type=invoice&limit=20&offset=0
# Response: { "documents": [...], "total": 100 }

# GET /api/v1/documents/{id}
# Response: { "id": "uuid", ...document }

# DELETE /api/v1/documents/{id}
# Response: { "success": true, "message": "Document deleted" }

# GET /api/v1/stats
# Response: { "total": 150, "government_id": 50, "invoice": 100 }

# WebSocket /ws/documents
# Events: { "type": "INSERT|UPDATE|DELETE", "data": {...} }
```

### 1.4 LlamaParse Integration

**Using Official Library:** `llama-cloud` (Python SDK)

Instead of manual HTTP requests, we'll use the official `llama-cloud` library which provides:
- Built-in authentication
- Automatic retries and error handling
- Type-safe API calls
- Better API version compatibility

**Configuration:**
```python
LLAMAPARSE_CONFIG = {
    "extraction_target": "PER_DOC",
    "extraction_mode": "BALANCED",
    "chunk_mode": "PAGE",
    "multimodal_fast_mode": False,
    "use_reasoning": False,
    "cite_sources": False,
    "confidence_scores": False,
    "high_resolution_mode": False
}
```

**Implementation Example (app/services/llamaparse.py):**
```python
from llama_cloud import LlamaCloud
from llama_cloud.types import CloudDocumentCreate
import base64
import asyncio
from typing import Dict, Any

class LlamaParseService:
    def __init__(self, api_key: str):
        self.client = LlamaCloud(api_key=api_key)

    async def extract_document(
        self,
        file_bytes: bytes,
        file_name: str,
        document_type: str,
        data_schema: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Extract data from document using LlamaParse

        Args:
            file_bytes: Raw file bytes
            file_name: Name of the file
            document_type: 'government_id' or 'invoice'
            data_schema: Pydantic schema for extraction

        Returns:
            Extracted data matching the schema
        """
        try:
            # Encode file as base64
            base64_data = base64.b64encode(file_bytes).decode('utf-8')

            # Determine MIME type
            mime_type = self._get_mime_type(file_name)

            # Create extraction job using official SDK
            job = self.client.extraction.create(
                file_data=base64_data,
                mime_type=mime_type,
                data_schema=data_schema,
                config=LLAMAPARSE_CONFIG
            )

            # Poll for results (SDK handles this internally)
            result = self.client.extraction.wait_for_completion(
                job_id=job.id,
                timeout=60,  # 60 seconds timeout
                poll_interval=2  # Check every 2 seconds
            )

            return result.data

        except Exception as e:
            raise Exception(f"LlamaParse extraction failed: {str(e)}")

    def _get_mime_type(self, file_name: str) -> str:
        """Determine MIME type from file extension"""
        ext = file_name.lower().split('.')[-1]
        mime_types = {
            'pdf': 'application/pdf',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png'
        }
        return mime_types.get(ext, 'application/octet-stream')
```

**Implementation Flow:**
1. Receive file bytes from Flutter client
2. Initialize LlamaCloud client with API key
3. Encode file as base64
4. Create extraction job with schema and config
5. SDK automatically polls for completion
6. Return extracted data to client

**Benefits of Using SDK:**
- ✅ Automatic authentication header management
- ✅ Built-in retry logic for transient failures
- ✅ Type hints and IDE autocomplete
- ✅ Handles API version changes automatically
- ✅ Better error messages and debugging

### 1.5 WebSocket Manager

**Features:**
- Connection pool management
- Broadcast to all connected clients
- Event types: INSERT, UPDATE, DELETE
- Automatic reconnection handling
- Client subscription management

**Message Format:**
```json
{
  "type": "INSERT|UPDATE|DELETE",
  "timestamp": "2025-11-11T10:30:00Z",
  "data": {
    "id": "document-uuid",
    "document_type": "invoice",
    "extracted_data": {...}
  }
}
```

### 1.6 Dependencies (requirements.txt)

```txt
# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0

# Database
motor==3.3.2                # Async MongoDB driver

# Data Validation
pydantic==2.5.0
pydantic-settings==2.1.0

# Configuration
python-dotenv==1.0.0

# LlamaParse Integration (Official SDK)
llama-cloud==0.0.11         # Official LlamaCloud Python SDK
# Note: Use 'llama-cloud' not 'llama_cloud_services'

# WebSocket & Communication
websockets==12.0
python-multipart==0.0.6

# Optional: For better async support
aiofiles==23.2.1
```

**Installation:**
```bash
pip install llama-cloud
# or
pip install -r requirements.txt
```

---

## Phase 2: Flutter App Refactoring

### Branch: `feature/flutter-api-integration`

### 2.1 Remove Supabase Dependencies

**Changes:**
- Remove `supabase_flutter` from `pubspec.yaml`
- Delete `lib/services/supabase_service.dart`
- Create `lib/services/api_service.dart` for FastAPI backend
- Create `lib/services/websocket_service.dart` for real-time sync

### 2.2 New Home Page Design

**Features:**
- **Header:** App logo + title
- **Stats Cards:**
  - Total documents
  - Government IDs count
  - Invoices count
- **Quick Actions:**
  - Camera capture
  - Gallery upload
  - File picker
- **Recent Documents:**
  - Last 5 documents with preview
  - Tap to view details
- **Bottom Navigation:**
  - Home
  - Upload
  - History

**Responsive Design:**
- Mobile: Single column, bottom navigation
- Web: Two columns, side navigation

### 2.3 Updated Services

#### ApiService (lib/services/api_service.dart)
```dart
class ApiService {
  final String baseUrl;
  final Dio _dio;

  // POST /api/v1/extract
  Future<Map<String, dynamic>> extractDocument(
    Uint8List fileBytes,
    String fileName,
    String documentType,
  );

  // POST /api/v1/documents
  Future<ExtractedDocument> saveDocument(ExtractedDocument doc);

  // GET /api/v1/documents
  Future<List<ExtractedDocument>> getDocuments({String? documentType});

  // GET /api/v1/documents/{id}
  Future<ExtractedDocument> getDocumentById(String id);

  // DELETE /api/v1/documents/{id}
  Future<void> deleteDocument(String id);

  // GET /api/v1/stats
  Future<Map<String, int>> getStats();
}
```

#### WebSocketService (lib/services/websocket_service.dart)
```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<DocumentEvent> _eventController;

  void connect(String url);
  void disconnect();
  Stream<DocumentEvent> get events;
  void reconnect();
}

enum DocumentEventType { INSERT, UPDATE, DELETE }

class DocumentEvent {
  final DocumentEventType type;
  final ExtractedDocument document;
  final DateTime timestamp;
}
```

### 2.4 Updated Provider

```dart
class DocumentProvider extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _wsService;

  List<ExtractedDocument> _documents = [];
  bool _isLoading = false;

  DocumentProvider(this._apiService, this._wsService) {
    _initWebSocket();
  }

  void _initWebSocket() {
    _wsService.connect('ws://your-backend-url/ws/documents');
    _wsService.events.listen((event) {
      // Handle INSERT, UPDATE, DELETE events
      // Update local _documents list
      // Call notifyListeners()
    });
  }

  // Existing methods with API calls instead of Supabase
}
```

### 2.5 New Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  web_socket_channel: ^2.4.0
  dio: ^5.4.0  # Already exists
  # Remove: supabase_flutter
```

---

## Phase 3: VPS Deployment Setup

### Branch: `feature/deployment-config`

### 3.1 Backend Deployment Files

#### Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: docextract_mongo
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongo_data:/data/db
    ports:
      - "27017:27017"

  backend:
    build: .
    container_name: docextract_backend
    restart: always
    environment:
      - MONGODB_URL=mongodb://${MONGO_USER}:${MONGO_PASSWORD}@mongodb:27017
      - LLAMA_CLOUD_API_KEY=${LLAMA_CLOUD_API_KEY}
    ports:
      - "8000:8000"
    depends_on:
      - mongodb

volumes:
  mongo_data:
```

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket
    location /ws/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Flutter Web App
    location / {
        root /var/www/docextract/web;
        try_files $uri $uri/ /index.html;
    }
}
```

### 3.2 Deployment Scripts

#### deploy.sh
```bash
#!/bin/bash

# Pull latest code
git pull origin main

# Build and restart backend
cd backend
docker-compose down
docker-compose up -d --build

# Build and deploy Flutter web
cd ../
flutter build web --release
sudo rm -rf /var/www/docextract/web
sudo cp -r build/web /var/www/docextract/

# Restart Nginx
sudo systemctl restart nginx

echo "Deployment complete!"
```

### 3.3 VPS Setup Checklist

- [ ] Ubuntu 22.04 LTS installed
- [ ] Docker and Docker Compose installed
- [ ] Nginx installed and configured
- [ ] Domain name pointed to VPS IP
- [ ] SSL certificate from Let's Encrypt
- [ ] Firewall configured (ports 80, 443, 22)
- [ ] MongoDB secured with authentication
- [ ] Environment variables set
- [ ] Backup scripts configured

---

## Phase 4: Play Store Preparation

### Branch: `release/v2.0-playstore`

### 4.1 Android App Configuration

#### android/app/build.gradle
```gradle
android {
    namespace "com.docextract.app"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.docextract.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "2.0.0"
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### AndroidManifest.xml Permissions
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="28" />
```

### 4.2 Store Assets Required

**Text Assets:**
- App Title: "DocExtract - AI Document Scanner"
- Short Description (80 chars): "Extract data from invoices & IDs using AI"
- Full Description (4000 chars): Detailed app description
- What's New: Version 2.0 features

**Visual Assets:**
- App Icon: 512x512 PNG (32-bit with alpha)
- Feature Graphic: 1024x500 PNG
- Screenshots:
  - Phone: At least 2 (min 320px)
  - 7-inch tablet: Optional
  - 10-inch tablet: Optional

**Legal:**
- Privacy Policy URL (required)
- Terms of Service (optional but recommended)

### 4.3 Build Commands

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build Android App Bundle (.aab)
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab

# Test build locally
flutter build apk --release
```

### 4.4 Play Console Setup Steps

1. Create app in Play Console
2. Upload app bundle
3. Fill out store listing
4. Set content rating (complete questionnaire)
5. Select app category (Business/Productivity)
6. Add privacy policy URL
7. Complete pricing & distribution (Free app)
8. Submit for review
9. Monitor review status (typically 1-7 days)

---

## Phase 5: Testing Strategy

### 5.1 Backend Testing

#### Unit Tests
- Test Pydantic model validation
- Test database CRUD operations
- Test LlamaParse service integration
- Test WebSocket manager

#### Integration Tests
- Test API endpoints end-to-end
- Test WebSocket connection and events
- Test error handling
- Test rate limiting

#### Load Testing
- Simulate multiple concurrent extractions
- Test WebSocket with 100+ connections
- Test database performance

### 5.2 Flutter Testing

#### Widget Tests
- Test home page UI
- Test document list filtering
- Test edit extraction screen

#### Integration Tests
- Test API service methods
- Test WebSocket connection
- Test offline behavior
- Test error states

#### Platform Testing
- Android emulator (multiple API levels)
- Physical Android device
- Web browsers (Chrome, Firefox, Safari)
- Different screen sizes

### 5.3 End-to-End Testing Scenarios

**Scenario 1: Upload & Extract Flow**
1. Open app → Select camera
2. Capture invoice image
3. Select document type (Invoice)
4. Wait for extraction (verify loading state)
5. Review extracted data
6. Edit if needed
7. Save document
8. Verify appears in home page
9. Open second device → Verify real-time sync

**Scenario 2: History & Management**
1. Open history screen
2. Filter by document type
3. Search for document
4. View document details
5. Copy data
6. Delete document
7. Verify real-time deletion on other device

**Scenario 3: Error Handling**
1. Disconnect internet → Try upload (verify error)
2. Invalid file type → Verify error message
3. Server down → Verify graceful degradation
4. Reconnect → Verify auto-sync

---

## Phase 6: Deployment & Release Timeline

### Week 1: Backend Development
- **Day 1-2:** Project structure, Pydantic models, MongoDB setup
- **Day 3:** API endpoints implementation
- **Day 4:** LlamaParse integration
- **Day 5:** WebSocket implementation
- **Day 6-7:** Backend testing and bug fixes

### Week 2: Flutter Refactoring
- **Day 8-9:** Remove Supabase, create ApiService
- **Day 10:** WebSocket service and provider updates
- **Day 11:** New home page UI
- **Day 12-13:** Flutter testing and bug fixes
- **Day 14:** Integration testing

### Week 3: Deployment & Release
- **Day 15:** VPS setup and backend deployment
- **Day 16:** Flutter web deployment
- **Day 17:** Play Store preparation and upload
- **Day 18-20:** Final testing and fixes
- **Day 21:** Play Store submission

**Total Timeline: 3 weeks (~21 days)**

---

## Environment Variables Reference

### Backend (.env)
```env
# MongoDB
MONGODB_URL=mongodb://username:password@localhost:27017/docextract
MONGO_USER=admin
MONGO_PASSWORD=secure_password

# LlamaParse
LLAMA_CLOUD_API_KEY=llx-your-api-key

# CORS
ALLOWED_ORIGINS=https://your-domain.com,http://localhost:3000

# Server
HOST=0.0.0.0
PORT=8000
```

### Flutter (API Configuration)
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.your-domain.com',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.your-domain.com/ws/documents',
  );
}
```

Build command:
```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.your-domain.com
```

---

## Success Metrics

### Technical Metrics
- [ ] All API endpoints return < 500ms response time
- [ ] WebSocket handles 100+ concurrent connections
- [ ] LlamaParse extraction completes within 30 seconds
- [ ] Zero data loss during deployment
- [ ] 99% uptime

### User Experience Metrics
- [ ] App launches in < 2 seconds
- [ ] Real-time sync works within 1 second
- [ ] Extraction accuracy > 95%
- [ ] Zero crashes in production

### Release Metrics
- [ ] Play Store app approved on first submission
- [ ] App rating target: 4.0+ stars
- [ ] Zero critical bugs in first week

---

## Risk Mitigation

### Technical Risks
1. **LlamaParse API Rate Limits**
   - Mitigation: Implement request queuing and retry logic
   - Backup: Cache frequent extractions

2. **WebSocket Connection Drops**
   - Mitigation: Auto-reconnect with exponential backoff
   - Backup: Polling fallback mechanism

3. **MongoDB Performance**
   - Mitigation: Proper indexing and query optimization
   - Backup: Implement caching layer with Redis

4. **VPS Downtime**
   - Mitigation: Set up monitoring and alerts
   - Backup: Prepare migration scripts for quick provider change

### Release Risks
1. **Play Store Rejection**
   - Mitigation: Follow all guidelines, provide privacy policy
   - Backup: Have legal review before submission

2. **Production Bugs**
   - Mitigation: Comprehensive testing phase
   - Backup: Rollback plan and hotfix deployment process

---

## Post-Release Roadmap

### v2.1 (Future Enhancements)
- [ ] User authentication (OAuth, email/password)
- [ ] Multi-user support with teams
- [ ] Export to PDF/Excel
- [ ] Bulk upload and processing
- [ ] Advanced search and filtering
- [ ] OCR for handwritten documents
- [ ] API for third-party integrations

### v2.2 (Performance Improvements)
- [ ] Redis caching layer
- [ ] CDN for static assets
- [ ] Database query optimization
- [ ] Image compression before upload
- [ ] Lazy loading for large datasets

### v3.0 (Major Features)
- [ ] iOS app (App Store release)
- [ ] Desktop app (Windows, macOS, Linux)
- [ ] AI-powered document classification
- [ ] Custom document types (user-defined schemas)
- [ ] Workflow automation
- [ ] Integration with accounting software

---

## Documentation Deliverables

1. **Backend API Documentation** (FastAPI auto-generated Swagger UI)
2. **Database Schema Documentation** (MongoDB collections and indexes)
3. **Flutter App Architecture Documentation** (Code documentation)
4. **Deployment Guide** (VPS setup and maintenance)
5. **User Guide** (How to use the app)
6. **Privacy Policy** (Required for Play Store)
7. **Contributing Guide** (If open-source)

---

## Contact & Support

- **Developer:** [Your Name]
- **Email:** [Your Email]
- **GitHub:** [Repository URL]
- **Documentation:** [Docs URL]
- **Support:** [Support Email/Form]

---

## Appendix A: API Endpoint Summary

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/extract` | Extract data from document | No (future) |
| POST | `/api/v1/documents` | Save extracted document | No (future) |
| GET | `/api/v1/documents` | List all documents | No (future) |
| GET | `/api/v1/documents/{id}` | Get document by ID | No (future) |
| DELETE | `/api/v1/documents/{id}` | Delete document | No (future) |
| GET | `/api/v1/stats` | Get document statistics | No (future) |
| WS | `/ws/documents` | Real-time document updates | No (future) |
| GET | `/health` | Health check | No |
| GET | `/docs` | API documentation | No |

---

## Appendix B: MongoDB Queries Reference

```javascript
// Get all documents
db.extracted_documents.find({})

// Filter by type
db.extracted_documents.find({ "document_type": "invoice" })

// Sort by date
db.extracted_documents.find({}).sort({ "created_at": -1 })

// Count by type
db.extracted_documents.aggregate([
  { $group: { _id: "$document_type", count: { $sum: 1 } } }
])

// Get recent documents (last 30 days)
db.extracted_documents.find({
  "created_at": { $gte: new Date(Date.now() - 30*24*60*60*1000) }
})

// Full-text search (requires text index)
db.extracted_documents.find({ $text: { $search: "search_term" } })
```

---

## Appendix C: Flutter Build Commands Reference

```bash
# Development builds
flutter run  # Run on connected device/emulator
flutter run -d chrome  # Run web app in Chrome
flutter run --release  # Release mode on device

# Production builds
flutter build apk --release  # Android APK
flutter build appbundle --release  # Android App Bundle (for Play Store)
flutter build web --release  # Web app
flutter build ios --release  # iOS app (requires macOS)

# With environment variables
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com \
  --dart-define=WS_URL=wss://api.your-domain.com/ws/documents

# Clean build
flutter clean && flutter pub get && flutter build appbundle --release
```

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-11 | Claude | Initial migration plan created and approved |

---

**End of Migration Plan Document**
