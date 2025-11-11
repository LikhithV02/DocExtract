"""
DocExtract FastAPI Backend Application
Main application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from .config import settings
from .routes import extraction_router, documents_router, stats_router
from .services.database import db_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager
    Handles startup and shutdown events
    """
    # Startup
    logger.info("Starting DocExtract Backend...")

    # Connect to MongoDB
    await db_service.connect()

    logger.info("DocExtract Backend started successfully")

    yield

    # Shutdown
    logger.info("Shutting down DocExtract Backend...")

    # Disconnect from MongoDB
    await db_service.disconnect()

    logger.info("DocExtract Backend shut down successfully")


# Create FastAPI app
app = FastAPI(
    title="DocExtract API",
    description="Document extraction and management API using LlamaParse and MongoDB",
    version="2.0.0",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(extraction_router, prefix=settings.api_v1_prefix)
app.include_router(documents_router, prefix=settings.api_v1_prefix)
app.include_router(stats_router, prefix=settings.api_v1_prefix)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "DocExtract API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "connected" if db_service.db else "disconnected",
    }


# WebSocket endpoint (mounted separately)
from .routes.documents import websocket_endpoint

app.websocket("/ws/documents")(websocket_endpoint)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=True,
    )
