#!/bin/bash

# DocExtract Deployment Script
# This script deploys the backend and optionally the Flutter web app

set -e  # Exit on error

echo "========================================="
echo "DocExtract v2.0 Deployment Script"
echo "========================================="
echo ""

# Configuration
BACKEND_DIR="backend"
FLUTTER_DIR="."
WEB_DEPLOY_DIR="/var/www/docextract/web"
BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some operations may require sudo."
fi

# Step 1: Pull latest code
print_info "Pulling latest code from Git..."
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH

# Step 2: Deploy Backend
print_info "Deploying backend..."
cd $BACKEND_DIR

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found in backend directory!"
    print_info "Please create .env file from .env.example and configure it."
    exit 1
fi

# Stop existing containers
print_info "Stopping existing containers..."
docker-compose down

# Build and start new containers
print_info "Building and starting containers..."
docker-compose up -d --build

# Wait for services to be healthy
print_info "Waiting for services to be healthy..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_info "Backend services started successfully!"
else
    print_error "Backend services failed to start!"
    docker-compose logs
    exit 1
fi

cd ..

# Step 3: Deploy Flutter Web (Optional)
read -p "Do you want to deploy Flutter web app? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Building Flutter web app..."

    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed!"
        exit 1
    fi

    # Clean and build
    flutter clean
    flutter pub get
    flutter build web --release

    # Deploy to web server
    print_info "Deploying web app to $WEB_DEPLOY_DIR..."
    sudo rm -rf $WEB_DEPLOY_DIR
    sudo mkdir -p $WEB_DEPLOY_DIR
    sudo cp -r build/web/* $WEB_DEPLOY_DIR/

    # Set proper permissions
    sudo chown -R www-data:www-data $WEB_DEPLOY_DIR
    sudo chmod -R 755 $WEB_DEPLOY_DIR

    print_info "Flutter web app deployed successfully!"
fi

# Step 4: Restart Nginx
read -p "Do you want to restart Nginx? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Restarting Nginx..."
    sudo systemctl restart nginx

    if sudo systemctl is-active --quiet nginx; then
        print_info "Nginx restarted successfully!"
    else
        print_error "Nginx failed to restart!"
        sudo systemctl status nginx
        exit 1
    fi
fi

# Step 5: Check deployment
print_info "Checking deployment..."
echo ""
print_info "Backend API: http://localhost:8000"
print_info "Backend Health: http://localhost:8000/health"
print_info "API Docs: http://localhost:8000/docs"
echo ""

# Test health endpoint
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    print_info "✓ Backend is healthy!"
else
    print_warning "Backend health check failed. Check logs with: docker-compose -f backend/docker-compose.yml logs"
fi

echo ""
echo "========================================="
print_info "Deployment complete!"
echo "========================================="
echo ""
print_info "Next steps:"
echo "  1. Check backend logs: cd backend && docker-compose logs -f"
echo "  2. Test API: curl http://localhost:8000/health"
echo "  3. Visit API docs: http://your-domain.com/docs"
echo ""
