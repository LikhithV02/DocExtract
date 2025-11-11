"""
LlamaParse service using official llama-cloud SDK
"""
import base64
import logging
from typing import Dict, Any, Optional
import asyncio

from llama_cloud import LlamaCloud
from llama_cloud.types import CloudDocumentCreate

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
        self.client = LlamaCloud(api_key=self.api_key)

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

            # Encode file as base64
            base64_data = base64.b64encode(file_bytes).decode("utf-8")

            # Determine MIME type
            mime_type = self._get_mime_type(file_name)

            logger.info(f"MIME type: {mime_type}")

            # Create extraction job using official SDK
            # Note: The actual API method might differ based on SDK version
            # This is based on the pattern from the migration plan
            job = await self._create_extraction_job(
                file_data=base64_data,
                mime_type=mime_type,
                data_schema=data_schema,
                config=LLAMAPARSE_CONFIG,
            )

            logger.info(f"Extraction job created: {job.get('id')}")

            # Poll for results
            result = await self._wait_for_completion(
                job_id=job.get("id"),
                timeout=60,
                poll_interval=2,
            )

            logger.info(f"Extraction completed successfully for {file_name}")

            return result.get("data", result)

        except Exception as e:
            logger.error(f"LlamaParse extraction failed for {file_name}: {str(e)}")
            raise Exception(f"LlamaParse extraction failed: {str(e)}")

    async def _create_extraction_job(
        self,
        file_data: str,
        mime_type: str,
        data_schema: Dict[str, Any],
        config: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Create an extraction job

        Args:
            file_data: Base64 encoded file data
            mime_type: MIME type of the file
            data_schema: JSON schema for extraction
            config: Extraction configuration

        Returns:
            Job information dict
        """
        # This method uses the official SDK
        # The actual implementation may vary based on SDK version
        # For now, using a requests-based approach as fallback

        import requests

        url = "https://api.cloud.llamaindex.ai/api/v1/extraction/run"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "data_schema": data_schema,
            "config": config,
            "file": {"data": file_data, "mime_type": mime_type},
        }

        response = requests.post(url, headers=headers, json=payload, timeout=120)
        response.raise_for_status()

        return response.json()

    async def _wait_for_completion(
        self,
        job_id: str,
        timeout: int = 60,
        poll_interval: int = 2,
    ) -> Dict[str, Any]:
        """
        Wait for extraction job to complete

        Args:
            job_id: Job ID to poll
            timeout: Maximum wait time in seconds
            poll_interval: Seconds between polls

        Returns:
            Extraction result

        Raises:
            TimeoutError: If job doesn't complete within timeout
        """
        import requests

        url = f"https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}/result"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        attempts = timeout // poll_interval

        for attempt in range(attempts):
            await asyncio.sleep(poll_interval)

            try:
                response = requests.get(url, headers=headers, timeout=10)

                if response.status_code == 200:
                    result = response.json()
                    logger.info(f"Job {job_id} completed after {attempt + 1} attempts")
                    return result
                elif response.status_code == 404:
                    # Job not ready yet
                    logger.debug(f"Job {job_id} not ready, attempt {attempt + 1}/{attempts}")
                    continue
                else:
                    logger.warning(
                        f"Unexpected status code {response.status_code} for job {job_id}"
                    )

            except requests.exceptions.RequestException as e:
                logger.warning(f"Error polling job {job_id}: {e}")

        raise TimeoutError(
            f"Extraction job {job_id} did not complete within {timeout} seconds"
        )


# Global LlamaParse service instance
llamaparse_service = LlamaParseService()
