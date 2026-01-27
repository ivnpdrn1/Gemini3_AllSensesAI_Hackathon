"""
Gemini API Client
Original work created for Google Gemini Hackathon 2026

Uses Google AI Studio with gemini-1.5-pro model
"""

import json
import os
from typing import Dict, Any, Optional
import logging
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import Gemini SDK
try:
    import google.generativeai as genai
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False
    logging.warning("google-generativeai not installed. Install with: pip install google-generativeai")

logger = logging.getLogger(__name__)


class GeminiClient:
    """
    Client for interacting with Google Gemini API via Google AI Studio.
    
    This is the primary intelligence interface for AllSensesAI.
    All emergency detection reasoning flows through Gemini.
    """
    
    def __init__(self, api_key: Optional[str] = None, model_name: Optional[str] = None):
        """
        Initialize Gemini client.
        
        Args:
            api_key: Google Gemini API key (from Google AI Studio)
            model_name: Gemini model version (gemini-1.5-pro or gemini-1.5-flash)
        """
        # Get API key from parameter or environment
        self.api_key = api_key or os.getenv("GOOGLE_GEMINI_API_KEY")
        if not self.api_key:
            raise RuntimeError(
                "Missing GOOGLE_GEMINI_API_KEY. "
                "Add it to .env file at project root or pass as parameter."
            )
        
        # Get model name from parameter or environment
        self.model_name = model_name or os.getenv("GEMINI_MODEL", "gemini-1.5-pro")
        
        # Validate model name
        valid_models = ["gemini-1.5-pro", "gemini-1.5-flash"]
        if self.model_name not in valid_models:
            logger.warning(
                f"Model '{self.model_name}' not in recommended list: {valid_models}. "
                f"Proceeding anyway, but this may fail."
            )
        
        # Initialize Gemini
        if GENAI_AVAILABLE:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)
            logger.info(f"Initialized GeminiClient with model: {self.model_name}")
        else:
            self.model = None
            logger.error("google-generativeai SDK not available")
    
    def analyze_emergency(
        self,
        input_data: Dict[str, Any],
        prompt_template: str
    ) -> Dict[str, Any]:
        """
        Analyze emergency situation using Gemini.
        
        Args:
            input_data: Multimodal input (text, audio, images, context)
            prompt_template: Formatted prompt for Gemini
            
        Returns:
            Structured risk assessment from Gemini
        """
        try:
            if not self.model:
                raise RuntimeError("Gemini model not initialized")
            
            # Call Gemini API
            response = self.model.generate_content(
                prompt_template,
                generation_config={
                    "temperature": 0.7,
                    "top_p": 0.95,
                    "top_k": 40,
                    "max_output_tokens": 2048,
                }
            )
            
            # Extract text response
            response_text = response.text
            
            # Parse and validate response
            parsed_response = self.parse_response(response_text)
            
            logger.info(f"Gemini analysis complete: {parsed_response['risk_level']}")
            return parsed_response
            
        except Exception as e:
            logger.error(f"Gemini API error: {str(e)}")
            return self._fallback_response(str(e))
    
    def parse_response(self, response_text: str) -> Dict[str, Any]:
        """
        Parse and validate Gemini JSON response.
        
        Args:
            response_text: Raw JSON response from Gemini
            
        Returns:
            Validated response dictionary
        """
        try:
            # Try to extract JSON from response
            # Gemini may wrap JSON in markdown code blocks
            if "```json" in response_text:
                start = response_text.find("```json") + 7
                end = response_text.find("```", start)
                response_text = response_text[start:end].strip()
            elif "```" in response_text:
                start = response_text.find("```") + 3
                end = response_text.find("```", start)
                response_text = response_text[start:end].strip()
            
            response = json.loads(response_text)
            
            # Validate required fields
            required_fields = [
                "risk_level",
                "confidence",
                "reasoning",
                "indicators",
                "recommended_action"
            ]
            
            for field in required_fields:
                if field not in response:
                    raise ValueError(f"Missing required field: {field}")
            
            # Validate risk_level enum
            valid_levels = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "NONE"]
            if response["risk_level"] not in valid_levels:
                raise ValueError(f"Invalid risk_level: {response['risk_level']}")
            
            # Validate confidence range
            if not 0.0 <= response["confidence"] <= 1.0:
                raise ValueError(f"Invalid confidence: {response['confidence']}")
            
            return response
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response: {str(e)}")
            return self._fallback_response("Invalid JSON response")
        except ValueError as e:
            logger.error(f"Invalid Gemini response structure: {str(e)}")
            return self._fallback_response(str(e))
    
    def _fallback_response(self, error_message: str) -> Dict[str, Any]:
        """
        Generate fallback response when Gemini fails.
        
        Args:
            error_message: Error description
            
        Returns:
            Safe fallback response
        """
        return {
            "risk_level": "MEDIUM",
            "confidence": 0.0,
            "reasoning": f"Gemini unavailable: {error_message}. Using fallback.",
            "indicators": ["API_ERROR"],
            "recommended_action": "MONITOR",
            "error": error_message
        }
    
    def health_check(self) -> bool:
        """
        Check if Gemini API is accessible.
        
        Returns:
            True if API is healthy, False otherwise
        """
        try:
            if not self.model:
                return False
            
            # Simple test call
            response = self.model.generate_content("test")
            return response is not None
            
        except Exception as e:
            logger.error(f"Gemini health check failed: {str(e)}")
            return False


def initialize_client(api_key: Optional[str] = None, model_name: Optional[str] = None) -> GeminiClient:
    """
    Factory function to create Gemini client.
    
    Args:
        api_key: Google Gemini API key (optional, reads from env)
        model_name: Gemini model version (optional, reads from env)
        
    Returns:
        Initialized GeminiClient instance
    """
    return GeminiClient(api_key=api_key, model_name=model_name)
