"""
API route handlers
"""
from .extraction import router as extraction_router
from .documents import router as documents_router
from .stats import router as stats_router

__all__ = ["extraction_router", "documents_router", "stats_router"]
