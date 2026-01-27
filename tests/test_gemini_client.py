"""
Tests for Gemini Client
Original work created for Google Gemini Hackathon 2026
"""

import unittest
import json
from unittest.mock import patch
import os
import sys
from pathlib import Path

# Add src/ to PYTHONPATH so `gemini` package is discoverable
PROJECT_ROOT = Path(__file__).resolve().parent.parent
SRC_PATH = PROJECT_ROOT / "src"
sys.path.insert(0, str(SRC_PATH))

from gemini.client import GeminiClient


class TestGeminiClient(unittest.TestCase):
    """Unit tests for Gemini API client."""

    def setUp(self):
        os.environ["GOOGLE_GEMINI_API_KEY"] = "test-api-key"
        os.environ["GEMINI_MODEL"] = "gemini-1.5-pro"

        # Patch flag in the correct module
        with patch("gemini.client.GENAI_AVAILABLE", False):
            self.client = GeminiClient()

    def test_initialization(self):
        self.assertEqual(self.client.model_name, "gemini-1.5-pro")

    def test_initialization_missing_key(self):
        del os.environ["GOOGLE_GEMINI_API_KEY"]
        with self.assertRaises(RuntimeError):
            GeminiClient()

    def test_parse_valid_response(self):
        response_text = json.dumps({
            "risk_level": "HIGH",
            "confidence": 0.85,
            "reasoning": "Multiple distress indicators detected",
            "indicators": ["help_request"],
            "recommended_action": "ALERT"
        })

        parsed = self.client.parse_response(response_text)
        self.assertEqual(parsed["risk_level"], "HIGH")
        self.assertEqual(parsed["confidence"], 0.85)

    def test_fallback_response(self):
        fallback = self.client._fallback_response("error")
        self.assertEqual(fallback["risk_level"], "MEDIUM")
        self.assertIn("error", fallback)


class TestGeminiIntegration(unittest.TestCase):
    """Integration-level tests."""

    def setUp(self):
        os.environ["GOOGLE_GEMINI_API_KEY"] = "test-key"
        os.environ["GEMINI_MODEL"] = "gemini-1.5-pro"

        with patch("gemini.client.GENAI_AVAILABLE", False):
            self.client = GeminiClient()

    def test_analyze_emergency_structure(self):
        result = self.client.analyze_emergency(
            {"modalities": [{"type": "text", "content": "Help"}]},
            "Analyze emergency"
        )

        self.assertIn("risk_level", result)
        self.assertIn("confidence", result)
        self.assertIn("reasoning", result)
        self.assertIn("indicators", result)
        self.assertIn("recommended_action", result)


if __name__ == "__main__":
    unittest.main()
