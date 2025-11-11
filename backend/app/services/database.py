"""
MongoDB database service for document operations
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from typing import List, Optional, Dict, Any
from datetime import datetime
import logging

from ..config import settings
from ..models.document import ExtractedDocument

logger = logging.getLogger(__name__)


class DatabaseService:
    """MongoDB database operations service"""

    def __init__(self):
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None
        self.collection_name = "extracted_documents"

    async def connect(self):
        """Connect to MongoDB"""
        try:
            self.client = AsyncIOMotorClient(settings.mongodb_url)
            self.db = self.client[settings.mongodb_db_name]

            # Create indexes
            await self._create_indexes()

            logger.info(f"Connected to MongoDB: {settings.mongodb_db_name}")
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise

    async def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
            logger.info("Disconnected from MongoDB")

    async def _create_indexes(self):
        """Create necessary indexes for the collection"""
        collection = self.db[self.collection_name]

        # Create indexes
        await collection.create_index("id", unique=True)
        await collection.create_index("document_type")
        await collection.create_index("created_at")

        logger.info("Database indexes created successfully")

    async def insert_document(self, document: ExtractedDocument) -> str:
        """
        Insert a new document into the database

        Args:
            document: ExtractedDocument to insert

        Returns:
            Document ID
        """
        collection = self.db[self.collection_name]

        doc_dict = document.model_dump()
        # Convert datetime to ISO format string for MongoDB
        doc_dict["created_at"] = document.created_at.isoformat()

        # Convert extracted_data to dict
        if hasattr(document.extracted_data, "model_dump"):
            doc_dict["extracted_data"] = document.extracted_data.model_dump()

        await collection.insert_one(doc_dict)
        logger.info(f"Inserted document: {document.id}")

        return document.id

    async def get_document(self, document_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a document by ID

        Args:
            document_id: Document ID

        Returns:
            Document dict or None if not found
        """
        collection = self.db[self.collection_name]
        document = await collection.find_one({"id": document_id}, {"_id": 0})

        return document

    async def get_documents(
        self,
        document_type: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """
        Get documents with optional filtering

        Args:
            document_type: Filter by document type (optional)
            limit: Maximum number of documents to return
            offset: Number of documents to skip

        Returns:
            List of document dicts
        """
        collection = self.db[self.collection_name]

        # Build query
        query = {}
        if document_type:
            query["document_type"] = document_type

        # Execute query
        cursor = (
            collection.find(query, {"_id": 0})
            .sort("created_at", -1)
            .skip(offset)
            .limit(limit)
        )

        documents = await cursor.to_list(length=limit)
        return documents

    async def delete_document(self, document_id: str) -> bool:
        """
        Delete a document by ID

        Args:
            document_id: Document ID

        Returns:
            True if deleted, False if not found
        """
        collection = self.db[self.collection_name]
        result = await collection.delete_one({"id": document_id})

        if result.deleted_count > 0:
            logger.info(f"Deleted document: {document_id}")
            return True

        logger.warning(f"Document not found for deletion: {document_id}")
        return False

    async def update_document(self, document: ExtractedDocument) -> bool:
        """
        Update an existing document

        Args:
            document: ExtractedDocument with updated data

        Returns:
            True if updated, False if not found
        """
        collection = self.db[self.collection_name]

        doc_dict = document.model_dump()
        doc_dict["created_at"] = document.created_at.isoformat()

        # Convert extracted_data to dict
        if hasattr(document.extracted_data, "model_dump"):
            doc_dict["extracted_data"] = document.extracted_data.model_dump()

        result = await collection.replace_one(
            {"id": document.id},
            doc_dict,
        )

        if result.modified_count > 0 or result.matched_count > 0:
            logger.info(f"Updated document: {document.id}")
            return True

        logger.warning(f"Document not found for update: {document.id}")
        return False

    async def get_stats(self) -> Dict[str, int]:
        """
        Get document statistics

        Returns:
            Dict with total, government_id, and invoice counts
        """
        collection = self.db[self.collection_name]

        # Get total count
        total = await collection.count_documents({})

        # Get counts by type
        pipeline = [
            {"$group": {"_id": "$document_type", "count": {"$sum": 1}}}
        ]

        results = await collection.aggregate(pipeline).to_list(None)

        # Build stats dict
        stats = {
            "total": total,
            "government_id": 0,
            "invoice": 0,
        }

        for result in results:
            doc_type = result["_id"]
            count = result["count"]
            if doc_type in stats:
                stats[doc_type] = count

        return stats

    async def count_documents(self, document_type: Optional[str] = None) -> int:
        """
        Count documents with optional filtering

        Args:
            document_type: Filter by document type (optional)

        Returns:
            Number of documents
        """
        collection = self.db[self.collection_name]

        query = {}
        if document_type:
            query["document_type"] = document_type

        count = await collection.count_documents(query)
        return count


# Global database service instance
db_service = DatabaseService()
