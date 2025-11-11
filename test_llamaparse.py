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
        'Authorization': f'Bearer {API_KEY}',
        'Content-Type': 'application/json'
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
            return False
        elif response.status_code == 403:
            print("   ❌ Forbidden - check your API key permissions")
            return False

        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Error connecting to API: {e}")
        return False

def test_extraction(file_path):
    """Test actual document extraction"""
    import base64

    print("\n📤 Testing document extraction...")
    print(f"File: {file_path}")
    print()

    if not os.path.exists(file_path):
        print(f"❌ Error: File not found: {file_path}")
        return

    # Read file and encode as base64
    with open(file_path, 'rb') as f:
        file_data = base64.b64encode(f.read()).decode('utf-8')

    # Determine MIME type
    mime_type = 'image/jpeg' if file_path.lower().endswith(('.jpg', '.jpeg')) else 'application/pdf'

    headers = {
        'Authorization': f'Bearer {API_KEY}',
        'Content-Type': 'application/json'
    }

    payload = {
        'data_schema': data_schema,
        'config': config,
        'file': {
            'data': file_data,
            'mime_type': mime_type
        }
    }

    try:
        response = requests.post(
            API_URL,
            headers=headers,
            json=payload,
            timeout=120
        )

        print(f"Status Code: {response.status_code}")
        print()

        if response.status_code == 200:
            job_data = response.json()
            job_id = job_data.get('id')
            print(f"✅ Extraction job submitted successfully!")
            print(f"Job ID: {job_id}")
            print(f"Status: {job_data.get('status')}")

            # Poll for results
            print("\n⏳ Waiting for extraction to complete...")
            import time
            for attempt in range(30):  # Try for up to 60 seconds
                time.sleep(2)
                result_url = f'https://api.cloud.llamaindex.ai/api/v1/extraction/jobs/{job_id}/result'
                result_response = requests.get(result_url, headers=headers, timeout=10)

                if result_response.status_code == 200:
                    result = result_response.json()
                    print("\n✅ SUCCESS! Extraction completed")
                    print("\n" + "=" * 60)
                    print("EXTRACTED DATA:")
                    print("=" * 60)
                    print(json.dumps(result.get('data', result), indent=2))
                    break
                elif attempt < 29:
                    print(f"   Attempt {attempt + 1}: Still processing...")
            else:
                print("\n⏱️ Timeout waiting for extraction to complete")
        else:
            print("❌ Request failed")
            print("\nResponse:")
            try:
                print(json.dumps(response.json(), indent=2))
            except:
                print(response.text)

    except requests.exceptions.RequestException as e:
        print(f"❌ Error during extraction: {e}")

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
