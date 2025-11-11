"""
Main document model for MongoDB storage
"""
from pydantic import BaseModel, Field
from typing import Union, Literal
from datetime import datetime
from uuid import uuid4

from .government_id import GovernmentIdData
from .invoice import InvoiceData


class ExtractedDocument(BaseModel):
    """Main document model stored in MongoDB"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    document_type: Literal["government_id", "invoice"]
    file_name: str
    extracted_data: dict  # Accept any dict structure
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "document_type": "invoice",
                "file_name": "invoice_2024_001.pdf",
                "extracted_data": {},
                "created_at": "2024-01-15T10:30:00Z",
            }
        }


class DocumentCreate(BaseModel):
    """Request model for creating a document"""

    document_type: Literal["government_id", "invoice"]
    file_name: str
    extracted_data: dict  # Accept any dict structure from Flutter


class DocumentResponse(BaseModel):
    """Response model for document operations"""

    id: str
    document_type: str
    file_name: str
    extracted_data: dict
    created_at: str


class DocumentListResponse(BaseModel):
    """Response model for listing documents"""

    documents: list[DocumentResponse]
    total: int


class StatsResponse(BaseModel):
    """Response model for statistics"""

    total: int
    government_id: int
    invoice: int
