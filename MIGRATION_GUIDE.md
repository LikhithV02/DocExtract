# DocExtract v2.0 Migration Guide

## Overview

This guide helps you migrate from DocExtract v1.0 (Supabase) to v2.0 (FastAPI + MongoDB).

---

## What's Changed

### Backend
- **From:** Supabase (PostgreSQL + Auth + Storage)
- **To:** FastAPI + MongoDB + LlamaParse
- **Why:** Centralized control, better performance, WebSocket support

### Key Changes
1. **No File Storage**: Files are not stored, only extracted data
2. **Centralized Extraction**: LlamaParse runs on backend, not client
3. **Real-time Sync**: WebSocket instead of Supabase Realtime
4. **Self-hosted**: Full control over your data and infrastructure

---

## Migration Steps

### Step 1: Backend Setup

#### 1.1 Install Prerequisites

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker docker-compose nginx certbot python3-certbot-nginx

# macOS
brew install docker docker-compose nginx
```

#### 1.2 Configure Environment

```bash
cd backend
cp .env.example .env
nano .env
```

Update these values:
```env
MONGODB_URL=mongodb://admin:your_password@mongodb:27017
MONGO_USER=admin
MONGO_PASSWORD=your_secure_password
LLAMA_CLOUD_API_KEY=llx-your-api-key
ALLOWED_ORIGINS=https://your-domain.com
```

#### 1.3 Start Backend

```bash
# Development
cd backend
docker-compose up -d

# Production
./deploy.sh
```

#### 1.4 Verify Backend

```bash
curl http://localhost:8000/health
# Should return: {"status":"healthy","database":"connected"}
```

---

### Step 2: Data Migration (Optional)

**Note:** DocExtract v2.0 starts fresh. If you need to migrate existing data:

#### 2.1 Export from Supabase

```sql
-- In Supabase SQL Editor
COPY (
    SELECT id, document_type, file_name, extracted_data, created_at
    FROM extracted_documents
) TO '/tmp/documents.csv' CSV HEADER;
```

#### 2.2 Import to MongoDB

```python
# migration_script.py
import csv
import requests
import json

API_URL = "http://localhost:8000/api/v1/documents"

with open('documents.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        payload = {
            "document_type": row['document_type'],
            "file_name": row['file_name'],
            "extracted_data": json.loads(row['extracted_data'])
        }
        response = requests.post(API_URL, json=payload)
        print(f"Migrated: {row['file_name']} - Status: {response.status_code}")
```

---

### Step 3: Flutter App Update

#### 3.1 Update Dependencies

```bash
flutter pub get
```

#### 3.2 Configure API Endpoint

Option A: Environment Variable (Recommended)
```bash
flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.com
```

Option B: Edit `lib/config/api_config.dart`
```dart
static const String baseUrl = 'https://api.your-domain.com';
static const String wsUrl = 'wss://api.your-domain.com/ws/documents';
```

#### 3.3 Remove Supabase Initialization

The app no longer needs Supabase.initialize(). This has been removed from `main.dart`.

---

### Step 4: VPS Deployment

#### 4.1 SSL Certificate

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

#### 4.2 Configure Nginx

```bash
sudo cp backend/nginx.conf /etc/nginx/sites-available/docextract
sudo ln -s /etc/nginx/sites-available/docextract /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 4.3 Set Up Auto-deployment

```bash
# Create systemd service for auto-restart
sudo nano /etc/systemd/system/docextract.service
```

```ini
[Unit]
Description=DocExtract Backend
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/DocExtract/backend
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable docextract
sudo systemctl start docextract
```

---

### Step 5: Testing

#### 5.1 Backend Tests

```bash
cd backend
pip install pytest
pytest tests/ -v
```

#### 5.2 API Manual Test

```bash
# Test extraction
curl -X POST http://localhost:8000/api/v1/extract \
  -H "Content-Type: application/json" \
  -d '{
    "file_data": "base64_encoded_file",
    "file_name": "test.pdf",
    "document_type": "invoice"
  }'
```

#### 5.3 WebSocket Test

```javascript
// In browser console
const ws = new WebSocket('ws://localhost:8000/ws/documents');
ws.onmessage = (event) => console.log('Received:', event.data);
```

---

## Troubleshooting

### Backend Not Starting

**Problem:** Docker containers fail to start

**Solution:**
```bash
cd backend
docker-compose logs
# Check for port conflicts
sudo lsof -i :8000
sudo lsof -i :27017
```

### MongoDB Connection Error

**Problem:** `MongoServerError: Authentication failed`

**Solution:**
1. Check `.env` file for correct credentials
2. Reset MongoDB:
```bash
docker-compose down -v
docker-compose up -d
```

### WebSocket Not Connecting

**Problem:** WebSocket connection refused

**Solution:**
1. Check Nginx configuration for `/ws/` location
2. Verify WebSocket upgrade headers
3. Check firewall rules:
```bash
sudo ufw allow 80
sudo ufw allow 443
```

### LlamaParse Extraction Fails

**Problem:** `403 Forbidden` or `401 Unauthorized`

**Solution:**
1. Verify API key in `.env`
2. Check LlamaParse quota at https://cloud.llamaindex.ai
3. Test API key:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.cloud.llamaindex.ai/api/v1/extraction/run
```

---

## Performance Optimization

### 1. MongoDB Indexing

```javascript
// In MongoDB shell
use docextract
db.extracted_documents.createIndex({ "document_type": 1 })
db.extracted_documents.createIndex({ "created_at": -1 })
db.extracted_documents.createIndex({ "id": 1 }, { unique: true })
```

### 2. Enable Redis Caching (Future)

```yaml
# docker-compose.yml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
```

### 3. Nginx Caching

```nginx
# In nginx.conf
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=100m;

location /api/v1/documents {
    proxy_cache api_cache;
    proxy_cache_valid 200 5m;
}
```

---

## Rollback Plan

If you need to rollback to v1.0:

1. Switch to v1.0 branch:
```bash
git checkout v1.0
```

2. Restore Supabase configuration

3. Rebuild Flutter app:
```bash
flutter clean
flutter pub get
flutter build apk
```

---

## Post-Migration Checklist

- [ ] Backend API running and healthy
- [ ] MongoDB connected and indexed
- [ ] SSL certificate installed
- [ ] Nginx configured and running
- [ ] WebSocket connections working
- [ ] Flutter app connected to new backend
- [ ] Data migrated (if applicable)
- [ ] Backups configured
- [ ] Monitoring set up
- [ ] Documentation updated

---

## Getting Help

- **Issues:** https://github.com/yourusername/DocExtract/issues
- **Documentation:** https://docs.your-domain.com
- **Email:** support@your-domain.com

---

## FAQ

**Q: Can I use Supabase and FastAPI together?**
A: Not recommended. v2.0 is designed to be independent.

**Q: What happens to my Supabase data?**
A: It remains in Supabase. You can export it if needed.

**Q: Is MongoDB required?**
A: Yes, but you can modify the code to use PostgreSQL if needed.

**Q: Can I deploy on Heroku/Railway/Render?**
A: Yes! Docker Compose works on most platforms.

**Q: What's the cost difference?**
A: v2.0 requires VPS ($5-10/month) + LlamaParse API. Supabase was free tier.

---

## Next Steps

1. Read the [Backend README](backend/README.md)
2. Check [API Documentation](http://localhost:8000/docs)
3. Review [Play Store Guide](PLAY_STORE_GUIDE.md) (coming soon)
4. Join our [Community Discord](https://discord.gg/your-invite)

---

**Migration Version:** 1.0
**Last Updated:** 2025-11-11
**Author:** DocExtract Team
