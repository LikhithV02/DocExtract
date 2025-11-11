#!/usr/bin/env python3
import requests
import json

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'
JOB_ID = '1221a4ab-a7fc-4466-a8c3-3e2fc6e4a360'

headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

endpoint = f'{BASE_URL}/extraction/jobs/{JOB_ID}/result'
print(f"Fetching extraction result from: {endpoint}")
print("=" * 60)

try:
    response = requests.get(endpoint, headers=headers, timeout=10)
    print(f"Status: {response.status_code}\n")
    
    if response.status_code == 200:
        result = response.json()
        print("✅ SUCCESS! Extracted Data:")
        print("=" * 60)
        print(json.dumps(result, indent=2))
    else:
        print(f"❌ Error: {response.text}")
except Exception as e:
    print(f"❌ Exception: {e}")

print("\n" + "=" * 60)
