import pytest
import json
import tempfile
import os
from app.config import load_config


class TestLoadConfig:
    """Tests for configuration loading."""

    def test_returns_defaults_when_no_path(self):
        """Returns default config when no path provided."""
        config = load_config(None)
        assert "endpoints" in config
        assert len(config["endpoints"]) > 0

    def test_loads_from_valid_file(self):
        """Loads config from a valid JSON file."""
        data = {"endpoints": [{"name": "Test", "url": "https://test.com", "threshold_ms": 1000}]}
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(data, f)
            path = f.name
        try:
            config = load_config(path)
            assert config["endpoints"][0]["name"] == "Test"
        finally:
            os.unlink(path)

    def test_raises_on_missing_url(self):
        """Raises ValueError when endpoint missing url field."""
        data = {"endpoints": [{"name": "Bad"}]}
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(data, f)
            path = f.name
        try:
            with pytest.raises(ValueError):
                load_config(path)
        finally:
            os.unlink(path)

    def test_returns_defaults_when_file_missing(self):
        """Returns defaults when path does not exist."""
        config = load_config("/nonexistent/path.json")
        assert "endpoints" in config
