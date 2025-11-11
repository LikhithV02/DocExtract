# Railway Deployment Guide

## Prerequisites

1. Railway account (https://railway.app)
2. LlamaCloud API key
3. MongoDB Atlas connection string

## Environment Variables

Set these in your Railway project settings:

```
LLAMA_CLOUD_API_KEY=your_llamacloud_api_key
MONGODB_URL=your_mongodb_atlas_connection_string
MONGODB_DB_NAME=docextract
HOST=0.0.0.0
```

**Note:** Do NOT set the `PORT` variable - Railway automatically provides this.

## Deployment Steps

### Option 1: Deploy from GitHub (Recommended)

1. Push your code to GitHub
2. Go to Railway dashboard
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Railway will auto-detect the Dockerfile
6. Set the root directory to `/backend` in Railway settings
7. Add the environment variables listed above
8. Deploy!

### Option 2: Deploy with Railway CLI

1. Install Railway CLI:
   ```bash
   npm i -g @railway/cli
   ```

2. Login to Railway:
   ```bash
   railway login
   ```

3. Initialize project:
   ```bash
   cd backend
   railway init
   ```

4. Add environment variables:
   ```bash
   railway variables set LLAMA_CLOUD_API_KEY=your_key
   railway variables set MONGODB_URL=your_mongodb_url
   railway variables set MONGODB_DB_NAME=docextract
   railway variables set HOST=0.0.0.0
   ```

5. Deploy:
   ```bash
   railway up
   ```

## Post-Deployment

1. Railway will provide a public URL (e.g., `https://your-app.railway.app`)
2. Test the health endpoint: `https://your-app.railway.app/health`
3. Update your Flutter app's `API_BASE_URL` to point to this URL
4. Update CORS settings in `backend/app/config.py` if needed for production

## Troubleshooting

### Port Binding Issues
- Railway automatically sets the `PORT` environment variable
- The Dockerfile is configured to use `${PORT:-8000}` (Railway's port or default to 8000)
- Do NOT manually set the PORT variable in Railway

### Health Check Failures
- Ensure MongoDB connection string is correct
- Check that LLAMA_CLOUD_API_KEY is set
- View logs in Railway dashboard for detailed errors

### CORS Issues
- Update `allowed_origins` in `backend/app/config.py` to include your Flutter web app URL
- For development, you can use `["*"]` but restrict this in production

## Production Considerations

1. **CORS**: Update `allowed_origins` in config.py to specific domains
2. **MongoDB**: Use MongoDB Atlas for production database
3. **Secrets**: Never commit `.env` file - use Railway's environment variables
4. **Monitoring**: Enable Railway's built-in monitoring and logs
5. **Scaling**: Consider Railway's auto-scaling options for high traffic

## Useful Commands

```bash
# View logs
railway logs

# Open project in browser
railway open

# Run commands in Railway environment
railway run python -m app.main

# Link to existing project
railway link
```
