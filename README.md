# Regional Service Endpoint Health Monitor

A lightweight Python/Flask service that polls a configurable list of AWS regional
service endpoints, records whether each responds within a latency threshold, and
exposes the results via a JSON API and an HTML dashboard.

Built for DevOps apprenticeship Modules 4.2 (CI/CD, Docker, Kubernetes) and
5.2 (Terraform, Ansible, monitoring).

## Endpoints

| Route        | Description                                              |
|--------------|----------------------------------------------------------|
| `/health`    | Liveness probe. Returns `{"status": "ok"}` with 200.     |
| `/status`    | JSON health results for all configured endpoints.        |
| `/dashboard` | HTML dashboard. Detail level controlled by feature flag. |

Each endpoint is classified as:
- **HEALTHY** — responded within the latency threshold
- **DEGRADED** — responded but exceeded the threshold
- **UNREACHABLE** — no response (timeout / connection error)

## Project structure

```
region-health-monitor/
├── app/
│   ├── __init__.py
│   ├── config.py      # endpoint config loading + validation
│   ├── poller.py      # poll_endpoint(), classify_result(), check_endpoints()
│   └── routes.py      # Flask app: /health, /status, /dashboard
├── tests/
│   ├── test_config.py
│   ├── test_poller.py
│   └── test_routes.py
├── k8s/deployment.yaml
├── scripts/
│   ├── setup-node.sh      # installs kind + kubectl, creates cluster
│   └── cleanup-images.sh  # prunes old Docker images
├── Dockerfile
├── Jenkinsfile
└── requirements.txt
```

## Local development

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest -v
```

Run the app:

```bash
python -m app.routes
curl http://localhost:8080/health
curl http://localhost:8080/status
```

## Configuration

By default the app monitors EC2, S3, and Lambda endpoints in `eu-west-1`.
Override by pointing `CONFIG_PATH` at a JSON file:

```json
{
  "endpoints": [
    {"name": "EC2", "url": "https://ec2.eu-west-1.amazonaws.com", "threshold_ms": 2000}
  ]
}
```

```bash
CONFIG_PATH=/path/to/config.json python -m app.routes
```

## Feature flag

`DASHBOARD_DETAIL_LEVEL` controls dashboard verbosity (branching by abstraction):

- `simple` (default) — status + name only
- `detailed` — also shows latency and URL

```bash
DASHBOARD_DETAIL_LEVEL=detailed python -m app.routes
```

## Docker

```bash
docker build -t region-health-monitor:1 .
docker run -d -p 8080:8080 --name health-monitor region-health-monitor:1
```

## CI/CD

`Jenkinsfile` defines a declarative pipeline: checkout → install → test →
dependency scan (pip-audit) → docker build → container scan (Trivy) → push →
deploy to Kubernetes. See `BUILD_GUIDE.md` for full setup on EC2.

Before use, replace `<your-dockerhub-username>` in `Jenkinsfile` and
`k8s/deployment.yaml` with your actual registry username.
