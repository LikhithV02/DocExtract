#!/bin/sh

# Startup script for Railway deployment
# Railway provides PORT environment variable automatically

# Use Railway's PORT if provided, otherwise default to 8000
PORT=${PORT:-8000}

echo "Starting server on port $PORT"

# Start uvicorn
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
