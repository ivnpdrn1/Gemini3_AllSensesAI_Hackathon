"""
Prompt Template Manager for Gemini 3
Original work created for Google Gemini 3 Hackathon 2026
"""

import json
import logging
from typing import Dict, Any, Optional
from pathlib import Path

logger = logging.getLogger(__name__)


class PromptManager:
    """
    Manages prompt templates for Gemini 3 API calls.
    
    Loads, formats, and validates prompts for emergency detection.
    """
    
    def __init__(self, prompts_dir: str = "prompts"):
        """
        Initialize prompt manager.
        
        Args:
            prompts_dir: Directory containing prompt templates
        """
        self.prompts_dir = Path(prompts_dir)
        self.templates = {}
        self._load_templates()
        logger.info(f"Initialized PromptManager with {len(self.templates)} templates")
    
    def _load_templates(self):
        """Load all prompt templates from directory."""
        try:
            # Load reasoning prompt
            reasoning_path = self.prompts_dir / "gemini_reasoning_prompt.md"
            if reasoning_path.exists():
                with open(reasoning_path, 'r', encoding='utf-8') as f:
                    self.templates['reasoning'] = f.read()
            
            # Load multimodal prompt
            multimodal_path = self.prompts_dir / "gemini_multimodal_prompt.md"
            if multimodal_path.exists():
                with open(multimodal_path, 'r', encoding='utf-8') as f:
                    self.templates['multimodal'] = f.read()
            
            # Load output schema
            schema_path = self.prompts_dir / "output_schema.json"
            if schema_path.exists():
                with open(schema_path, 'r', encoding='utf-8') as f:
                    self.templates['schema'] = json.load(f)
            
            logger.info(f"Loaded templates: {list(self.templates.keys())}")
            
        except Exception as e:
            logger.error(f"Failed to load templates: {str(e)}")
    
    def format_emergency_prompt(
        self,
        input_data: Dict[str, Any],
        template_name: str = "reasoning"
    ) -> str:
        """
        Format emergency detection prompt for Gemini 3.
        
        Args:
            input_data: Multimodal input data
            template_name: Name of template to use
            
        Returns:
            Formatted prompt string
        """
        if template_name not in self.templates:
            raise ValueError(f"Template not found: {template_name}")
        
        template = self.templates[template_name]
        
        # Extract modalities
        text_content = self._extract_text(input_data)
        audio_info = self._extract_audio_info(input_data)
        image_info = self._extract_image_info(input_data)
        context_info = self._format_context(input_data.get('context', {}))
        
        # Format prompt with input data
        formatted_prompt = template.format(
            text_content=text_content,
            audio_info=audio_info,
            image_info=image_info,
            context_info=context_info
        )
        
        # Add output schema instruction
        if 'schema' in self.templates:
            schema_json = json.dumps(self.templates['schema'], indent=2)
            formatted_prompt += f"\n\nRESPOND WITH JSON MATCHING THIS SCHEMA:\n{schema_json}"
        
        return formatted_prompt
    
    def _extract_text(self, input_data: Dict[str, Any]) -> str:
        """Extract text content from input data."""
        for modality in input_data.get('modalities', []):
            if modality.get('type') == 'text':
                return modality.get('content', '')
        return "No text provided"
    
    def _extract_audio_info(self, input_data: Dict[str, Any]) -> str:
        """Extract audio information from input data."""
        for modality in input_data.get('modalities', []):
            if modality.get('type') == 'audio':
                mime_type = modality.get('mime_type', 'unknown')
                return f"Audio file provided (type: {mime_type})"
        return "No audio provided"
    
    def _extract_image_info(self, input_data: Dict[str, Any]) -> str:
        """Extract image information from input data."""
        for modality in input_data.get('modalities', []):
            if modality.get('type') == 'image':
                mime_type = modality.get('mime_type', 'unknown')
                return f"Image file provided (type: {mime_type})"
        return "No image provided"
    
    def _format_context(self, context: Dict[str, Any]) -> str:
        """Format context information."""
        if not context:
            return "No additional context"
        
        context_parts = []
        
        if 'location' in context:
            loc = context['location']
            context_parts.append(f"Location: {loc.get('lat')}, {loc.get('lng')}")
        
        if 'timestamp' in context:
            context_parts.append(f"Time: {context['timestamp']}")
        
        if 'user_profile' in context:
            profile = context['user_profile']
            if 'age' in profile:
                context_parts.append(f"User age: {profile['age']}")
            if 'language' in profile:
                context_parts.append(f"Language: {profile['language']}")
        
        return "\n".join(context_parts) if context_parts else "No additional context"
    
    def get_schema(self) -> Optional[Dict[str, Any]]:
        """
        Get output schema for Gemini 3 responses.
        
        Returns:
            JSON schema dictionary or None
        """
        return self.templates.get('schema')
    
    def validate_response(self, response: Dict[str, Any]) -> bool:
        """
        Validate Gemini 3 response against schema.
        
        Args:
            response: Response dictionary from Gemini 3
            
        Returns:
            True if valid, False otherwise
        """
        schema = self.get_schema()
        if not schema:
            logger.warning("No schema available for validation")
            return True
        
        # Check required fields
        required_fields = schema.get('required', [])
        for field in required_fields:
            if field not in response:
                logger.error(f"Missing required field: {field}")
                return False
        
        # Check field types
        properties = schema.get('properties', {})
        for field, value in response.items():
            if field in properties:
                expected_type = properties[field].get('type')
                actual_type = type(value).__name__
                
                # Simple type checking
                type_map = {
                    'string': 'str',
                    'number': ['int', 'float'],
                    'array': 'list',
                    'object': 'dict',
                    'boolean': 'bool'
                }
                
                expected = type_map.get(expected_type, expected_type)
                if isinstance(expected, list):
                    if actual_type not in expected:
                        logger.error(f"Invalid type for {field}: expected {expected}, got {actual_type}")
                        return False
                elif actual_type != expected:
                    logger.error(f"Invalid type for {field}: expected {expected}, got {actual_type}")
                    return False
        
        return True


def create_manager(prompts_dir: str = "prompts") -> PromptManager:
    """
    Factory function to create prompt manager.
    
    Args:
        prompts_dir: Directory containing prompt templates
        
    Returns:
        Initialized PromptManager instance
    """
    return PromptManager(prompts_dir=prompts_dir)
