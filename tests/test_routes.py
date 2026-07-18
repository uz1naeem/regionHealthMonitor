import pytest
from app.routes import app


@pytest.fixture
def client():
    """Create Flask test client."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    """Tests for the /health endpoint."""

    def test_health_returns_200(self, client):
        """Health endpoint returns 200 OK."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "ok"


class TestStatusEndpoint:
    """Tests for the /status endpoint."""

    def test_status_returns_json(self, client):
        """Status endpoint returns JSON with results key."""
        response = client.get("/status")
        assert response.status_code == 200
        data = response.get_json()
        assert "results" in data
        assert isinstance(data["results"], list)


class TestDashboardEndpoint:
    """Tests for the /dashboard endpoint."""

    def test_dashboard_returns_html(self, client):
        """Dashboard endpoint returns HTML content."""
        response = client.get("/dashboard")
        assert response.status_code == 200
        assert b"Endpoint Health Monitor" in response.data
