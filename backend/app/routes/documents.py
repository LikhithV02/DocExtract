"""
Document CRUD API endpoints
"""
from fastapi import APIRouter, HTTPException, status, WebSocket, WebSocketDisconnect
from typing import Optional
import logging

from ..models.document import (
    ExtractedDocument,
    DocumentCreate,
    DocumentResponse,
    DocumentListResponse,
)
from ..services.database import db_service
from ..services.websocket_manager import ws_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/documents", tags=["documents"])


@router.post("", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def create_document(document: DocumentCreate):
    """
    Create a new document in the database

    Args:
        document: DocumentCreate with document data

    Returns:
        DocumentResponse with created document

    Raises:
        HTTPException: If creation fails
    """
    try:
        # Create ExtractedDocument instance
        extracted_doc = ExtractedDocument(
            document_type=document.document_type,
            file_name=document.file_name,
            extracted_data=document.extracted_data,
        )

        # Insert into database
        doc_id = await db_service.insert_document(extracted_doc)

        # Broadcast INSERT event to WebSocket clients
        await ws_manager.broadcast(
            event_type="INSERT",
            data=extracted_doc.model_dump(mode="json"),
        )

        logger.info(f"Created document: {doc_id}")

        # Return response
        return DocumentResponse(
            id=extracted_doc.id,
            document_type=extracted_doc.document_type,
            file_name=extracted_doc.file_name,
            extracted_data=extracted_doc.extracted_data,  # Already a dict
            created_at=extracted_doc.created_at.isoformat(),
        )

    except Exception as e:
        logger.error(f"Error creating document: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create document: {str(e)}",
        )


@router.get("", response_model=DocumentListResponse)
async def list_documents(
    document_type: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
):
    """
    List documents with optional filtering

    Args:
        document_type: Filter by document type (optional)
        limit: Maximum number of documents (default 100)
        offset: Number of documents to skip (default 0)

    Returns:
        DocumentListResponse with list of documents and total count
    """
    try:
        # Get documents
        documents = await db_service.get_documents(
            document_type=document_type,
            limit=limit,
            offset=offset,
        )

        # Get total count
        total = await db_service.count_documents(document_type=document_type)

        # Convert to response models
        doc_responses = [
            DocumentResponse(
                id=doc["id"],
                document_type=doc["document_type"],
                file_name=doc["file_name"],
                extracted_data=doc["extracted_data"],
                created_at=doc["created_at"],
            )
            for doc in documents
        ]

        return DocumentListResponse(documents=doc_responses, total=total)

    except Exception as e:
        logger.error(f"Error listing documents: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list documents: {str(e)}",
        )


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(document_id: str):
    """
    Get a document by ID

    Args:
        document_id: Document ID

    Returns:
        DocumentResponse with document data

    Raises:
        HTTPException: If document not found
    """
    try:
        document = await db_service.get_document(document_id)

        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Document not found: {document_id}",
            )

        return DocumentResponse(
            id=document["id"],
            document_type=document["document_type"],
            file_name=document["file_name"],
            extracted_data=document["extracted_data"],
            created_at=document["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting document: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get document: {str(e)}",
        )


@router.delete("/{document_id}")
async def delete_document(document_id: str):
    """
    Delete a document by ID

    Args:
        document_id: Document ID

    Returns:
        Success message

    Raises:
        HTTPException: If document not found
    """
    try:
        # Get document before deleting for WebSocket broadcast
        document = await db_service.get_document(document_id)

        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Document not found: {document_id}",
            )

        # Delete document
        deleted = await db_service.delete_document(document_id)

        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Document not found: {document_id}",
            )

        # Broadcast DELETE event to WebSocket clients
        await ws_manager.broadcast(
            event_type="DELETE",
            data={"id": document_id},
        )

        logger.info(f"Deleted document: {document_id}")

        return {"success": True, "message": f"Document {document_id} deleted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting document: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete document: {str(e)}",
        )


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time document updates

    Args:
        websocket: WebSocket connection
    """
    await ws_manager.connect(websocket)

    try:
        while True:
            # Keep connection alive and receive messages (if needed)
            data = await websocket.receive_text()
            # Echo back for now (can be used for client-side events)
            await ws_manager.send_personal_message(f"Received: {data}", websocket)

    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
        logger.info("WebSocket client disconnected")
