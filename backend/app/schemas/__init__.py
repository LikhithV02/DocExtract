"""
LlamaParse extraction schemas for different document types
"""
from .government_id_schema import get_government_id_schema
from .invoice_schema import get_invoice_schema

__all__ = ["get_government_id_schema", "get_invoice_schema"]
