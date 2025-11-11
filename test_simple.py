#!/usr/bin/env python3
import os
import requests

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
API_URL = 'https://api.cloud.llamaindex.ai/api/v1/extraction/run'

# Minimal test - just check what the API expects
headers = {
    'Authorization': f'Bearer {API_KEY}'
}

files = {
    'file': ('Invoice.jpeg', open('Invoice.jpeg', 'rb'), 'image/jpeg')
}

# Minimal schema
data = {
    'data_schema': '{"type": "object", "properties": {"total": {"type": "number"}}}',
    'config': '{}'
}

print("Sending request...")
response = requests.post(API_URL, headers=headers, files=files, data=data, timeout=120)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")

files['file'][1].close()
