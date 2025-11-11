"""
Statistics API endpoints
"""
from fastapi import APIRouter, HTTPException, status
import logging

from ..models.document import StatsResponse
from ..services.database import db_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/stats", tags=["statistics"])


@router.get("", response_model=StatsResponse)
async def get_stats():
    """
    Get document statistics

    Returns:
        StatsResponse with document counts by type

    Raises:
        HTTPException: If stats retrieval fails
    """
    try:
        stats = await db_service.get_stats()

        return StatsResponse(
            total=stats["total"],
            government_id=stats["government_id"],
            invoice=stats["invoice"],
        )

    except Exception as e:
        logger.error(f"Error getting stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get statistics: {str(e)}",
        )
