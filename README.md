# DocExtract v2.0

A Flutter mobile and web application for extracting information from documents using LlamaParse AI. This app specializes in processing government IDs and invoices with a centralized FastAPI backend.

> 🎉 **New in v2.0**: FastAPI + MongoDB backend, real-time WebSocket sync, centralized document extraction, and self-hosted deployment!

## ✨ Features

- 📸 **Capture photos** directly from your device camera (Android only)
- 📁 **Upload images** (JPG, PNG) or PDF documents
- 🆔 **Government ID extraction** - Extract information from passports, driver's licenses, national IDs, etc.
- 🧾 **Invoice extraction** - Extract details from Indian GST invoices with complete line items
- ✏️ **Edit before saving** - Review and edit all extracted data before saving to database
- 🔄 **Real-time sync** - WebSocket-based instant sync across all devices
- 💾 **MongoDB storage** - Fast, scalable document database
- 🚀 **Self-hosted** - Full control over your data and infrastructure
- 📱 **Cross-platform** - Runs on Android and as a web application
- 📜 **History view** - Browse and manage all previously extracted documents
- 📊 **Statistics** - Track document counts by type

## 🏗️ Architecture

### v2.0 Stack

**Backend:**
- **FastAPI** - Modern, fast Python web framework
- **MongoDB** - NoSQL document database
- **LlamaParse** - AI-powered document extraction (server-side)
- **WebSocket** - Real-time bidirectional communication
- **Docker** - Containerized deployment

**Frontend:**
- **Flutter/Dart** - Cross-platform UI framework
- **Provider** - State management
- **Dio** - HTTP client
- **WebSocket** - Real-time updates

## 📋 Prerequisites

### Backend
- Docker & Docker Compose
- Python 3.11+ (for local development)
- MongoDB 7.0+ (or use Docker)
- LlamaCloud API key

### Frontend
- Flutter SDK 3.0.0+
- Dart SDK (comes with Flutter)
- Android Studio (for Android development)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/DocExtract.git
cd DocExtract
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Configure these variables:
```env
MONGODB_URL=mongodb://admin:your_password@mongodb:27017
MONGO_USER=admin
MONGO_PASSWORD=your_secure_password
LLAMA_CLOUD_API_KEY=llx-your-api-key
ALLOWED_ORIGINS=http://localhost:3000,https://your-domain.com
```

Start the backend:
```bash
docker-compose up -d
```

Verify it's running:
```bash
curl http://localhost:8000/health
# Should return: {"status":"healthy","database":"connected"}
```

### 3. Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run

# Or run on Web
flutter run -d chrome
```

## 📖 Detailed Setup

### Backend Development Setup

For local development without Docker:

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run MongoDB locally or use Docker
docker run -d -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:7.0

# Start the backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter App Configuration

Configure the API endpoint:

**Option A: Environment Variable (Recommended)**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 \
            --dart-define=WS_URL=ws://localhost:8000/ws/documents
```

**Option B: Edit Configuration File**
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://localhost:8000';
static const String wsUrl = 'ws://localhost:8000/ws/documents';
```

## 🌐 Production Deployment

### VPS Deployment

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for complete deployment instructions.

Quick deploy script:
```bash
./deploy.sh
```

### Nginx Configuration

```bash
# Copy Nginx config
sudo cp backend/nginx.conf /etc/nginx/sites-available/docextract
sudo ln -s /etc/nginx/sites-available/docextract /etc/nginx/sites-enabled/

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

## 🔌 API Documentation

Once the backend is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

```
POST   /api/v1/extract          # Extract data from document
POST   /api/v1/documents        # Save document
GET    /api/v1/documents        # List documents
GET    /api/v1/documents/{id}   # Get document by ID
DELETE /api/v1/documents/{id}   # Delete document
GET    /api/v1/stats            # Get statistics
WS     /ws/documents            # WebSocket for real-time updates
```

## 📁 Project Structure

```
DocExtract/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── main.py            # FastAPI application
│   │   ├── config.py          # Configuration
│   │   ├── models/            # Pydantic models
│   │   ├── schemas/           # LlamaParse schemas
│   │   ├── routes/            # API endpoints
│   │   ├── services/          # Business logic
│   │   │   ├── database.py    # MongoDB operations
│   │   │   ├── llamaparse.py  # LlamaParse integration
│   │   │   └── websocket_manager.py
│   │   └── utils/             # Utilities
│   ├── tests/                 # Backend tests
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
│
├── lib/                       # Flutter app
│   ├── main.dart
│   ├── config/
│   │   └── api_config.dart    # API configuration
│   ├── models/
│   │   └── extracted_document.dart
│   ├── providers/
│   │   └── document_provider.dart  # State + WebSocket
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── document_type_selection_screen.dart
│   │   ├── edit_extraction_screen.dart
│   │   ├── extraction_result_screen.dart
│   │   └── history_screen.dart
│   └── services/
│       ├── api_service.dart       # REST API client
│       └── websocket_service.dart # WebSocket client
│
├── deploy.sh                  # Deployment script
├── MIGRATION_GUIDE.md         # Migration from v1.0
└── README.md                  # This file
```

## 🧪 Testing

### Backend Tests

```bash
cd backend
pip install pytest
pytest tests/ -v
```

### Flutter Tests

```bash
flutter test
```

## 📊 Extracted Data Formats

### Government ID (9 fields)
- Full Name
- ID Number
- Date of Birth
- Gender
- Address
- Issue Date
- Expiry Date
- Nationality
- Document Type

### Invoice (Indian GST Format)

**7 Main Sections:**
1. **Seller Information** - Name, GSTIN, Contact Numbers
2. **Customer Information** - Name, Address, Contact, GSTIN
3. **Invoice Details** - Date, Bill Number, Gold Price
4. **Line Items** - Description, HSN Code, Weight, Rate, Amount, etc.
5. **Financial Summary** - Subtotal, Taxes (SGST/CGST), Grand Total
6. **Payment Details** - Cash, UPI, Card
7. **Total in Words** - Amount in text format

## 🔧 Troubleshooting

### Backend Issues

**MongoDB Connection Error:**
```bash
# Reset MongoDB
cd backend
docker-compose down -v
docker-compose up -d
```

**LlamaParse API Errors:**
- Verify API key in `.env`
- Check quota at https://cloud.llamaindex.ai
- Test API key:
```bash
curl -H "Authorization: Bearer YOUR_KEY" \
  https://api.cloud.llamaindex.ai/api/v1/extraction/run
```

### Flutter Issues

**WebSocket Not Connecting:**
- Check API endpoint configuration
- Verify backend is running: `curl http://localhost:8000/health`
- Check firewall rules

**Camera Not Working (Android):**
- Grant camera permissions in Settings > Apps > DocExtract > Permissions

## 📈 Performance

- **Extraction Time**: 10-30 seconds (depends on document complexity)
- **WebSocket Latency**: < 100ms for real-time updates
- **Concurrent Users**: Tested with 100+ simultaneous connections
- **Database**: MongoDB indexes optimize query performance

## 💰 Costs

- **LlamaParse**: ~$0.003 per page ([pricing](https://cloud.llamaindex.ai))
- **VPS Hosting**: $5-20/month (DigitalOcean, Linode, etc.)
- **Domain**: ~$10-15/year
- **SSL Certificate**: Free (Let's Encrypt)

## 🔄 Migration from v1.0

If you're upgrading from Supabase-based v1.0, see [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md).

## 🎯 Roadmap

- [ ] User authentication (OAuth, JWT)
- [ ] Multi-user support with teams
- [ ] Export to PDF/Excel
- [ ] Bulk upload and processing
- [ ] iOS app release
- [ ] Advanced search and filtering
- [ ] Custom document types (user-defined schemas)
- [ ] API for third-party integrations

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - UI framework
- [FastAPI](https://fastapi.tiangolo.com) - Web framework
- [LlamaIndex](https://www.llamaindex.ai) - Document extraction
- [MongoDB](https://www.mongodb.com) - Database
- [Docker](https://www.docker.com) - Containerization

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/DocExtract/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/DocExtract/discussions)
- **Email**: support@your-domain.com

---

**Version**: 2.0.0
**Last Updated**: 2025-11-11
**Status**: Production Ready ✅
