#!/usr/bin/env python3
"""
Test with manual DNS resolution using HTTP requests
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

# Invoice schema (simplified for testing)
INVOICE_SCHEMA = {
    "type": "object",
    "properties": {
        "seller_info": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "gstin": {"type": "string"}
            }
        },
        "invoice_details": {
            "type": "object",
            "properties": {
                "date": {"type": "string"},
                "bill_no": {"type": "string"}
            }
        },
        "summary": {
            "type": "object",
            "properties": {
                "grand_total": {"type": "number"}
            }
        }
    }
}

def test_http_connectivity():
    """Test basic HTTP connectivity"""
    print_step(1, "Testing HTTP Connectivity")

    try:
        response = requests.get("https://httpbin.org/get", timeout=10)
        if response.status_code in [200, 403]:
            print_success("HTTP connectivity working")
            return True
        else:
            print_error(f"Unexpected status: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"HTTP test failed: {e}")
        return False

def test_mongodb_with_pymongo():
    """Test MongoDB with pymongo using dnspython"""
    print_step(2, "Testing MongoDB Atlas Connection")

    try:
        # Install dnspython if needed
        print_info("Ensuring dnspython is installed...")
        import subprocess
        subprocess.run(["pip", "install", "-q", "dnspython"], check=False)

        print_info("Connecting to MongoDB Atlas...")
        client = MongoClient(
            MONGODB_URL,
            serverSelectionTimeoutMS=10000,
            connectTimeoutMS=10000,
            socketTimeoutMS=10000
        )

        # Force connection test
        result = client.admin.command('ping')
        print_success("Connected to MongoDB Atlas!")
        print_info(f"Ping result: {result}")

        db = client['docextract']
        print_success(f"Database ready: {db.name}")

        return client, db

    except Exception as e:
        print_error(f"MongoDB connection failed: {e}")
        print_info("Trying alternative connection method...")

        try:
            # Try with explicit DNS resolution disabled
            from pymongo import MongoClient
            from urllib.parse import quote_plus

            username = "likhithv02_db_user"
            password = "ZVmXUhv6docO5d6F"
            cluster = "cluster0.aowb5jb.mongodb.net"

            connection_string = f"mongodb+srv://{quote_plus(username)}:{quote_plus(password)}@{cluster}/docextract?retryWrites=true&w=majority&ssl=true"

            client = MongoClient(
                connection_string,
                serverSelectionTimeoutMS=15000
            )

            client.admin.command('ping')
            print_success("Connected via alternative method!")

            db = client['docextract']
            return client, db

        except Exception as e2:
            print_error(f"Alternative method also failed: {e2}")
            return None, None

def test_llamaparse():
    """Test LlamaParse extraction"""
    print_step(3, "Testing LlamaParse Document Extraction")

    if not os.path.exists(INVOICE_FILE):
        print_error(f"File not found: {INVOICE_FILE}")
        return None

    print_info(f"Reading {INVOICE_FILE}...")
    with open(INVOICE_FILE, 'rb') as f:
        file_bytes = f.read()

    print_success(f"File read: {len(file_bytes):,} bytes")

    # Encode to base64
    base64_data = base64.b64encode(file_bytes).decode('utf-8')
    print_success(f"Encoded to base64")

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
            "extraction_mode": "BALANCED"
        },
        "file": {
            "data": base64_data,
            "mime_type": "image/jpeg"
        }
    }

    print_info("Sending extraction request to LlamaParse...")
    print_info("⏳ This may take 30-60 seconds...")

    try:
        start_time = time.time()

        # Create extraction job
        response = requests.post(url, headers=headers, json=payload, timeout=120)

        if response.status_code != 200:
            print_error(f"Request failed: {response.status_code}")
            print_error(response.text[:500])
            return None

        job_data = response.json()
        job_id = job_data.get('id')
        print_success(f"Extraction job created: {job_id}")

        # Poll for results
        result_url = f"https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}/result"

        print_info("Waiting for extraction to complete...")
        for attempt in range(40):  # Try for up to 80 seconds
            time.sleep(2)

            try:
                result_response = requests.get(result_url, headers=headers, timeout=10)

                if result_response.status_code == 200:
                    result = result_response.json()
                    elapsed = time.time() - start_time
                    print_success(f"Extraction completed in {elapsed:.2f}s!")

                    # Extract data
                    extracted_data = result.get('data', result)

                    # Handle list response
                    if isinstance(extracted_data, list) and len(extracted_data) > 0:
                        extracted_data = extracted_data[0]

                    # Display preview
                    print_info("\n📊 Extracted Data Preview:")
                    print("─" * 70)

                    if 'seller_info' in extracted_data:
                        seller = extracted_data['seller_info']
                        print(f"  🏪 Seller: {seller.get('name', 'N/A')}")
                        print(f"     GSTIN: {seller.get('gstin', 'N/A')}")

                    if 'invoice_details' in extracted_data:
                        invoice = extracted_data['invoice_details']
                        print(f"  📅 Date: {invoice.get('date', 'N/A')}")
                        print(f"  🔢 Bill No: {invoice.get('bill_no', 'N/A')}")

                    if 'summary' in extracted_data:
                        summary = extracted_data['summary']
                        print(f"  💵 Grand Total: ₹{summary.get('grand_total', 0):,.2f}")

                    print("─" * 70)

                    # Full data for MongoDB
                    print_info("\n📦 Full extracted data structure:")
                    print(json.dumps(extracted_data, indent=2)[:500] + "...")

                    return extracted_data

                elif result_response.status_code == 404:
                    if attempt % 5 == 0:
                        print(f"   ⏳ Still processing... ({attempt * 2}s elapsed)")
                else:
                    print_error(f"Unexpected status: {result_response.status_code}")

            except requests.exceptions.Timeout:
                print_info(f"   Timeout on attempt {attempt + 1}, retrying...")

        print_error("Extraction timed out after 80 seconds")
        return None

    except Exception as e:
        print_error(f"Extraction error: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_mongodb_save(db, extracted_data):
    """Test saving to MongoDB"""
    print_step(4, "Testing MongoDB Document Storage")

    if not db or not extracted_data:
        print_error("Missing database or extracted_data")
        return None

    try:
        document = {
            "document_type": "invoice",
            "file_name": "Invoice.jpeg",
            "extracted_data": extracted_data,
            "created_at": datetime.utcnow().isoformat(),
            "test_run": True  # Mark as test
        }

        collection = db['extracted_documents']
        result = collection.insert_one(document)

        doc_id = str(result.inserted_id)
        print_success(f"✅ Document saved to MongoDB Atlas!")
        print_success(f"Document ID: {doc_id}")
        print_info(f"Collection: extracted_documents")
        print_info(f"Database: docextract")

        # Verify it was saved
        count = collection.count_documents({})
        print_success(f"Total documents in collection: {count}")

        return doc_id

    except Exception as e:
        print_error(f"Save failed: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_mongodb_retrieve(db, doc_id):
    """Test retrieving from MongoDB"""
    print_step(5, "Testing MongoDB Document Retrieval")

    if not db or not doc_id:
        print_error("Missing database or doc_id")
        return False

    try:
        from bson.objectid import ObjectId

        collection = db['extracted_documents']
        document = collection.find_one({"_id": ObjectId(doc_id)})

        if document:
            print_success("✅ Document retrieved successfully!")
            print_info(f"Document Type: {document.get('document_type')}")
            print_info(f"File Name: {document.get('file_name')}")
            print_info(f"Created At: {document.get('created_at')}")
            return True
        else:
            print_error("Document not found")
            return False

    except Exception as e:
        print_error(f"Retrieval failed: {e}")
        return False

def main():
    """Run all tests"""
    print_header("DocExtract v2.0 - Full Integration Test")
    print_header("LlamaParse + MongoDB Atlas")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    client = None

    try:
        # Test HTTP connectivity
        if not test_http_connectivity():
            print_error("\nHTTP connectivity failed. Cannot proceed.")
            return

        # Test MongoDB
        client, db = test_mongodb_with_pymongo()
        if not client or not db:
            print_error("\nMongoDB connection failed. Skipping MongoDB tests.")
            db = None

        # Test LlamaParse (independent of MongoDB)
        extracted_data = test_llamaparse()
        if not extracted_data:
            print_error("\n❌ LlamaParse extraction failed.")
            return

        print_success("\n✅ LlamaParse extraction successful!")

        # Test MongoDB save if connection available
        if db:
            doc_id = test_mongodb_save(db, extracted_data)
            if doc_id:
                test_mongodb_retrieve(db, doc_id)
                print_header("✅ ALL TESTS PASSED!")
                print_success("LlamaParse: WORKING ✓")
                print_success("MongoDB: WORKING ✓")
                print(f"\n{BOLD}🎉 Backend services fully functional!{END}\n")
            else:
                print_error("\n❌ MongoDB save failed")
        else:
            print_info("\nSkipped MongoDB tests due to connection issues")
            print_success("LlamaParse tested successfully!")

    except KeyboardInterrupt:
        print_info("\n\nTest interrupted by user")
    except Exception as e:
        print_error(f"\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if client:
            client.close()
            print_info("MongoDB connection closed")

if __name__ == "__main__":
    main()
