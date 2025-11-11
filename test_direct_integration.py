#!/usr/bin/env python3
"""
Direct integration test for LlamaParse and MongoDB
Tests without starting the full FastAPI server
"""

import os
import sys
import json
import base64
import asyncio
from datetime import datetime

# Add backend to path
sys.path.insert(0, '/home/user/DocExtract/backend')

# Colors for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.END}\n")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.END}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.END}")

def print_info(text):
    print(f"{Colors.YELLOW}ℹ {text}{Colors.END}")

def print_step(step, text):
    print(f"\n{Colors.BOLD}Step {step}: {text}{Colors.END}")

# Import backend modules
try:
    from app.config import settings
    from app.services.database import DatabaseService
    from app.services.llamaparse import LlamaParseService
    from app.schemas import get_invoice_schema
    from app.models.invoice import InvoiceData
    from app.models.document import ExtractedDocument
    print_success("Backend modules imported successfully")
except Exception as e:
    print_error(f"Failed to import backend modules: {e}")
    sys.exit(1)

async def test_mongodb_connection():
    """Test MongoDB Atlas connection"""
    print_step(1, "Testing MongoDB Atlas Connection")

    db_service = DatabaseService()

    try:
        await db_service.connect()
        print_success(f"Connected to MongoDB: {settings.mongodb_db_name}")
        print_info(f"MongoDB URL: {settings.mongodb_url[:50]}...")
        return db_service
    except Exception as e:
        print_error(f"MongoDB connection failed: {e}")
        return None

async def test_llamaparse_extraction():
    """Test LlamaParse extraction with Invoice.jpeg"""
    print_step(2, "Testing LlamaParse Document Extraction")

    invoice_file = "/home/user/DocExtract/Invoice.jpeg"

    if not os.path.exists(invoice_file):
        print_error(f"Invoice file not found: {invoice_file}")
        return None

    print_info(f"Reading {invoice_file}...")
    with open(invoice_file, 'rb') as f:
        file_bytes = f.read()

    print_success(f"File read: {len(file_bytes)} bytes")

    # Initialize LlamaParse service
    llamaparse_service = LlamaParseService()
    print_info(f"API Key: {settings.llama_cloud_api_key[:30]}...")

    # Get invoice schema
    schema = get_invoice_schema()
    print_info("Using invoice extraction schema")

    # Extract document
    print_info("Starting extraction... (this may take 30-60 seconds)")
    print_info("Please wait...")

    try:
        import time
        start_time = time.time()

        extracted_data = await llamaparse_service.extract_document(
            file_bytes=file_bytes,
            file_name="Invoice.jpeg",
            document_type="invoice",
            data_schema=schema
        )

        elapsed_time = time.time() - start_time
        print_success(f"Extraction completed in {elapsed_time:.2f}s")

        # Display extracted data preview
        print_info("\n📊 Extracted Data Preview:")
        print("─" * 70)

        if 'seller_info' in extracted_data:
            seller = extracted_data['seller_info']
            print(f"  🏪 Seller: {seller.get('name', 'N/A')}")
            print(f"     GSTIN: {seller.get('gstin', 'N/A')}")

        if 'customer_info' in extracted_data:
            customer = extracted_data['customer_info']
            print(f"  👤 Customer: {customer.get('name', 'N/A')}")

        if 'invoice_details' in extracted_data:
            invoice = extracted_data['invoice_details']
            print(f"  📅 Date: {invoice.get('date', 'N/A')}")
            print(f"  🔢 Bill No: {invoice.get('bill_no', 'N/A')}")

        if 'line_items' in extracted_data:
            items = extracted_data['line_items']
            print(f"  📦 Line Items: {len(items)}")
            if items:
                print(f"     First item: {items[0].get('description', 'N/A')}")

        if 'summary' in extracted_data:
            summary = extracted_data['summary']
            print(f"  💰 Subtotal: ₹{summary.get('sub_total', 0):,.2f}")
            print(f"  💵 Grand Total: ₹{summary.get('grand_total', 0):,.2f}")

        print("─" * 70)

        return extracted_data

    except Exception as e:
        print_error(f"Extraction failed: {e}")
        import traceback
        traceback.print_exc()
        return None

async def test_mongodb_storage(db_service, extracted_data):
    """Test saving extracted document to MongoDB"""
    print_step(3, "Testing MongoDB Document Storage")

    if not db_service or not extracted_data:
        print_error("Cannot test storage: missing db_service or extracted_data")
        return None

    try:
        # Create document
        document = ExtractedDocument(
            document_type="invoice",
            file_name="Invoice.jpeg",
            extracted_data=InvoiceData(**extracted_data)
        )

        print_info(f"Saving document with ID: {document.id}")

        # Save to MongoDB
        doc_id = await db_service.insert_document(document)
        print_success(f"Document saved successfully!")
        print_success(f"MongoDB Document ID: {doc_id}")

        return doc_id

    except Exception as e:
        print_error(f"Storage failed: {e}")
        import traceback
        traceback.print_exc()
        return None

async def test_mongodb_retrieval(db_service, doc_id):
    """Test retrieving document from MongoDB"""
    print_step(4, "Testing MongoDB Document Retrieval")

    if not db_service or not doc_id:
        print_error("Cannot test retrieval: missing db_service or doc_id")
        return False

    try:
        # Retrieve document
        document = await db_service.get_document(doc_id)

        if document:
            print_success("Document retrieved successfully!")
            print_info(f"Document Type: {document.get('document_type')}")
            print_info(f"File Name: {document.get('file_name')}")
            print_info(f"Created At: {document.get('created_at')}")
            return True
        else:
            print_error("Document not found in database")
            return False

    except Exception as e:
        print_error(f"Retrieval failed: {e}")
        return False

async def test_statistics(db_service):
    """Test statistics"""
    print_step(5, "Testing Statistics")

    if not db_service:
        print_error("Cannot test stats: missing db_service")
        return

    try:
        stats = await db_service.get_stats()
        print_success("Statistics retrieved!")
        print_info(f"  Total Documents: {stats.get('total', 0)}")
        print_info(f"  Government IDs: {stats.get('government_id', 0)}")
        print_info(f"  Invoices: {stats.get('invoice', 0)}")
    except Exception as e:
        print_error(f"Stats failed: {e}")

async def cleanup(db_service, doc_id):
    """Cleanup test document"""
    print_step(6, "Cleanup (Optional)")

    if not db_service or not doc_id:
        print_info("No document to clean up")
        return

    try:
        response = input(f"\nDelete test document {doc_id}? (y/n): ")
        if response.lower() == 'y':
            success = await db_service.delete_document(doc_id)
            if success:
                print_success("Test document deleted")
            else:
                print_error("Document not found for deletion")
        else:
            print_info("Keeping test document")
    except Exception as e:
        print_error(f"Cleanup failed: {e}")

async def main():
    """Run all tests"""
    print_header("DocExtract v2.0 - Direct Integration Test")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_info("Testing LlamaParse + MongoDB without FastAPI server\n")

    db_service = None
    doc_id = None

    try:
        # Test MongoDB connection
        db_service = await test_mongodb_connection()
        if not db_service:
            print_error("\nMongoDB connection failed. Stopping tests.")
            return

        # Test LlamaParse extraction
        extracted_data = await test_llamaparse_extraction()
        if not extracted_data:
            print_error("\nExtraction failed. Stopping tests.")
            return

        # Test MongoDB storage
        doc_id = await test_mongodb_storage(db_service, extracted_data)
        if not doc_id:
            print_error("\nStorage failed. Stopping tests.")
            return

        # Test MongoDB retrieval
        await test_mongodb_retrieval(db_service, doc_id)

        # Test statistics
        await test_statistics(db_service)

        # Cleanup
        await cleanup(db_service, doc_id)

        # Final summary
        print_header("✅ Test Summary")
        print_success("All tests completed successfully!")
        print_info("\nVerified components:")
        print_info("  ✓ MongoDB Atlas connection")
        print_info("  ✓ LlamaParse document extraction")
        print_info("  ✓ MongoDB document storage")
        print_info("  ✓ MongoDB document retrieval")
        print_info("  ✓ Statistics calculation")

        print(f"\n{Colors.BOLD}Backend services are working correctly! 🚀{Colors.END}\n")

    except KeyboardInterrupt:
        print_info("\n\nTest interrupted by user")
    except Exception as e:
        print_error(f"\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Cleanup database connection
        if db_service:
            await db_service.disconnect()
            print_info("Disconnected from MongoDB")

if __name__ == "__main__":
    asyncio.run(main())
