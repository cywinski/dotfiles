---
description: Check remaining OpenRouter API credits
allowed-tools: Bash, Read
---

Check my OpenRouter credits by running this:

```python
import requests
from dotenv import load_dotenv
import os

load_dotenv()
url = "https://openrouter.ai/api/v1/credits"
headers = {"Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}"}
response = requests.get(url, headers=headers)
print(response.json())
```

Report the remaining balance clearly.
