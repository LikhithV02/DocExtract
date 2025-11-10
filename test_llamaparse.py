#!/usr/bin/env python3
"""
Test script for LlamaParse API extraction
Usage: python3 test_llamaparse.py [path_to_test_file.pdf]
"""

import os
import sys
import json
import requests

# API Configuration
API_KEY = os.getenv('LLAMA_CLOUD_API_KEY', 'YOUR_API_KEY_HERE')
API_URL = 'https://api.cloud.llamaindex.ai/api/v1/extraction/run'

# Simple test schema for invoices
data_schema = {
    "type": "object",
    "additionalProperties": False,
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

config = {
    "priority": None,
    "extraction_target": "PER_DOC",
    "extraction_mode": "BALANCED",
    "parse_model": None,
    "extract_model": None,
    "multimodal_fast_mode": False,
    "system_prompt": None,
    "use_reasoning": False,
    "cite_sources": False,
    "confidence_scores": False,
    "chunk_mode": "PAGE",
    "high_resolution_mode": False,
    "invalidate_cache": False,
    "num_pages_context": None,
    "page_range": None
}

def test_api_endpoint():
    """Test if the API endpoint is reachable"""
    print("🧪 Testing LlamaParse API")
    print("=" * 50)
    print(f"API URL: {API_URL}")
    print(f"API Key: {API_KEY[:10]}...")
    print()

    headers = {
        'Authorization': f'Bearer {API_KEY}'
    }

    # Test endpoint availability
    try:
        response = requests.get(API_URL, headers=headers, timeout=10)
        print(f"✅ Endpoint is reachable!")
        print(f"Status Code: {response.status_code}")

        if response.status_code == 405:
            print("   (405 = Method Not Allowed - expected, endpoint requires POST)")
        elif response.status_code == 401:
            print("   ❌ Authentication failed - check your API key")
        elif response.status_code == 403:
            print("   ❌ Forbidden - check your API key permissions")

        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Error connecting to API: {e}")
        return False

def test_extraction(file_path):
    """Test actual document extraction"""
    print("\n📤 Testing document extraction...")
    print(f"File: {file_path}")
    print()

    if not os.path.exists(file_path):
        print(f"❌ Error: File not found: {file_path}")
        return

    headers = {
        'Authorization': f'Bearer {API_KEY}'
    }

    files = {
        'file': open(file_path, 'rb')
    }

    data = {
        'data_schema': json.dumps(data_schema),
        'config': json.dumps(config)
    }

    try:
        response = requests.post(
            API_URL,
            headers=headers,
            files=files,
            data=data,
            timeout=60
        )

        print(f"Status Code: {response.status_code}")
        print()

        if response.status_code == 200:
            print("✅ SUCCESS! Extraction completed")
            print("\nExtracted Data:")
            print(json.dumps(response.json(), indent=2))
        else:
            print("❌ Request failed")
            print("\nResponse:")
            try:
                print(json.dumps(response.json(), indent=2))
            except:
                print(response.text)

    except requests.exceptions.RequestException as e:
        print(f"❌ Error during extraction: {e}")
    finally:
        files['file'].close()

if __name__ == "__main__":
    # Check API endpoint
    if not test_api_endpoint():
        sys.exit(1)

    # If file provided, test extraction
    if len(sys.argv) > 1:
        test_file = sys.argv[1]
        test_extraction(test_file)
    else:
        print("\n💡 To test with a file, run:")
        print(f"   python3 test_llamaparse.py /path/to/invoice.pdf")

    print("\n" + "=" * 50)
