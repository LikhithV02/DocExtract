"""
Validation utility functions
"""
from typing import Literal


def validate_document_type(document_type: str) -> bool:
    """
    Validate if document type is supported

    Args:
        document_type: Document type to validate

    Returns:
        True if valid, False otherwise
    """
    valid_types = ["government_id", "invoice"]
    return document_type in valid_types
