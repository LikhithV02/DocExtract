#!/bin/bash

# Deploy backend to Railway from backend directory
# This ensures Railway uses the correct Dockerfile and configuration

echo "Deploying DocExtract Backend to Railway..."

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found!"
    echo "Install it with: npm i -g @railway/cli"
    exit 1
fi

# Check if we're in the backend directory
if [ ! -f "railway.toml" ]; then
    echo "❌ Must run from backend directory!"
    echo "Run: cd backend && ./deploy-railway.sh"
    exit 1
fi

# Deploy
echo "🚀 Deploying to Railway..."
railway up

echo "✅ Deployment complete!"
echo "Check your Railway dashboard for logs and URL"
