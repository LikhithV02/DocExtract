#!/usr/bin/env python3
import sys
import requests
import json
import time

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'

if len(sys.argv) < 2:
    print("Usage: python3 check_extraction_v2.py <job_id>")
    sys.exit(1)

job_id = sys.argv[1]
headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

print(f"Checking extraction job: {job_id}")
print("=" * 60)

# Try different endpoint patterns
endpoints = [
    f'{BASE_URL}/extraction/job/{job_id}',
    f'{BASE_URL}/extraction/{job_id}',
    f'{BASE_URL}/extraction/jobs/{job_id}',
    f'{BASE_URL}/extraction/run/{job_id}',
]

for endpoint in endpoints:
    print(f"\nTrying: {endpoint}")
    try:
        response = requests.get(endpoint, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("\n✅ Found! Response:")
            print(json.dumps(response.json(), indent=2))
            break
        elif response.status_code != 404:
            print(f"Response: {response.text[:200]}")
    except Exception as e:
        print(f"Error: {e}")

print("\n" + "=" * 60)
