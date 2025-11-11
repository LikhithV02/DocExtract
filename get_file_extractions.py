#!/usr/bin/env python3
import requests
import json

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'

# File ID from the extraction job
file_id = '5eaf29de-8abb-4b96-902f-59ca04917b14'

headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

# Try to get extraction data via file endpoints
endpoints_to_try = [
    f'{BASE_URL}/files/{file_id}/extractions',
    f'{BASE_URL}/files/{file_id}/extraction',
    f'{BASE_URL}/files/{file_id}/data',
    f'{BASE_URL}/files/{file_id}',
]

for endpoint in endpoints_to_try:
    print(f"Trying: {endpoint}")
    try:
        response = requests.get(endpoint, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Response:")
            print(json.dumps(result, indent=2))
            break
        elif response.status_code != 404:
            print(f"Response: {response.text[:300]}")
    except Exception as e:
        print(f"Error: {e}")
    print()
