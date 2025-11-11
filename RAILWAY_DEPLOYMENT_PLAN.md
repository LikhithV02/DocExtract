# Railway Deployment Plan - DocExtract v2.0

## Overview
This plan covers deploying the DocExtract application to Railway with:
- **Backend**: FastAPI + MongoDB (Docker container)
- **Frontend**: Flutter Web App (Static hosting)
- **Database**: MongoDB Atlas or Railway PostgreSQL + MongoDB plugin

---

## Architecture on Railway

```
┌─────────────────────────────────────────────────────────┐
│                    Railway Project                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────┐         ┌──────────────────┐     │
│  │  Backend Service │◄────────┤  MongoDB Atlas   │     │
│  │  (FastAPI)       │         │  (External)      │     │
│  │  Port: 8000      │         └──────────────────┘     │
│  └────────┬─────────┘                                   │
│           │                                              │
│           │ API Calls                                    │
│           │                                              │
│  ┌────────▼─────────┐                                   │
│  │  Flutter Web     │                                    │
│  │  (Static Files)  │                                    │
│  │  via Railway     │                                    │
│  │  Static Hosting  │                                    │
│  └──────────────────┘                                   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: Prerequisites

### 1.1 Required Accounts
- [ ] Railway account (https://railway.app)
- [ ] MongoDB Atlas account (https://www.mongodb.com/cloud/atlas) - Free tier available
- [ ] LlamaParse API key (https://cloud.llamaindex.ai)
- [ ] GitHub account with repository access

### 1.2 Local Setup
```bash
# Ensure your code is committed and pushed
git add .
git commit -m "Prepare for Railway deployment"
git push origin claude/railway-deployment-plan-011CV2JmozcwAoCFbEfHnn2j
```

---

## Phase 2: MongoDB Setup (MongoDB Atlas - Recommended)

### 2.1 Create MongoDB Cluster
1. Go to https://www.mongodb.com/cloud/atlas
2. Sign up / Log in
3. Create a **FREE** M0 cluster
   - Cloud Provider: AWS / Google Cloud / Azure (choose closest region)
   - Cluster Name: `docextract-cluster`

### 2.2 Configure Database Access
1. **Database Access** → Add New Database User
   - Username: `docextract_user`
   - Password: Generate secure password (save it!)
   - Database User Privileges: `Read and write to any database`

### 2.3 Configure Network Access
1. **Network Access** → Add IP Address
   - **Option A**: Allow access from anywhere: `0.0.0.0/0` (for Railway)
   - **Option B**: Add Railway's IP ranges (check Railway docs)

### 2.4 Get Connection String
1. **Database** → Connect → **Connect your application**
2. Driver: **Python** / Version: **3.11 or later**
3. Copy connection string:
   ```
   mongodb+srv://docextract_user:<password>@docextract-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
4. Replace `<password>` with your actual password
5. Add database name:
   ```
   mongodb+srv://docextract_user:<password>@docextract-cluster.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
   ```

---

## Phase 3: Backend Deployment on Railway

### 3.1 Create Railway Project
1. Go to https://railway.app/dashboard
2. Click **New Project**
3. Select **Deploy from GitHub repo**
4. Choose your `DocExtract` repository
5. Select branch: `claude/railway-deployment-plan-011CV2JmozcwAoCFbEfHnn2j` (or your main branch)

### 3.2 Configure Backend Service
1. **Service Name**: `docextract-backend`
2. **Root Directory**: `/backend` (IMPORTANT!)
3. **Build Method**: Dockerfile
4. **Dockerfile Path**: `Dockerfile` (relative to backend folder)

### 3.3 Set Environment Variables
In Railway project → `docextract-backend` → **Variables** tab:

```env
# MongoDB Configuration
MONGODB_URL=mongodb+srv://docextract_user:<password>@docextract-cluster.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
MONGODB_DB_NAME=docextract

# LlamaParse AI Configuration
LLAMA_CLOUD_API_KEY=llx-your-llamaparse-api-key-here

# Server Configuration
HOST=0.0.0.0
PORT=8000

# CORS Configuration (Update after deploying frontend)
ALLOWED_ORIGINS=https://your-railway-domain.up.railway.app,https://your-custom-domain.com

# Optional: Application Settings
LOG_LEVEL=info
```

### 3.4 Deploy Backend
1. Railway will automatically build and deploy
2. Monitor deployment logs in **Deployments** tab
3. Once deployed, note your backend URL:
   - Example: `https://docextract-backend-production.up.railway.app`

### 3.5 Verify Backend Health
```bash
# Test health endpoint
curl https://your-backend-url.up.railway.app/health

# Expected response:
{"status":"healthy","database":"connected"}
```

---

## Phase 4: Flutter Web App Deployment

### 4.1 Build Flutter Web App Locally

```bash
# Navigate to project root
cd /home/user/DocExtract

# Build for production with Railway backend URL
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-backend-url.up.railway.app \
  --dart-define=WS_URL=wss://your-backend-url.up.railway.app/ws/documents

# Output will be in: build/web/
```

### 4.2 Deploy Flutter Web to Railway

**Option A: Railway Static Site (Recommended)**

1. Create a new service in your Railway project
2. **Service Name**: `docextract-frontend`
3. **Deploy from**: Same GitHub repository
4. Create a `Dockerfile` in project root:

```dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY backend/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

5. Add build step to generate Flutter web:
   - Create `railway.toml` in project root (see Phase 5)

**Option B: Use Netlify/Vercel for Frontend (Alternative)**

1. Deploy `build/web/` folder to Netlify or Vercel
2. Set environment variables in build settings
3. Configure custom domain

---

## Phase 5: Railway Configuration Files

### 5.1 Create `railway.toml` for Backend

Create `/backend/railway.toml`:
```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[[services]]
name = "backend"
```

### 5.2 Create Root Dockerfile (for Frontend)

Create `/Dockerfile` in project root:
```dockerfile
# Build Flutter Web
FROM cirrusci/flutter:3.19.0 AS build-stage

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Build arguments for API configuration
ARG API_BASE_URL
ARG WS_URL

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=WS_URL=${WS_URL}

# Production Nginx server
FROM nginx:alpine
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Custom nginx config for Flutter
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 5.3 Environment Variables for Frontend Service

In Railway → Frontend Service → Variables:
```env
API_BASE_URL=https://your-backend-url.up.railway.app
WS_URL=wss://your-backend-url.up.railway.app/ws/documents
```

---

## Phase 6: Domain Configuration & CORS

### 6.1 Configure Custom Domains (Optional)
1. Railway → Backend Service → **Settings** → **Domains**
2. Add custom domain: `api.yourdomain.com`
3. Add DNS records as instructed by Railway

4. Railway → Frontend Service → **Settings** → **Domains**
5. Add custom domain: `app.yourdomain.com`
6. Add DNS records

### 6.2 Update CORS Settings
After deploying frontend, update backend environment variable:

```env
ALLOWED_ORIGINS=https://your-frontend.up.railway.app,https://app.yourdomain.com
```

Redeploy backend service.

---

## Phase 7: Testing & Verification

### 7.1 Backend Tests
```bash
# Health check
curl https://your-backend.up.railway.app/health

# API documentation
curl https://your-backend.up.railway.app/api/v1/docs

# Test document creation (requires authentication)
curl -X POST https://your-backend.up.railway.app/api/v1/documents \
  -H "Content-Type: application/json" \
  -d '{"document_type":"invoice","extracted_data":{}}'
```

### 7.2 Frontend Tests
1. Open your frontend URL in browser
2. Test document upload
3. Test WebSocket connection (real-time updates)
4. Check browser console for errors
5. Test on mobile devices

### 7.3 Integration Tests
- Upload a document through frontend
- Verify it appears in MongoDB Atlas
- Check WebSocket updates
- Test document deletion
- Verify statistics endpoint

---

## Phase 8: Monitoring & Maintenance

### 8.1 Railway Monitoring
- **Metrics**: CPU, Memory, Network usage in Railway dashboard
- **Logs**: View real-time logs in Deployments tab
- **Alerts**: Set up alerts for service downtime

### 8.2 MongoDB Atlas Monitoring
- **Performance**: Query performance in Atlas dashboard
- **Alerts**: Configure alerts for connection issues
- **Backups**: Enable automatic backups (paid feature)

### 8.3 Application Logs
Monitor FastAPI logs in Railway:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Connected to MongoDB successfully
```

---

## Cost Estimate

### Free Tier (Development)
- **Railway**: $5 credit/month (500 hours execution time)
- **MongoDB Atlas**: Free M0 cluster (512 MB storage)
- **LlamaParse**: Free tier (varies by plan)
- **Total**: $0-5/month for development

### Production (Estimated)
- **Railway**: $10-20/month (Hobby plan)
- **MongoDB Atlas**: $0 (Free tier) or $9/month (M10 cluster)
- **LlamaParse**: Check pricing at https://cloud.llamaindex.ai
- **Total**: $10-30/month

---

## Rollback Plan

If deployment fails:

### Backend Rollback
```bash
# In Railway dashboard
1. Go to Deployments
2. Find last working deployment
3. Click "Redeploy"
```

### Database Rollback
```bash
# MongoDB Atlas
1. Use Point-in-Time restore (if enabled)
2. Or restore from backup snapshot
```

---

## Troubleshooting

### Issue: Build Fails
**Solution**: Check Railway logs for errors
- Verify Dockerfile path
- Check requirements.txt dependencies
- Ensure Python version compatibility

### Issue: Database Connection Failed
**Solution**:
- Verify MongoDB Atlas IP whitelist includes `0.0.0.0/0`
- Check connection string format
- Test connection string locally first

### Issue: CORS Errors
**Solution**:
- Add frontend domain to `ALLOWED_ORIGINS`
- Redeploy backend
- Clear browser cache

### Issue: WebSocket Not Connecting
**Solution**:
- Ensure WSS protocol (not WS) for HTTPS sites
- Check Railway WebSocket support (enabled by default)
- Verify firewall rules

---

## Security Checklist

- [ ] Use strong MongoDB password
- [ ] Enable MongoDB Atlas IP whitelist
- [ ] Store API keys in Railway environment variables (never in code)
- [ ] Enable HTTPS for custom domains
- [ ] Restrict CORS to specific domains
- [ ] Enable MongoDB Atlas encryption at rest
- [ ] Set up Railway access controls
- [ ] Regular security updates for dependencies

---

## Next Steps After Deployment

1. **Set up CI/CD**: Configure automatic deployments on git push
2. **Monitoring**: Integrate with Sentry or LogRocket
3. **Analytics**: Add Google Analytics or Mixpanel
4. **Performance**: Enable CDN for static assets
5. **Backups**: Schedule regular MongoDB backups
6. **Documentation**: Update API documentation
7. **Testing**: Set up automated E2E tests

---

## Support Resources

- Railway Docs: https://docs.railway.app
- MongoDB Atlas Docs: https://docs.atlas.mongodb.com
- Flutter Web Deployment: https://docs.flutter.dev/deployment/web
- FastAPI Deployment: https://fastapi.tiangolo.com/deployment/

---

## Deployment Checklist Summary

**Pre-Deployment:**
- [ ] Code committed and pushed to GitHub
- [ ] MongoDB Atlas cluster created
- [ ] LlamaParse API key obtained
- [ ] Railway account created

**Backend Deployment:**
- [ ] Railway project created
- [ ] Backend service configured (root: `/backend`)
- [ ] Environment variables set
- [ ] Backend deployed and health check passing
- [ ] Backend URL documented

**Frontend Deployment:**
- [ ] Flutter web built with correct API URLs
- [ ] Frontend service created on Railway
- [ ] Dockerfile for frontend created
- [ ] Frontend deployed successfully
- [ ] Frontend URL documented

**Post-Deployment:**
- [ ] Custom domains configured (optional)
- [ ] CORS settings updated
- [ ] End-to-end testing completed
- [ ] Monitoring set up
- [ ] Documentation updated

---

**Deployment Date**: _____________
**Backend URL**: _____________
**Frontend URL**: _____________
**Deployed By**: _____________

---

*This deployment plan is for DocExtract v2.0. For issues or questions, refer to the project documentation or contact the development team.*
