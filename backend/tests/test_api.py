"""
Basic API endpoint tests for DocExtract backend
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test root endpoint returns API info"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "DocExtract API"
    assert data["version"] == "2.0.0"
    assert data["status"] == "running"


def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "healthy"


def test_docs_available():
    """Test that API documentation is available"""
    response = client.get("/docs")
    assert response.status_code == 200


def test_stats_endpoint():
    """Test stats endpoint returns correct structure"""
    response = client.get("/api/v1/stats")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "government_id" in data
    assert "invoice" in data


def test_extract_endpoint_invalid_type():
    """Test extraction endpoint with invalid document type"""
    payload = {
        "file_data": "dGVzdA==",  # base64 "test"
        "file_name": "test.pdf",
        "document_type": "invalid_type",
    }
    response = client.post("/api/v1/extract", json=payload)
    assert response.status_code == 400


def test_extract_endpoint_invalid_base64():
    """Test extraction endpoint with invalid base64"""
    payload = {
        "file_data": "not_valid_base64!@#",
        "file_name": "test.pdf",
        "document_type": "invoice",
    }
    response = client.post("/api/v1/extract", json=payload)
    assert response.status_code == 400


def test_documents_list_endpoint():
    """Test documents list endpoint"""
    response = client.get("/api/v1/documents")
    assert response.status_code == 200
    data = response.json()
    assert "documents" in data
    assert "total" in data
    assert isinstance(data["documents"], list)
    assert isinstance(data["total"], int)


def test_document_get_nonexistent():
    """Test getting a nonexistent document"""
    response = client.get("/api/v1/documents/nonexistent-id")
    assert response.status_code == 404


def test_document_delete_nonexistent():
    """Test deleting a nonexistent document"""
    response = client.delete("/api/v1/documents/nonexistent-id")
    assert response.status_code == 404


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
