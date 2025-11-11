# Docker Compose Setup Guide

This guide explains how to run DocExtract locally using Docker Compose for easy development and testing.

## Prerequisites

- Docker Desktop installed ([Download](https://www.docker.com/products/docker-desktop))
- Docker Compose (included with Docker Desktop)
- LlamaCloud API key ([Get one here](https://cloud.llamaindex.ai))

## Quick Start

### 1. Set Up Environment Variables

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and configure:

#### Option A: MongoDB Cloud (Atlas) - RECOMMENDED

```env
LLAMA_CLOUD_API_KEY=llx-your-actual-api-key-here
MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/docextract?retryWrites=true&w=majority
MONGODB_DB_NAME=docextract
```

**See [MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md) for detailed MongoDB Atlas setup.**

#### Option B: Local MongoDB

Uncomment the MongoDB service in `docker-compose.yml` and use:

```env
LLAMA_CLOUD_API_KEY=llx-your-actual-api-key-here
MONGODB_URL=mongodb://admin:password123@mongodb:27017
MONGODB_DB_NAME=docextract
```

### 2. Start All Services

From the project root directory:

```bash
docker-compose up --build
```

This will start:
- **Backend** (FastAPI) on port `8000`
- **Frontend** (Flutter Web) on port `8080`
- **MongoDB** (Optional) on port `27017` - if using local MongoDB

### 3. Access the Application

Once all services are running:

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **MongoDB** (if local): `mongodb://admin:password123@localhost:27017`

## Docker Compose Commands

### Start Services

```bash
# Start all services (with logs)
docker-compose up

# Start in background (detached mode)
docker-compose up -d

# Rebuild and start
docker-compose up --build
```

### Stop Services

```bash
# Stop all services (keeps containers)
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (clears database)
docker-compose down -v
```

### View Logs

```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend
```

### Check Service Status

```bash
docker-compose ps
```

## Service Details

### MongoDB Service (Optional - Local Only)

**Default configuration uses MongoDB Atlas (cloud). To use local MongoDB:**

1. Uncomment the `mongodb` service in `docker-compose.yml`
2. Update backend `depends_on` to include mongodb
3. Use local connection string in `.env`

When enabled:
- **Container**: `docextract_mongodb`
- **Port**: 27017
- **Username**: `admin`
- **Password**: `password123` (configurable)
- **Database**: `docextract`
- **Data Persistence**: Volumes `mongodb_data` and `mongodb_config`

### Backend Service

- **Container**: `docextract_backend`
- **Port**: 8000
- **Health Check**: `/health` endpoint
- **Depends on**: MongoDB (waits for it to be healthy)
- **Environment**:
  - `MONGODB_URL`: Connection to MongoDB service
  - `LLAMA_CLOUD_API_KEY`: From .env file
  - `ALLOWED_ORIGINS`: CORS configuration

### Frontend Service

- **Container**: `docextract_frontend`
- **Port**: 8080
- **Build Args**:
  - `API_BASE_URL`: http://localhost:8000
  - `WS_URL`: ws://localhost:8000/ws/documents
- **Server**: Nginx serving Flutter web build
- **Depends on**: Backend (waits for it to be healthy)

## Backend-Only Development

If you only want to run the backend with MongoDB:

```bash
cd backend
docker-compose up
```

This uses `backend/docker-compose.yml` which includes:
- MongoDB on port 27017
- Backend on port 8000

You can then run Flutter web locally:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_URL=ws://localhost:8000/ws/documents
```

## Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

1. Check what's using the port:
   ```bash
   # Check port 8000
   lsof -i :8000

   # Check port 8080
   lsof -i :8080

   # Check port 27017
   lsof -i :27017
   ```

2. Stop the conflicting process or change ports in `docker-compose.yml`

### Services Not Starting

Check logs for errors:

```bash
docker-compose logs
```

Common issues:
- **MongoDB**: Insufficient disk space or memory
- **Backend**: Missing `.env` file or invalid API key
- **Frontend**: Build failures (check Flutter dependencies)

### Health Check Failing

Wait a bit longer - services have startup times:
- MongoDB: ~10 seconds
- Backend: ~20 seconds (waits for MongoDB)
- Frontend: ~10 seconds

Check health status:

```bash
docker-compose ps
```

### Database Reset

To start with a fresh database:

```bash
# Stop and remove volumes
docker-compose down -v

# Start again
docker-compose up
```

### Rebuild After Code Changes

```bash
# Rebuild specific service
docker-compose build backend
docker-compose up -d backend

# Rebuild all services
docker-compose build
docker-compose up -d
```

## Development Workflow

### 1. Backend Development

When making backend changes:

```bash
# Stop backend
docker-compose stop backend

# Rebuild backend
docker-compose build backend

# Start backend
docker-compose up -d backend

# View logs
docker-compose logs -f backend
```

### 2. Frontend Development

For frontend changes, it's faster to run Flutter locally:

```bash
# Keep backend running in Docker
docker-compose up -d mongodb backend

# Run Flutter with hot reload
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_URL=ws://localhost:8000/ws/documents
```

### 3. Database Management

Connect to MongoDB:

```bash
# Using mongosh (if installed locally)
mongosh mongodb://admin:password123@localhost:27017/docextract

# Or exec into container
docker exec -it docextract_mongodb mongosh -u admin -p password123 docextract
```

## Production Deployment

For production deployment, see:
- [RAILWAY_QUICK_START.md](RAILWAY_QUICK_START.md) - Deploy to Railway
- [RAILWAY_DEPLOYMENT_PLAN.md](RAILWAY_DEPLOYMENT_PLAN.md) - Detailed deployment guide

## Configuration

### Customizing Ports

Edit `docker-compose.yml`:

```yaml
services:
  backend:
    ports:
      - "8001:8000"  # Change host port to 8001

  frontend:
    ports:
      - "3000:80"    # Change host port to 3000
```

### Customizing MongoDB

Edit `docker-compose.yml`:

```yaml
services:
  mongodb:
    environment:
      MONGO_INITDB_ROOT_USERNAME: myuser
      MONGO_INITDB_ROOT_PASSWORD: mypassword
```

Don't forget to update backend environment variables to match!

## Architecture

### With MongoDB Atlas (Default)

```
                 ┌─────────────────────┐
                 │   MongoDB Atlas     │
                 │   (Cloud)           │
                 └──────────▲──────────┘
                            │
┌───────────────────────────┼─────────────────────┐
│         Docker Compose    │                     │
│                           │                     │
│                  ┌────────┴─────┐               │
│                  │   Backend    │               │
│                  │    :8000     │               │
│                  └────────▲─────┘               │
│                           │                     │
│                  ┌────────┴─────┐               │
│                  │   Frontend   │               │
│                  │    :8080     │               │
│                  └──────────────┘               │
│                                                 │
└─────────────────────────────────────────────────┘
                     │            │
                localhost:8000  localhost:8080
                     │            │
                ┌────▼────────────▼────┐
                │   Your Browser        │
                └───────────────────────┘
```

### With Local MongoDB (Optional)

```
┌─────────────────────────────────────────┐
│         Docker Compose Network          │
│                                         │
│  ┌──────────┐   ┌──────────┐          │
│  │ MongoDB  │◄──│ Backend  │          │
│  │  :27017  │   │  :8000   │          │
│  └──────────┘   └─────▲────┘          │
│                       │                │
│                  ┌────┴─────┐          │
│                  │ Frontend │          │
│                  │  :8080   │          │
│                  └──────────┘          │
│                                         │
└─────────────────────────────────────────┘
           │            │
      localhost:8000  localhost:8080
           │            │
      ┌────▼────────────▼────┐
      │   Your Browser        │
      └───────────────────────┘
```

## Support

For issues or questions:
- Check [README.md](README.md) for general documentation
- View [TROUBLESHOOTING.md](backend/TROUBLESHOOTING.md) for common issues
- Report bugs at [GitHub Issues](https://github.com/yourusername/DocExtract/issues)
