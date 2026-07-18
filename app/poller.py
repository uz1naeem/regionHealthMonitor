import requests
import time


def check_endpoint(url, threshold_ms, timeout=5):
    """Poll an endpoint and classify the result in a single step.

    This combined function performs both the HTTP request and the
    HEALTHY/DEGRADED/UNREACHABLE classification. It is split into two
    focused functions in a later refactor (see refactor/split-poller).
    """
    try:
        start = time.time()
        response = requests.get(url, timeout=timeout)
        latency_ms = round((time.time() - start) * 1000, 2)
        if latency_ms > threshold_ms:
            return {"status": "DEGRADED", "latency_ms": latency_ms, "error": None}
        return {"status": "HEALTHY", "latency_ms": latency_ms, "error": None}
    except requests.exceptions.Timeout:
        return {"status": "UNREACHABLE", "latency_ms": None, "error": "timeout"}
    except requests.exceptions.ConnectionError:
        return {"status": "UNREACHABLE", "latency_ms": None, "error": "connection_error"}
    except Exception as e:
        return {"status": "UNREACHABLE", "latency_ms": None, "error": str(e)}


def check_endpoints(config):
    """Poll all configured endpoints and return classified results."""
    results = []
    for endpoint in config["endpoints"]:
        result = check_endpoint(endpoint["url"], endpoint.get("threshold_ms", 2000))
        results.append({
            "name": endpoint["name"],
            "url": endpoint["url"],
            "status": result["status"],
            "latency_ms": result["latency_ms"],
            "error": result["error"]
        })
    return results
