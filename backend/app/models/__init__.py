"""
Pydantic models for MongoDB documents
"""
from .government_id import GovernmentIdData
from .invoice import InvoiceData
from .document import ExtractedDocument

__all__ = ["GovernmentIdData", "InvoiceData", "ExtractedDocument"]
