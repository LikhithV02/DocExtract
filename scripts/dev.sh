#!/bin/bash
# Development startup script for DocExtract

set -e

echo "=€ Starting DocExtract Development Environment..."

# Check if .env exists in backend
if [ ! -f "backend/.env" ]; then
    echo "   Warning: backend/.env not found. Creating from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example backend/.env
        echo " Created backend/.env from .env.example"
        echo "   Please update backend/.env with your actual credentials"
    else
        echo "L Error: .env.example not found!"
        exit 1
    fi
fi

# Check if frontend/.env exists
if [ ! -f "frontend/.env" ]; then
    echo "   Warning: frontend/.env not found. Creating from .env.example..."
    if [ -f "frontend/.env.example" ]; then
        cp frontend/.env.example frontend/.env
        echo " Created frontend/.env"
    fi
fi

# Start backend in background
echo "=æ Starting Backend (FastAPI)..."
cd backend
python -m venv venv 2>/dev/null || true
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null || true
pip install -r requirements.txt > /dev/null
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
cd ..

echo " Backend started (PID: $BACKEND_PID)"

# Start frontend
echo "<¨ Starting Frontend (Vite)..."
cd frontend
npm install
npm run dev -- --host 0.0.0.0 --port 5173 &
FRONTEND_PID=$!
cd ..

echo " Frontend started (PID: $FRONTEND_PID)"
echo ""
echo "<‰ DocExtract Development Environment Ready!"
echo "   Backend:  http://localhost:8000"
echo "   API Docs: http://localhost:8000/docs"
echo "   Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop all services..."

# Wait for interrupt signal
trap "echo ''; echo '=Ñ Stopping services...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo ' All services stopped'; exit 0" INT

# Keep script running
wait
