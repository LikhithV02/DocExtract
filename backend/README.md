# DocExtract Backend API

FastAPI + MongoDB + LlamaParse backend for DocExtract v2.0

## Features

- **Document Extraction**: Extract data from Government IDs and Invoices using LlamaParse
- **MongoDB Storage**: Store extracted documents in MongoDB
- **Real-time Sync**: WebSocket support for real-time updates
- **RESTful API**: Complete CRUD operations for documents
- **Type Safety**: Full Pydantic validation
- **Docker Support**: Easy deployment with Docker Compose

## Tech Stack

- **Framework**: FastAPI 0.104.1
- **Database**: MongoDB 7.0 (via Motor async driver)
- **Extraction**: LlamaParse (Official SDK)
- **Validation**: Pydantic 2.5.0
- **WebSocket**: Native FastAPI WebSocket support

## Setup

### 1. Prerequisites

- Python 3.11+
- MongoDB 7.0+ (or use Docker Compose)
- LlamaCloud API Key

### 2. Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
MONGODB_URL=mongodb://admin:password@localhost:27017
LLAMA_CLOUD_API_KEY=llx-your-api-key
```

### 3. Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Docker Deployment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## API Endpoints

### Health Check

```
GET /health
```

### Extraction

```
POST /api/v1/extract
Content-Type: application/json

{
  "file_data": "base64_encoded_file",
  "file_name": "invoice.pdf",
  "document_type": "invoice"
}
```

### Documents

```
# Create document
POST /api/v1/documents

# List documents
GET /api/v1/documents?document_type=invoice&limit=20&offset=0

# Get document by ID
GET /api/v1/documents/{id}

# Delete document
DELETE /api/v1/documents/{id}
```

### Statistics

```
GET /api/v1/stats
```

### WebSocket

```
WS /ws/documents
```

## API Documentation

Once running, visit:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── config.py            # Configuration
│   ├── models/              # Pydantic models
│   ├── schemas/             # LlamaParse schemas
│   ├── routes/              # API endpoints
│   ├── services/            # Business logic
│   └── utils/               # Utilities
├── tests/                   # Test files
├── .env.example             # Environment template
├── requirements.txt         # Python dependencies
├── Dockerfile               # Docker image
├── docker-compose.yml       # Docker Compose config
└── README.md                # This file
```

## Testing

```bash
# Run tests
pytest

# Run with coverage
pytest --cov=app tests/
```

## Deployment

See [deployment guide](../DEPLOYMENT.md) for VPS deployment instructions.

## License

See root LICENSE file.
