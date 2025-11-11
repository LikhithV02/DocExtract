#!/usr/bin/env python3
import sys
import requests
import json
import time

API_KEY = 'llx-WxpnuBrjBwvHmktFnGJIG0VnH7pz6nAxGyA6vLVVIyzX2IwG'
BASE_URL = 'https://api.cloud.llamaindex.ai/api/v1'

if len(sys.argv) < 2:
    print("Usage: python3 check_extraction_result.py <job_id>")
    sys.exit(1)

job_id = sys.argv[1]
headers = {
    'Authorization': f'Bearer {API_KEY}',
    'Content-Type': 'application/json'
}

print(f"Checking extraction job: {job_id}")
print("=" * 60)

# Poll for results
for attempt in range(30):  # Try for up to 60 seconds
    try:
        response = requests.get(
            f'{BASE_URL}/extraction/job/{job_id}',
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            status = result.get('status', 'UNKNOWN')
            print(f"\nAttempt {attempt + 1}: Status = {status}")
            
            if status == 'SUCCESS':
                print("\n✅ Extraction completed successfully!")
                print("\n" + "=" * 60)
                print("EXTRACTED DATA:")
                print("=" * 60)
                if 'data' in result:
                    print(json.dumps(result['data'], indent=2))
                else:
                    print(json.dumps(result, indent=2))
                break
            elif status == 'ERROR':
                print(f"\n❌ Extraction failed: {result.get('error')}")
                break
            elif status == 'PENDING':
                time.sleep(2)
                continue
        else:
            print(f"Error: Status {response.status_code}")
            print(response.text)
            break
    except Exception as e:
        print(f"Error: {e}")
        break
else:
    print("\n⏱️ Timeout waiting for extraction to complete")

print("\n" + "=" * 60)
