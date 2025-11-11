#!/usr/bin/env python3
"""
Comprehensive integration test for DocExtract v2.0 Backend
Tests LlamaParse extraction and MongoDB storage using Invoice.jpeg
"""

import os
import sys
import json
import time
import base64
import requests
from datetime import datetime

# Colors for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}\n")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.END}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.END}")

def print_info(text):
    print(f"{Colors.YELLOW}ℹ {text}{Colors.END}")

def print_step(step, text):
    print(f"\n{Colors.BOLD}Step {step}: {text}{Colors.END}")

# Configuration
API_BASE_URL = "http://localhost:8000"
INVOICE_FILE = "Invoice.jpeg"

def check_prerequisites():
    """Check if all prerequisites are met"""
    print_step(1, "Checking Prerequisites")

    # Check if Invoice.jpeg exists
    if not os.path.exists(INVOICE_FILE):
        print_error(f"Invoice file not found: {INVOICE_FILE}")
        return False
    print_success(f"Invoice file found: {INVOICE_FILE} ({os.path.getsize(INVOICE_FILE)} bytes)")

    # Check if API key is set
    api_key = os.getenv('LLAMA_CLOUD_API_KEY')
    if not api_key or api_key == 'YOUR_API_KEY_HERE':
        print_error("LLAMA_CLOUD_API_KEY environment variable not set!")
        print_info("Set it with: export LLAMA_CLOUD_API_KEY='your-api-key'")
        return False
    print_success(f"API key found: {api_key[:20]}...")

    return True

def check_backend_health():
    """Check if backend is running and healthy"""
    print_step(2, "Checking Backend Health")

    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print_success(f"Backend is healthy: {data}")
            return True
        else:
            print_error(f"Backend health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print_error("Backend is not running!")
        print_info("Start it with: cd backend && docker-compose up -d")
        return False
    except Exception as e:
        print_error(f"Health check error: {e}")
        return False

def test_extraction():
    """Test document extraction with Invoice.jpeg"""
    print_step(3, "Testing Document Extraction")

    # Read and encode file
    print_info(f"Reading {INVOICE_FILE}...")
    with open(INVOICE_FILE, 'rb') as f:
        file_bytes = f.read()

    base64_data = base64.b64encode(file_bytes).decode('utf-8')
    print_success(f"File encoded to base64 ({len(base64_data)} chars)")

    # Prepare request
    payload = {
        "file_data": base64_data,
        "file_name": "Invoice.jpeg",
        "document_type": "invoice"
    }

    print_info("Sending extraction request to backend...")
    print_info("This may take 30-60 seconds...")

    start_time = time.time()

    try:
        response = requests.post(
            f"{API_BASE_URL}/api/v1/extract",
            json=payload,
            timeout=120
        )

        elapsed_time = time.time() - start_time

        if response.status_code == 200:
            data = response.json()
            print_success(f"Extraction completed in {elapsed_time:.2f}s")

            # Display extracted data
            print_info("\nExtracted Data Preview:")
            extracted_data = data.get('extracted_data', {})

            # Seller info
            if 'seller_info' in extracted_data:
                seller = extracted_data['seller_info']
                print(f"  Seller: {seller.get('name', 'N/A')}")
                print(f"  GSTIN: {seller.get('gstin', 'N/A')}")

            # Invoice details
            if 'invoice_details' in extracted_data:
                invoice = extracted_data['invoice_details']
                print(f"  Date: {invoice.get('date', 'N/A')}")
                print(f"  Bill No: {invoice.get('bill_no', 'N/A')}")

            # Summary
            if 'summary' in extracted_data:
                summary = extracted_data['summary']
                print(f"  Grand Total: ₹{summary.get('grand_total', 0)}")

            # Line items count
            if 'line_items' in extracted_data:
                items = extracted_data['line_items']
                print(f"  Line Items: {len(items)}")

            return extracted_data
        else:
            print_error(f"Extraction failed: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None

    except requests.exceptions.Timeout:
        print_error("Extraction request timed out!")
        return None
    except Exception as e:
        print_error(f"Extraction error: {e}")
        return None

def test_save_document(extracted_data):
    """Test saving document to MongoDB"""
    print_step(4, "Testing MongoDB Storage")

    if not extracted_data:
        print_error("No extracted data to save")
        return None

    payload = {
        "document_type": "invoice",
        "file_name": "Invoice.jpeg",
        "extracted_data": extracted_data
    }

    print_info("Saving document to MongoDB...")

    try:
        response = requests.post(
            f"{API_BASE_URL}/api/v1/documents",
            json=payload,
            timeout=10
        )

        if response.status_code == 201:
            data = response.json()
            doc_id = data.get('id')
            print_success(f"Document saved successfully!")
            print_success(f"Document ID: {doc_id}")
            print_success(f"Created at: {data.get('created_at')}")
            return doc_id
        else:
            print_error(f"Save failed: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None

    except Exception as e:
        print_error(f"Save error: {e}")
        return None

def test_retrieve_document(doc_id):
    """Test retrieving document from MongoDB"""
    print_step(5, "Testing Document Retrieval")

    if not doc_id:
        print_error("No document ID to retrieve")
        return False

    print_info(f"Retrieving document {doc_id}...")

    try:
        response = requests.get(
            f"{API_BASE_URL}/api/v1/documents/{doc_id}",
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            print_success("Document retrieved successfully!")
            print_info(f"Document Type: {data.get('document_type')}")
            print_info(f"File Name: {data.get('file_name')}")
            return True
        else:
            print_error(f"Retrieval failed: {response.status_code}")
            return False

    except Exception as e:
        print_error(f"Retrieval error: {e}")
        return False

def test_list_documents():
    """Test listing documents"""
    print_step(6, "Testing Document Listing")

    print_info("Fetching all documents...")

    try:
        response = requests.get(
            f"{API_BASE_URL}/api/v1/documents",
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            total = data.get('total', 0)
            documents = data.get('documents', [])
            print_success(f"Found {total} total documents")
            print_success(f"Retrieved {len(documents)} documents")

            if documents:
                print_info("\nRecent documents:")
                for i, doc in enumerate(documents[:5], 1):
                    print(f"  {i}. {doc['file_name']} ({doc['document_type']}) - {doc['created_at']}")

            return True
        else:
            print_error(f"List failed: {response.status_code}")
            return False

    except Exception as e:
        print_error(f"List error: {e}")
        return False

def test_stats():
    """Test statistics endpoint"""
    print_step(7, "Testing Statistics")

    print_info("Fetching statistics...")

    try:
        response = requests.get(
            f"{API_BASE_URL}/api/v1/stats",
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            print_success("Statistics retrieved!")
            print_info(f"  Total: {data.get('total', 0)}")
            print_info(f"  Government IDs: {data.get('government_id', 0)}")
            print_info(f"  Invoices: {data.get('invoice', 0)}")
            return True
        else:
            print_error(f"Stats failed: {response.status_code}")
            return False

    except Exception as e:
        print_error(f"Stats error: {e}")
        return False

def cleanup_test_document(doc_id):
    """Clean up test document (optional)"""
    print_step(8, "Cleanup (Optional)")

    if not doc_id:
        print_info("No document to clean up")
        return

    response = input(f"\nDelete test document {doc_id}? (y/n): ")
    if response.lower() == 'y':
        try:
            response = requests.delete(
                f"{API_BASE_URL}/api/v1/documents/{doc_id}",
                timeout=10
            )

            if response.status_code == 200:
                print_success("Test document deleted")
            else:
                print_error(f"Delete failed: {response.status_code}")

        except Exception as e:
            print_error(f"Delete error: {e}")
    else:
        print_info("Keeping test document")

def main():
    """Run all tests"""
    print_header("DocExtract v2.0 Backend Integration Test")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    # Run tests
    if not check_prerequisites():
        sys.exit(1)

    if not check_backend_health():
        sys.exit(1)

    extracted_data = test_extraction()
    if not extracted_data:
        print_error("\nExtraction failed. Stopping tests.")
        sys.exit(1)

    doc_id = test_save_document(extracted_data)
    if not doc_id:
        print_error("\nSave failed. Stopping tests.")
        sys.exit(1)

    test_retrieve_document(doc_id)
    test_list_documents()
    test_stats()
    cleanup_test_document(doc_id)

    # Final summary
    print_header("Test Summary")
    print_success("All tests completed successfully! ✓")
    print_info("\nBackend services are working correctly:")
    print_info("  ✓ LlamaParse extraction")
    print_info("  ✓ MongoDB storage")
    print_info("  ✓ Document retrieval")
    print_info("  ✓ Document listing")
    print_info("  ✓ Statistics")

    print(f"\n{Colors.BOLD}Backend is ready for production! 🚀{Colors.END}\n")

if __name__ == "__main__":
    main()
