"""
Document extraction API endpoints
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
import base64
import logging

from ..services.llamaparse import llamaparse_service
from ..schemas import get_government_id_schema, get_invoice_schema

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/extract", tags=["extraction"])


class ExtractionRequest(BaseModel):
    """Request model for document extraction"""

    file_data: str  # Base64 encoded file
    file_name: str
    document_type: str  # "government_id" or "invoice"


class ExtractionResponse(BaseModel):
    """Response model for extraction"""

    extracted_data: dict
    file_name: str


@router.post("", response_model=ExtractionResponse)
async def extract_document(request: ExtractionRequest):
    """
    Extract data from a document using LlamaParse

    Args:
        request: ExtractionRequest with file data and metadata

    Returns:
        ExtractionResponse with extracted data

    Raises:
        HTTPException: If extraction fails or invalid document type
    """
    try:
        # Validate document type
        if request.document_type not in ["government_id", "invoice"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid document type: {request.document_type}. Must be 'government_id' or 'invoice'",
            )

        # Get the appropriate schema
        if request.document_type == "government_id":
            schema = get_government_id_schema()
        else:
            schema = get_invoice_schema()

        # Decode base64 file data
        try:
            file_bytes = base64.b64decode(request.file_data)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid base64 file data: {str(e)}",
            )

        # Extract document using LlamaParse
        extracted_data = await llamaparse_service.extract_document(
            file_bytes=file_bytes,
            file_name=request.file_name,
            document_type=request.document_type,
            data_schema=schema,
        )

        logger.info(f"Successfully extracted {request.document_type} from {request.file_name}")

        return ExtractionResponse(
            extracted_data=extracted_data,
            file_name=request.file_name,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Extraction error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Extraction failed: {str(e)}",
        )
