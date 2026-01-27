"""
Multimodal Input Preparation for Gemini 3
Original work created for Google Gemini 3 Hackathon 2026
"""

import base64
import logging
from typing import Dict, Any, List, Optional
from pathlib import Path

logger = logging.getLogger(__name__)


class MultimodalInputHandler:
    """
    Prepares multimodal inputs for Gemini 3 API.
    
    Handles text, audio, and image inputs, formatting them
    according to Gemini 3 API requirements.
    """
    
    def __init__(self):
        """Initialize multimodal input handler."""
        self.supported_audio_formats = ['.mp3', '.wav', '.m4a', '.ogg']
        self.supported_image_formats = ['.jpg', '.jpeg', '.png', '.webp']
        logger.info("Initialized MultimodalInputHandler")
    
    def prepare_input(
        self,
        text: Optional[str] = None,
        audio_path: Optional[str] = None,
        image_path: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Prepare multimodal input for Gemini 3.
        
        Args:
            text: Text transcript or message
            audio_path: Path to audio file
            image_path: Path to image file
            context: Additional context (location, time, user profile)
            
        Returns:
            Formatted input dictionary for Gemini 3
        """
        input_data = {
            "modalities": [],
            "context": context or {}
        }
        
        # Add text modality
        if text:
            input_data["modalities"].append({
                "type": "text",
                "content": text
            })
            logger.debug(f"Added text modality: {len(text)} characters")
        
        # Add audio modality
        if audio_path:
            audio_data = self._prepare_audio(audio_path)
            if audio_data:
                input_data["modalities"].append(audio_data)
                logger.debug(f"Added audio modality: {audio_path}")
        
        # Add image modality
        if image_path:
            image_data = self._prepare_image(image_path)
            if image_data:
                input_data["modalities"].append(image_data)
                logger.debug(f"Added image modality: {image_path}")
        
        # Validate input
        if not input_data["modalities"]:
            raise ValueError("At least one modality (text, audio, or image) required")
        
        return input_data
    
    def _prepare_audio(self, audio_path: str) -> Optional[Dict[str, Any]]:
        """
        Prepare audio file for Gemini 3.
        
        Args:
            audio_path: Path to audio file
            
        Returns:
            Audio modality dictionary or None if error
        """
        try:
            path = Path(audio_path)
            
            # Validate format
            if path.suffix.lower() not in self.supported_audio_formats:
                logger.warning(f"Unsupported audio format: {path.suffix}")
                return None
            
            # Read and encode audio
            with open(path, 'rb') as f:
                audio_bytes = f.read()
            
            audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
            
            return {
                "type": "audio",
                "mime_type": self._get_audio_mime_type(path.suffix),
                "data": audio_base64
            }
            
        except Exception as e:
            logger.error(f"Failed to prepare audio: {str(e)}")
            return None
    
    def _prepare_image(self, image_path: str) -> Optional[Dict[str, Any]]:
        """
        Prepare image file for Gemini 3.
        
        Args:
            image_path: Path to image file
            
        Returns:
            Image modality dictionary or None if error
        """
        try:
            path = Path(image_path)
            
            # Validate format
            if path.suffix.lower() not in self.supported_image_formats:
                logger.warning(f"Unsupported image format: {path.suffix}")
                return None
            
            # Read and encode image
            with open(path, 'rb') as f:
                image_bytes = f.read()
            
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')
            
            return {
                "type": "image",
                "mime_type": self._get_image_mime_type(path.suffix),
                "data": image_base64
            }
            
        except Exception as e:
            logger.error(f"Failed to prepare image: {str(e)}")
            return None
    
    def _get_audio_mime_type(self, extension: str) -> str:
        """Get MIME type for audio file."""
        mime_types = {
            '.mp3': 'audio/mpeg',
            '.wav': 'audio/wav',
            '.m4a': 'audio/mp4',
            '.ogg': 'audio/ogg'
        }
        return mime_types.get(extension.lower(), 'audio/mpeg')
    
    def _get_image_mime_type(self, extension: str) -> str:
        """Get MIME type for image file."""
        mime_types = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.webp': 'image/webp'
        }
        return mime_types.get(extension.lower(), 'image/jpeg')
    
    def add_context(
        self,
        input_data: Dict[str, Any],
        location: Optional[Dict[str, float]] = None,
        timestamp: Optional[str] = None,
        user_profile: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Add contextual information to input.
        
        Args:
            input_data: Existing input data
            location: GPS coordinates (lat, lng)
            timestamp: ISO 8601 timestamp
            user_profile: User demographics and preferences
            
        Returns:
            Enhanced input data with context
        """
        if location:
            input_data["context"]["location"] = location
        
        if timestamp:
            input_data["context"]["timestamp"] = timestamp
        
        if user_profile:
            input_data["context"]["user_profile"] = user_profile
        
        return input_data


def create_handler() -> MultimodalInputHandler:
    """
    Factory function to create multimodal input handler.
    
    Returns:
        Initialized MultimodalInputHandler instance
    """
    return MultimodalInputHandler()
