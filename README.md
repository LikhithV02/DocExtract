# DocExtract v2.0

A modern React + TypeScript web application for extracting information from documents using LlamaParse AI. This app specializes in processing government IDs and invoices with a FastAPI backend and MongoDB database.

> 🎉 **New in v2.0**: Migrated to React + TypeScript (Lovable stack), real-time WebSocket sync, Statistics dashboard, field-level copy buttons, and enhanced validation!

## ✨ Features

- 📁 **Upload documents** - Support for images (JPG, PNG) and PDF files
- 🆔 **Government ID extraction** - Extract information from passports, driver's licenses, national IDs, etc.
- 🧾 **Invoice extraction** - Extract details from Indian GST invoices with complete line items
- ✏️ **Edit with validation** - Review and edit extracted data with inline validation
- 📋 **Copy to clipboard** - One-click copy for any field
- 🔄 **Real-time sync** - WebSocket-based instant updates with connection status
- 💾 **MongoDB storage** - Fast, scalable document database
- 🚀 **Self-hosted** - Full control over your data and infrastructure
- 📊 **Statistics dashboard** - Visual insights into document processing and revenue
- 📜 **History view** - Browse, search, and manage all extracted documents
- 🎨 **Modern UI** - Built with React, TailwindCSS, and shadcn/ui components
- 🌐 **Responsive design** - Works seamlessly on desktop and mobile browsers

## 🏗️ Architecture

### v2.0 Stack

**Backend:**
- **FastAPI** - Modern, fast Python web framework
- **MongoDB** - NoSQL document database
- **LlamaParse** - AI-powered document extraction (server-side)
- **WebSocket** - Real-time bidirectional communication
- **Docker** - Containerized deployment

**Frontend:**
- **React 18** - Modern UI library
- **TypeScript** - Type-safe JavaScript
- **Vite** - Lightning-fast build tool
- **TailwindCSS** - Utility-first CSS framework
- **shadcn/ui** - High-quality React components
- **React Query** - Server state management
- **WebSocket** - Real-time updates

## 📋 Prerequisites

### Backend
- Docker & Docker Compose (recommended)
- Python 3.11+ (for local development)
- MongoDB 7.0+ (MongoDB Atlas recommended)
- LlamaCloud API key

### Frontend
- Node.js 18+ and npm
- Modern web browser (Chrome, Firefox, Safari, Edge)

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

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with backend URL (default: http://localhost:8000)
nano .env

# Start development server
npm run dev
```

The frontend will be available at `http://localhost:5173`

### 4. Using the Dev Script (Easiest)

```bash
# Start both backend and frontend together
./scripts/dev.sh
```

This script will:
- Set up environment files if needed
- Start the backend on port 8000
- Start the frontend on port 5173
- Display all access URLs

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

### Frontend Configuration

Configure the API endpoint in `frontend/.env`:

```bash
# Development
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_WS_URL=ws://localhost:8000/ws
VITE_API_PORT=8000

# Production (Railway)
# VITE_API_BASE_URL=https://your-backend.railway.app/api/v1
# VITE_WS_URL=wss://your-backend.railway.app/ws
```

## 🧑‍💻 Local Development & Testing

### Backend - Docker Commands

**Build the Docker images:**
```bash
cd backend
docker-compose build
```

**Start the backend services:**
```bash
docker-compose up
```

**Start in detached mode (background):**
```bash
docker-compose up -d
```

**View logs:**
```bash
docker-compose logs -f
```

**Stop services:**
```bash
docker-compose down
```

**Rebuild and restart (after code changes):**
```bash
docker-compose down
docker-compose build
docker-compose up
```

**Clean reset (removes volumes):**
```bash
docker-compose down -v
docker-compose build
docker-compose up
```

**Backend will be available at:**
- API: http://localhost:8000
- Health check: http://localhost:8000/health
- API docs: http://localhost:8000/docs

### Frontend - Local Testing

**Run React frontend with hot reload:**
```bash
cd frontend

# Development mode (with HMR)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

**Frontend will be available at:**
- Development: http://localhost:5173
- Preview: http://localhost:4173

## 📦 Deployment

### Docker Compose (Full Stack)

```bash
# Build and start all services
docker-compose up --build

# Access the application
- Frontend: http://localhost:8080
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
```

### Railway Deployment

Use the helper script for easy deployment:

```bash
./scripts/deploy-railway.sh
```

Or deploy manually:
1. Install Railway CLI: `npm install -g @railway/cli`
2. Login: `railway login`
3. Link project: `railway link`
4. Set environment variables in Railway dashboard
5. Deploy: `railway up`

See [LOVABLE_MIGRATION.md](LOVABLE_MIGRATION.md) for detailed migration guide.

## 🔄 Migration from Flutter

This project was migrated from Flutter to React + TypeScript in November 2025. The Flutter code has been archived in `archive/flutter-app/` for reference.

**Key changes:**
- Migrated to React 18 + TypeScript + Vite
- Enhanced UI with TailwindCSS and shadcn/ui
- Added Statistics dashboard
- Implemented field-level copy buttons
- Added inline validation
- Improved WebSocket integration
- No raw JSON visible in UI

For complete migration details, see [LOVABLE_MIGRATION.md](LOVABLE_MIGRATION.md)

## 🧪 Testing

### Running Tests

```bash
# Backend tests
cd backend
pytest

# Frontend tests (if configured)
cd frontend
npm test
```

### Integration Testing

1. **Start both services:**
   ```bash
   ./scripts/dev.sh
   ```

2. **Test the flow:**
   - Upload a document at http://localhost:5173
   - Verify extraction results display correctly
   - Edit and save the document
   - Check WebSocket live indicator
   - View document in History page
   - Check Statistics dashboard

3. **Monitor logs:**
   ```bash
   # Backend logs
   docker-compose logs -f backend

   # Or if running locally
   # Check terminal where uvicorn is running
   ```

## 📚 Documentation

- [API Documentation](API_DOCUMENTATION.md) - Complete API reference
- [Migration Guide](LOVABLE_MIGRATION.md) - Flutter to React migration
- [Railway Deployment](RAILWAY_DEPLOYMENT_PLAN.md) - Production deployment
- [MongoDB Setup](MONGODB_ATLAS_SETUP.md) - Database configuration

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
