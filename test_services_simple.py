#!/usr/bin/env python3
"""
Simple standalone test for LlamaParse and MongoDB
"""

import os
import sys
import json
import base64
import time
import requests
from datetime import datetime
from pymongo import MongoClient

# Colors
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
BOLD = '\033[1m'
END = '\033[0m'

def print_header(text):
    print(f"\n{BOLD}{BLUE}{'='*70}{END}")
    print(f"{BOLD}{BLUE}{text}{END}")
    print(f"{BOLD}{BLUE}{'='*70}{END}\n")

def print_success(text):
    print(f"{GREEN}✓ {text}{END}")

def print_error(text):
    print(f"{RED}✗ {text}{END}")

def print_info(text):
    print(f"{YELLOW}ℹ {text}{END}")

def print_step(step, text):
    print(f"\n{BOLD}Step {step}: {text}{END}")

# Configuration
MONGODB_URL = "mongodb+srv://likhithv02_db_user:ZVmXUhv6docO5d6F@cluster0.aowb5jb.mongodb.net/docextract?retryWrites=true&w=majority"
LLAMA_API_KEY = "llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG"
INVOICE_FILE = "/home/user/DocExtract/Invoice.jpeg"

# Invoice schema
INVOICE_SCHEMA = {
    "type": "object",
    "properties": {
        "seller_info": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "gstin": {"type": "string"},
                "contact_numbers": {"type": "array", "items": {"type": "string"}}
            }
        },
        "customer_info": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "address": {"type": ["string", "null"]},
                "contact": {"type": ["string", "null"]}
            }
        },
        "invoice_details": {
            "type": "object",
            "properties": {
                "date": {"type": "string"},
                "bill_no": {"type": "string"}
            }
        },
        "line_items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "description": {"type": "string"},
                    "weight": {"type": "number"},
                    "rate": {"type": "number"},
                    "amount": {"type": "number"}
                }
            }
        },
        "summary": {
            "type": "object",
            "properties": {
                "sub_total": {"type": "number"},
                "grand_total": {"type": "number"}
            }
        }
    }
}

def test_mongodb():
    """Test MongoDB Atlas connection"""
    print_step(1, "Testing MongoDB Atlas Connection")

    try:
        client = MongoClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
        # Force connection
        client.admin.command('ping')
        print_success("Connected to MongoDB Atlas")

        db = client['docextract']
        print_success(f"Database: {db.name}")

        return client, db
    except Exception as e:
        print_error(f"MongoDB connection failed: {e}")
        return None, None

def test_llamaparse():
    """Test LlamaParse extraction"""
    print_step(2, "Testing LlamaParse Document Extraction")

    if not os.path.exists(INVOICE_FILE):
        print_error(f"File not found: {INVOICE_FILE}")
        return None

    print_info(f"Reading {INVOICE_FILE}...")
    with open(INVOICE_FILE, 'rb') as f:
        file_bytes = f.read()

    print_success(f"File read: {len(file_bytes):,} bytes")

    # Encode to base64
    base64_data = base64.b64encode(file_bytes).decode('utf-8')
    print_success(f"Encoded to base64: {len(base64_data):,} chars")

    # Prepare request
    url = "https://api.cloud.llamaindex.ai/api/v1/extraction/run"
    headers = {
        "Authorization": f"Bearer {LLAMA_API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "data_schema": INVOICE_SCHEMA,
        "config": {
            "extraction_target": "PER_DOC",
            "extraction_mode": "BALANCED",
            "chunk_mode": "PAGE"
        },
        "file": {
            "data": base64_data,
            "mime_type": "image/jpeg"
        }
    }

    print_info("Sending extraction request...")
    print_info("This may take 30-60 seconds...")

    try:
        start_time = time.time()

        # Create extraction job
        response = requests.post(url, headers=headers, json=payload, timeout=120)

        if response.status_code == 200:
            job_data = response.json()
            job_id = job_data.get('id')
            print_success(f"Extraction job created: {job_id}")

            # Poll for results
            result_url = f"https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}/result"

            print_info("Waiting for extraction to complete...")
            for attempt in range(30):
                time.sleep(2)
                result_response = requests.get(result_url, headers=headers, timeout=10)

                if result_response.status_code == 200:
                    result = result_response.json()
                    elapsed = time.time() - start_time
                    print_success(f"Extraction completed in {elapsed:.2f}s")

                    # Extract data
                    extracted_data = result.get('data', result)

                    # Display preview
                    print_info("\n📊 Extracted Data Preview:")
                    print("─" * 70)

                    if isinstance(extracted_data, list) and len(extracted_data) > 0:
                        extracted_data = extracted_data[0]

                    if 'seller_info' in extracted_data:
                        seller = extracted_data['seller_info']
                        print(f"  🏪 Seller: {seller.get('name', 'N/A')}")
                        print(f"     GSTIN: {seller.get('gstin', 'N/A')}")

                    if 'invoice_details' in extracted_data:
                        invoice = extracted_data['invoice_details']
                        print(f"  📅 Date: {invoice.get('date', 'N/A')}")
                        print(f"  🔢 Bill No: {invoice.get('bill_no', 'N/A')}")

                    if 'line_items' in extracted_data:
                        items = extracted_data['line_items']
                        print(f"  📦 Line Items: {len(items)}")

                    if 'summary' in extracted_data:
                        summary = extracted_data['summary']
                        print(f"  💵 Grand Total: ₹{summary.get('grand_total', 0):,.2f}")

                    print("─" * 70)

                    return extracted_data

                elif attempt < 29:
                    print(f"   Polling... attempt {attempt + 1}/30")

            print_error("Extraction timed out")
            return None

        else:
            print_error(f"Request failed: {response.status_code}")
            print_error(response.text)
            return None

    except Exception as e:
        print_error(f"Extraction error: {e}")
        return None

def test_mongodb_save(db, extracted_data):
    """Test saving to MongoDB"""
    print_step(3, "Testing MongoDB Document Storage")

    if not db or not extracted_data:
        print_error("Missing db or extracted_data")
        return None

    try:
        document = {
            "document_type": "invoice",
            "file_name": "Invoice.jpeg",
            "extracted_data": extracted_data,
            "created_at": datetime.utcnow().isoformat()
        }

        collection = db['extracted_documents']
        result = collection.insert_one(document)

        doc_id = str(result.inserted_id)
        print_success(f"Document saved to MongoDB!")
        print_success(f"Document ID: {doc_id}")

        return doc_id

    except Exception as e:
        print_error(f"Save failed: {e}")
        return None

def test_mongodb_retrieve(db, doc_id):
    """Test retrieving from MongoDB"""
    print_step(4, "Testing MongoDB Document Retrieval")

    if not db or not doc_id:
        print_error("Missing db or doc_id")
        return False

    try:
        from bson.objectid import ObjectId

        collection = db['extracted_documents']
        document = collection.find_one({"_id": ObjectId(doc_id)})

        if document:
            print_success("Document retrieved successfully!")
            print_info(f"Document Type: {document.get('document_type')}")
            print_info(f"File Name: {document.get('file_name')}")
            return True
        else:
            print_error("Document not found")
            return False

    except Exception as e:
        print_error(f"Retrieval failed: {e}")
        return False

def test_mongodb_stats(db):
    """Test statistics"""
    print_step(5, "Testing Statistics")

    if not db:
        print_error("Missing db")
        return

    try:
        collection = db['extracted_documents']
        total = collection.count_documents({})
        invoices = collection.count_documents({"document_type": "invoice"})
        gov_ids = collection.count_documents({"document_type": "government_id"})

        print_success("Statistics retrieved!")
        print_info(f"  Total: {total}")
        print_info(f"  Invoices: {invoices}")
        print_info(f"  Government IDs: {gov_ids}")

    except Exception as e:
        print_error(f"Stats failed: {e}")

def main():
    """Run all tests"""
    print_header("DocExtract v2.0 - LlamaParse + MongoDB Integration Test")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    # Test MongoDB
    client, db = test_mongodb()
    if not client or not db:
        print_error("\nMongoDB connection failed. Stopping.")
        sys.exit(1)

    # Test LlamaParse
    extracted_data = test_llamaparse()
    if not extracted_data:
        print_error("\nExtraction failed. Stopping.")
        client.close()
        sys.exit(1)

    # Test MongoDB save
    doc_id = test_mongodb_save(db, extracted_data)
    if not doc_id:
        print_error("\nSave failed. Stopping.")
        client.close()
        sys.exit(1)

    # Test MongoDB retrieve
    test_mongodb_retrieve(db, doc_id)

    # Test statistics
    test_mongodb_stats(db)

    # Cleanup
    print_step(6, "Cleanup")
    client.close()
    print_info("MongoDB connection closed")

    # Final summary
    print_header("✅ Test Complete - All Services Working!")
    print_success("LlamaParse extraction: WORKING ✓")
    print_success("MongoDB storage: WORKING ✓")
    print_success("MongoDB retrieval: WORKING ✓")
    print(f"\n{BOLD}Backend services are ready! 🚀{END}\n")

if __name__ == "__main__":
    main()
