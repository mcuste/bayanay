Retry fn with exponential backoff. Sleeps 1s, 2s, 4s between attempts. Re-raises last exception if all 3 fail.

```python
import time
import requests
from requests.exceptions import RequestException


def retry_request(method, url, max_retries=3, **kwargs):
    for attempt in range(max_retries):
        try:
            response = requests.request(method, url, **kwargs)
            response.raise_for_status()
            return response
        except RequestException:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)
```

Usage:

```python
response = retry_request("GET", "https://api.example.com/data")
response = retry_request("POST", "https://api.example.com/submit", json={"key": "value"})
```

Backoff schedule: attempt 0 → 1s, attempt 1 → 2s, attempt 2 → raise. `raise_for_status()` catches 4xx/5xx too, not only connection errors. Pass any `requests.request` kwarg through `**kwargs` (headers, timeout, auth, etc.).
