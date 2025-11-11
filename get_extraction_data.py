#!/usr/bin/env python3
import sys
import requests
import json

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'

if len(sys.argv) < 2:
    print("Usage: python3 get_extraction_data.py <job_id>")
    sys.exit(1)

job_id = sys.argv[1]
headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

print(f"Fetching extraction data for job: {job_id}")
print("=" * 60)

# Try to get the results
endpoints = [
    f'{BASE_URL}/extraction/jobs/{job_id}/results',
    f'{BASE_URL}/extraction/jobs/{job_id}/data',
    f'{BASE_URL}/extraction/jobs/{job_id}',
]

for endpoint in endpoints:
    print(f"\nTrying: {endpoint}")
    try:
        response = requests.get(endpoint, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Response received!")
            
            # Check for data field
            if 'data' in result:
                print("\n" + "=" * 60)
                print("EXTRACTED DATA:")
                print("=" * 60)
                print(json.dumps(result['data'], indent=2))
            else:
                print("\nFull Response:")
                print(json.dumps(result, indent=2))
            
            break
        elif response.status_code != 404:
            print(f"Response: {response.text[:200]}")
    except Exception as e:
        print(f"Error: {e}")

print("\n" + "=" * 60)
