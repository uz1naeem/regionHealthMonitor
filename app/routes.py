import os
from flask import Flask, jsonify, render_template_string
from app.poller import check_endpoints
from app.config import load_config

app = Flask(__name__)
config = load_config(os.environ.get("CONFIG_PATH"))

# Feature flag: controls dashboard detail level
DETAIL_LEVEL = os.environ.get("DASHBOARD_DETAIL_LEVEL", "simple")

DASHBOARD_TEMPLATE = """
<!DOCTYPE html>
<html>
<head><title>Endpoint Health Monitor</title>
<style>
body { font-family: Arial, sans-serif; margin: 40px; background: #1a1a2e; color: #eee; }
h1 { color: #0f3460; }
.endpoint { padding: 12px; margin: 8px 0; border-radius: 6px; }
.HEALTHY { background: #16213e; border-left: 4px solid #0cce6b; }
.DEGRADED { background: #16213e; border-left: 4px solid #ffa62b; }
.UNREACHABLE { background: #16213e; border-left: 4px solid #e63946; }
.status { font-weight: bold; }
.latency { color: #999; font-size: 0.9em; }
</style></head>
<body>
<h1>Regional Endpoint Health Monitor</h1>
{% for ep in results %}
<div class="endpoint {{ ep.status }}">
    <span class="status">{{ ep.status }}</span> - {{ ep.name }}
    {% if detail_level == "detailed" %}
        <span class="latency">({{ ep.latency_ms }}ms - {{ ep.url }})</span>
    {% endif %}
</div>
{% endfor %}
</body></html>
"""


@app.route("/health")
def health():
    """Liveness probe endpoint."""
    return jsonify({"status": "ok"}), 200


@app.route("/status")
def status():
    """Return endpoint health results as JSON."""
    results = check_endpoints(config)
    return jsonify({"results": results}), 200


@app.route("/dashboard")
def dashboard():
    """Render HTML dashboard with endpoint health."""
    results = check_endpoints(config)
    return render_template_string(
        DASHBOARD_TEMPLATE,
        results=results,
        detail_level=DETAIL_LEVEL
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
