import pytest
from unittest.mock import patch, MagicMock
from app.poller import check_endpoint, check_endpoints


class TestCheckEndpoint:
    """Tests for the combined check_endpoint function."""

    @patch("app.poller.requests.get")
    def test_healthy_within_threshold(self, mock_get):
        """A fast successful response is HEALTHY."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        result = check_endpoint("https://example.com", 2000)

        assert result["status"] == "HEALTHY"
        assert result["latency_ms"] is not None
        assert result["error"] is None

    @patch("app.poller.requests.get")
    def test_timeout(self, mock_get):
        """A timeout is UNREACHABLE."""
        import requests
        mock_get.side_effect = requests.exceptions.Timeout()

        result = check_endpoint("https://example.com", 2000)

        assert result["status"] == "UNREACHABLE"
        assert result["error"] == "timeout"

    @patch("app.poller.requests.get")
    def test_connection_error(self, mock_get):
        """A connection error is UNREACHABLE."""
        import requests
        mock_get.side_effect = requests.exceptions.ConnectionError()

        result = check_endpoint("https://unreachable.invalid", 2000)

        assert result["status"] == "UNREACHABLE"
        assert result["error"] == "connection_error"


class TestCheckEndpoints:
    """Tests for the check_endpoints integration function."""

    @patch("app.poller.check_endpoint")
    def test_returns_results_for_all_endpoints(self, mock_check):
        """Returns one result per configured endpoint."""
        mock_check.return_value = {"status": "HEALTHY", "latency_ms": 100, "error": None}
        config = {"endpoints": [
            {"name": "A", "url": "https://a.com", "threshold_ms": 2000},
            {"name": "B", "url": "https://b.com", "threshold_ms": 2000}
        ]}

        results = check_endpoints(config)

        assert len(results) == 2
        assert results[0]["name"] == "A"
        assert results[1]["name"] == "B"
        assert all(r["status"] == "HEALTHY" for r in results)
