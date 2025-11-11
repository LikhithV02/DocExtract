"""
LlamaParse service using LlamaCloud API
"""
import base64
import logging
from typing import Dict, Any, Optional
import asyncio

from llama_cloud_services import LlamaExtract
from llama_cloud import ExtractConfig

from ..config import settings

logger = logging.getLogger(__name__)

# LlamaParse configuration
LLAMAPARSE_CONFIG = {
    "extraction_target": "PER_DOC",
    "extraction_mode": "BALANCED",
    "chunk_mode": "PAGE",
    "multimodal_fast_mode": False,
    "use_reasoning": False,
    "cite_sources": False,
    "confidence_scores": False,
    "high_resolution_mode": False,
}


class LlamaParseService:
    """Service for document extraction using LlamaParse official SDK"""

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize LlamaParse service

        Args:
            api_key: LlamaCloud API key (defaults to settings)
        """
        self.api_key = api_key or settings.llama_cloud_api_key
        # Note: LlamaExtract will use LLAMA_CLOUD_API_KEY environment variable
        self.extractor = LlamaExtract()

    def _get_mime_type(self, file_name: str) -> str:
        """
        Determine MIME type from file extension

        Args:
            file_name: Name of the file

        Returns:
            MIME type string
        """
        ext = file_name.lower().split(".")[-1]
        mime_types = {
            "pdf": "application/pdf",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
        }
        return mime_types.get(ext, "application/octet-stream")

    async def extract_document(
        self,
        file_bytes: bytes,
        file_name: str,
        document_type: str,
        data_schema: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Extract data from document using LlamaParse

        Args:
            file_bytes: Raw file bytes
            file_name: Name of the file
            document_type: 'government_id' or 'invoice'
            data_schema: JSON schema for extraction

        Returns:
            Extracted data matching the schema

        Raises:
            Exception: If extraction fails
        """
        try:
            logger.info(f"Starting extraction for {file_name} (type: {document_type})")

            # Create temp file for LlamaExtract
            import tempfile
            import os

            # Create a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file_name)[1]) as tmp_file:
                tmp_file.write(file_bytes)
                tmp_file_path = tmp_file.name

            try:
                # Create extraction config
                config = ExtractConfig(**LLAMAPARSE_CONFIG)

                # Extract data using SDK
                result = self.extractor.extract(data_schema, config, tmp_file_path)

                logger.info(f"Extraction completed successfully for {file_name}")

                # Return the extracted data
                return result.data if hasattr(result, 'data') else result

            finally:
                # Clean up temporary file
                if os.path.exists(tmp_file_path):
                    os.unlink(tmp_file_path)

        except Exception as e:
            logger.error(f"LlamaParse extraction failed for {file_name}: {str(e)}")
            raise Exception(f"LlamaParse extraction failed: {str(e)}")


# Global LlamaParse service instance
llamaparse_service = LlamaParseService()
