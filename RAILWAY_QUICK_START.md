# Railway Deployment - Quick Start Guide

## 🚀 Deploy DocExtract to Railway in 15 Minutes

This guide gets you up and running quickly. For detailed explanations, see [RAILWAY_DEPLOYMENT_PLAN.md](./RAILWAY_DEPLOYMENT_PLAN.md).

---

## Step 1: Prerequisites (5 minutes)

### 1.1 Create Accounts
- [ ] [Railway](https://railway.app) - Sign up with GitHub
- [ ] [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) - Free tier
- [ ] [LlamaParse](https://cloud.llamaindex.ai) - Get API key

### 1.2 Prepare Repository
```bash
# Ensure code is pushed to GitHub
git add .
git commit -m "Prepare for Railway deployment"
git push origin claude/railway-deployment-plan-011CV2JmozcwAoCFbEfHnn2j
```

---

## Step 2: MongoDB Atlas Setup (3 minutes)

### 2.1 Create Database
1. Go to MongoDB Atlas → **Create New Cluster** (FREE M0)
2. **Database Access** → Add user:
   - Username: `docextract_user`
   - Password: (generate strong password - save it!)
3. **Network Access** → Add IP: `0.0.0.0/0` (allow from anywhere)

### 2.2 Get Connection String
1. Click **Connect** → **Connect your application**
2. Copy connection string:
   ```
   mongodb+srv://docextract_user:<password>@cluster.xxxxx.mongodb.net/
   ```
3. Replace `<password>` and add database name:
   ```
   mongodb+srv://docextract_user:YOUR_PASSWORD@cluster.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
   ```
4. **Save this string** - you'll need it in Step 3!

---

## Step 3: Deploy Backend to Railway (5 minutes)

### 3.1 Create Project
1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. **New Project** → **Deploy from GitHub repo**
3. Select your `DocExtract` repository
4. Select branch: `claude/railway-deployment-plan-011CV2JmozcwAoCFbEfHnn2j`

### 3.2 Configure Backend Service
1. **Service Name**: Change to `docextract-backend`
2. **Settings** → **Root Directory**: `/backend` ⚠️ **CRITICAL!**
3. Railway will auto-detect Dockerfile

### 3.3 Set Environment Variables
Click **Variables** tab and add these:

```env
MONGODB_URL=mongodb+srv://docextract_user:YOUR_PASSWORD@cluster.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
MONGODB_DB_NAME=docextract
LLAMA_CLOUD_API_KEY=llx-your-api-key-here
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=*
LOG_LEVEL=info
```

### 3.4 Deploy & Get URL
1. Railway will automatically deploy
2. Go to **Settings** → **Public Networking** → **Generate Domain**
3. **Copy your backend URL**: `https://docextract-backend-production.up.railway.app`

### 3.5 Verify Backend
```bash
curl https://your-backend-url.up.railway.app/health
# Should return: {"status":"healthy","database":"connected"}
```

---

## Step 4: Deploy Frontend to Railway (5 minutes)

### 4.1 Create Frontend Service
1. Same Railway project → **+ New Service**
2. **Deploy from GitHub repo** (same repo)
3. **Service Name**: `docextract-frontend`

### 4.2 Configure Frontend
1. **Settings** → **Root Directory**: `/` (leave as root)
2. **Settings** → **Dockerfile Path**: `Dockerfile`

### 4.3 Set Build Arguments
Click **Variables** tab:

```env
API_BASE_URL=https://your-backend-url.up.railway.app
WS_URL=wss://your-backend-url.up.railway.app/ws/documents
```

Replace `your-backend-url` with your actual backend URL from Step 3.4!

### 4.4 Deploy Frontend
1. Railway will build Flutter web app (takes ~5 minutes)
2. **Settings** → **Public Networking** → **Generate Domain**
3. **Copy your frontend URL**: `https://docextract-frontend-production.up.railway.app`

---

## Step 5: Update CORS (2 minutes)

### 5.1 Add Frontend to CORS
1. Go to backend service → **Variables**
2. Update `ALLOWED_ORIGINS`:
   ```
   ALLOWED_ORIGINS=https://your-frontend-url.up.railway.app
   ```
3. Backend will auto-redeploy

---

## Step 6: Test Your App! 🎉

### 6.1 Open Frontend
Visit your frontend URL: `https://your-frontend-url.up.railway.app`

### 6.2 Test Features
- [ ] Upload a document (Government ID or Invoice)
- [ ] Check extraction results
- [ ] Verify real-time updates (WebSocket)
- [ ] Test document listing
- [ ] Try document deletion

### 6.3 Check Logs
If something fails:
1. Railway → Backend Service → **Deployments** → View logs
2. MongoDB Atlas → **Metrics** → Check connections

---

## Troubleshooting

### ❌ Backend Health Check Fails
**Problem**: `/health` returns error or "database disconnected"

**Solution**:
1. Check MongoDB Atlas connection string format
2. Verify MongoDB Atlas IP whitelist: `0.0.0.0/0`
3. Check database username/password
4. View Railway logs for specific error

### ❌ Frontend Shows "API Connection Error"
**Problem**: Frontend can't reach backend

**Solution**:
1. Verify `API_BASE_URL` in frontend variables is correct
2. Check CORS settings in backend variables
3. Ensure backend URL is HTTPS (not HTTP)
4. Check browser console for specific errors

### ❌ WebSocket Not Connecting
**Problem**: Real-time updates don't work

**Solution**:
1. Verify `WS_URL` uses `wss://` (not `ws://`)
2. Check Railway WebSocket support (enabled by default)
3. Test WebSocket separately: `wscat -c wss://your-backend-url/ws/documents`

### ❌ Document Upload Fails
**Problem**: "LlamaParse error" or extraction fails

**Solution**:
1. Verify `LLAMA_CLOUD_API_KEY` is correct
2. Check LlamaParse quota at https://cloud.llamaindex.ai
3. View backend logs for specific error
4. Test with a simple document first

### ❌ Build Fails
**Problem**: Railway build fails during deployment

**Solution**:
- **Backend**: Check `requirements.txt` for incompatible versions
- **Frontend**: Ensure Flutter SDK version in Dockerfile exists
- View build logs in Railway → Deployments
- Check Dockerfile syntax

---

## Cost Summary

### Free Tier (Great for Testing!)
- **Railway**: $5 free credit/month (~500 hours)
- **MongoDB Atlas**: Free M0 cluster (512MB)
- **LlamaParse**: Free tier (check limits)
- **Total**: $0/month for development! 🎉

### Production
- **Railway Hobby**: $5-10/month
- **MongoDB Atlas M10**: $9/month (or stay on free tier)
- **LlamaParse**: Variable (check pricing)
- **Total**: ~$15-20/month

---

## Next Steps

### Improve Your Deployment
- [ ] Add custom domain (Railway Settings → Domains)
- [ ] Set up automatic deployments on git push
- [ ] Enable Railway monitoring & alerts
- [ ] Configure MongoDB Atlas backups
- [ ] Add application monitoring (Sentry, LogRocket)

### Production Hardening
- [ ] Restrict CORS to specific domains (remove `*`)
- [ ] Add rate limiting to API
- [ ] Enable MongoDB Atlas encryption
- [ ] Set up CI/CD pipeline
- [ ] Add automated tests
- [ ] Create staging environment

---

## Important URLs

After deployment, save these:

```
Backend URL:  https://___________________________.up.railway.app
Frontend URL: https://___________________________.up.railway.app
MongoDB URL:  mongodb+srv://___________________________
API Docs:     https://your-backend-url.up.railway.app/api/v1/docs
```

---

## Support

- **Railway Issues**: [Railway Discord](https://discord.gg/railway)
- **MongoDB Help**: [MongoDB Community](https://www.mongodb.com/community/forums)
- **DocExtract Docs**: See [README.md](./README.md)
- **Detailed Guide**: See [RAILWAY_DEPLOYMENT_PLAN.md](./RAILWAY_DEPLOYMENT_PLAN.md)

---

## Success Checklist ✅

After completing this guide, you should have:
- [x] Backend deployed on Railway
- [x] Frontend deployed on Railway
- [x] MongoDB Atlas database connected
- [x] LlamaParse integration working
- [x] WebSocket real-time updates functional
- [x] Document upload/extraction working
- [x] CORS configured correctly
- [x] Health checks passing
- [x] Application accessible via HTTPS

**Congratulations! Your DocExtract app is now live! 🚀**

---

*Deployment time: ~15 minutes | Difficulty: Easy | Cost: Free (with free tiers)*
