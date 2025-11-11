#!/usr/bin/env python3
import requests
import json

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'

headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

# Try to list extractions or get extraction results
endpoints_to_try = [
    f'{BASE_URL}/extraction/jobs',
    f'{BASE_URL}/extraction',
    f'{BASE_URL}/extractions',
]

for endpoint in endpoints_to_try:
    print(f"Trying GET {endpoint}")
    try:
        response = requests.get(endpoint, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(json.dumps(result, indent=2)[:1000])  # First 1000 chars
            print("...")
            break
    except Exception as e:
        print(f"Error: {e}")
    print()
