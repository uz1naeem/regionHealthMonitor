import json
import os

DEFAULT_CONFIG = {
    "endpoints": [
        {"name": "EC2", "url": "https://ec2.eu-west-1.amazonaws.com", "threshold_ms": 2000},
        {"name": "S3", "url": "https://s3.eu-west-1.amazonaws.com", "threshold_ms": 2000},
        {"name": "Lambda", "url": "https://lambda.eu-west-1.amazonaws.com", "threshold_ms": 2000}
    ]
}


def load_config(path=None):
    """Load endpoint configuration from file or return defaults."""
    if path and os.path.exists(path):
        with open(path, 'r') as f:
            data = json.load(f)
            if not isinstance(data.get("endpoints"), list):
                raise ValueError("Config must contain an 'endpoints' list")
            for ep in data["endpoints"]:
                if "url" not in ep or "name" not in ep:
                    raise ValueError("Each endpoint must have 'name' and 'url' fields")
            return data
    return DEFAULT_CONFIG
