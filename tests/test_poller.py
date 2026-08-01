import pytest
from unittest.mock import patch, MagicMock
from app.poller import poll_endpoint, classify_result, check_endpoints


class TestPollEndpoint:
    """Tests for the poll_endpoint function."""

    @patch("app.poller.requests.get")
    def test_successful_request(self, mock_get):
        """A successful HTTP response returns status code and latency."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        result = poll_endpoint("https://example.com")

        assert result["status_code"] == 200
        assert result["latency_ms"] is not None
        assert result["error"] is None

    @patch("app.poller.requests.get")
    def test_timeout(self, mock_get):
        """A timeout returns error without status code."""
        import requests
        mock_get.side_effect = requests.exceptions.Timeout()

        result = poll_endpoint("https://example.com")

        assert result["status_code"] is None
        assert result["error"] == "timeout"

    @patch("app.poller.requests.get")
    def test_connection_error(self, mock_get):
        """A connection error returns UNREACHABLE classification."""
        import requests
        mock_get.side_effect = requests.exceptions.ConnectionError()

        result = poll_endpoint("https://unreachable.invalid")

        assert result["status_code"] is None
        assert result["error"] == "connection_error"


class TestClassifyResult:
    """Tests for the classify_result function."""

    def test_healthy_within_threshold(self):
        """Response within threshold is HEALTHY."""
        result = {"status_code": 200, "latency_ms": 150, "error": None}
        assert classify_result(result, 2000) == "HEALTHY"

    def test_degraded_exceeds_threshold(self):
        """Response exceeding threshold is DEGRADED."""
        result = {"status_code": 200, "latency_ms": 3500, "error": None}
        assert classify_result(result, 2000) == "DEGRADED"

    def test_unreachable_on_error(self):
        """Any error results in UNREACHABLE."""
        result = {"status_code": None, "latency_ms": None, "error": "connection_error"}
        assert classify_result(result, 2000) == "UNREACHABLE"

    def test_healthy_at_exact_threshold(self):
        """Response at exactly the threshold is HEALTHY (not degraded)."""
        result = {"status_code": 200, "latency_ms": 2000, "error": None}
        assert classify_result(result, 2000) == "HEALTHY"


class TestCheckEndpoints:
    """Tests for the check_endpoints integration function."""

    @patch("app.poller.poll_endpoint")
    def test_returns_results_for_all_endpoints(self, mock_poll):
        """Returns one result per configured endpoint."""
        mock_poll.return_value = {"status_code": 200, "latency_ms": 100, "error": None}
        config = {"endpoints": [
            {"name": "A", "url": "https://a.com", "threshold_ms": 2000},
            {"name": "B", "url": "https://b.com", "threshold_ms": 2000}
        ]}

        results = check_endpoints(config)

        assert len(results) == 2
        assert results[0]["name"] == "A"
        assert results[1]["name"] == "B"
        assert all(r["status"] == "HEALTHY" for r in results)
