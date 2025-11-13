#!/bin/bash
# Railway deployment helper script for DocExtract

set -e

echo "=‚ Railway Deployment Helper for DocExtract"
echo "==========================================="
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "L Railway CLI not found!"
    echo "Install it with: npm install -g @railway/cli"
    echo "Or visit: https://docs.railway.app/develop/cli"
    exit 1
fi

echo " Railway CLI found"
echo ""

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "= Not logged in to Railway. Running 'railway login'..."
    railway login
fi

echo " Logged in to Railway"
echo ""

# Check if project is linked
if [ ! -f ".railway/config.json" ]; then
    echo "   Project not linked to Railway"
    echo "1. Create a new project: railway init"
    echo "2. Link existing project: railway link"
    read -p "Do you want to create a new project? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        railway init
    else
        railway link
    fi
fi

echo " Project linked"
echo ""

# Show current environment
echo "=Ë Current Railway Environment:"
railway status
echo ""

# Environment variables check
echo "=' Required Environment Variables:"
echo ""
echo "Backend (docextract-backend):"
echo "  - MONGODB_URL: Your MongoDB Atlas connection string"
echo "  - LLAMA_CLOUD_API_KEY: Your LlamaParse API key"
echo "  - ALLOWED_ORIGINS: Frontend URL (e.g., https://your-frontend.railway.app)"
echo ""
echo "Frontend (docextract-frontend):"
echo "  - VITE_API_BASE_URL: Backend URL (e.g., https://your-backend.railway.app/api/v1)"
echo "  - VITE_WS_URL: Backend WebSocket URL (e.g., wss://your-backend.railway.app/ws)"
echo ""

read -p "Have you set all environment variables in Railway dashboard? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   Please set environment variables in Railway dashboard first:"
    echo "   https://railway.app/dashboard"
    exit 1
fi

echo " Environment variables confirmed"
echo ""

# Deploy
echo "=€ Deploying to Railway..."
railway up

echo ""
echo " Deployment initiated!"
echo ""
echo "=Ê Monitor deployment:"
echo "   railway logs"
echo ""
echo "< Open in browser:"
echo "   railway open"
echo ""
echo "<‰ Deployment complete!"
