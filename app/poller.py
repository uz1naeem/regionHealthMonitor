import requests
import time


def poll_endpoint(url, timeout=5):
    """Make an HTTP request to the endpoint and record the response."""
    try:
        start = time.time()
        response = requests.get(url, timeout=timeout)
        latency_ms = (time.time() - start) * 1000
        return {
            "status_code": response.status_code,
            "latency_ms": round(latency_ms, 2),
            "error": None
        }
    except requests.exceptions.Timeout:
        return {"status_code": None, "latency_ms": None, "error": "timeout"}
    except requests.exceptions.ConnectionError:
        return {"status_code": None, "latency_ms": None, "error": "connection_error"}
    except Exception as e:
        return {"status_code": None, "latency_ms": None, "error": str(e)}


def classify_result(poll_result, threshold_ms):
    """Classify the poll result as HEALTHY, DEGRADED, or UNREACHABLE."""
    if poll_result["error"] is not None:
        return "UNREACHABLE"
    if poll_result["latency_ms"] > threshold_ms:
        return "DEGRADED"
    return "HEALTHY"


def check_endpoints(config):
    """Poll all configured endpoints and return classified results."""
    results = []
    for endpoint in config["endpoints"]:
        poll_result = poll_endpoint(endpoint["url"])
        status = classify_result(poll_result, endpoint.get("threshold_ms", 2000))
        results.append({
            "name": endpoint["name"],
            "url": endpoint["url"],
            "status": status,
            "latency_ms": poll_result["latency_ms"],
            "error": poll_result["error"]
        })
    return results
