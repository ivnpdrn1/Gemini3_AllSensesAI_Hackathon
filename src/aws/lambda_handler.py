"""
AWS Lambda Handler for AllSensesAI
Original work created for Google Gemini 3 Hackathon 2026
"""

import json
import logging
import os
from typing import Dict, Any

# Import our modules
import sys
sys.path.append('/opt/python')  # Lambda layer path

from gemini.client import GeminiClient
from gemini.multimodal import MultimodalInputHandler
from gemini.prompts import PromptManager
from kiro.orchestrator import KIROOrchestrator
from aws.sns_client import SNSClient

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients (reuse across invocations)
gemini_client = None
multimodal_handler = None
prompt_manager = None
kiro_orchestrator = None
sns_client = None


def initialize_clients():
    """Initialize all service clients."""
    global gemini_client, multimodal_handler, prompt_manager, kiro_orchestrator, sns_client
    
    if gemini_client is None:
        # Get Gemini API key from environment
        api_key = os.environ.get('GOOGLE_GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GOOGLE_GEMINI_API_KEY environment variable not set")
        
        model_name = os.environ.get('GEMINI_MODEL', 'gemini-1.5-pro')
        
        gemini_client = GeminiClient(api_key=api_key, model_name=model_name)
        multimodal_handler = MultimodalInputHandler()
        prompt_manager = PromptManager(prompts_dir='/opt/prompts')
        
        # KIRO orchestrator needs config
        kiro_config = {
            "thresholds": {
                "CRITICAL": 0.8,
                "HIGH": 0.7,
                "MEDIUM": 0.5,
                "LOW": 0.3
            }
        }
        kiro_orchestrator = KIROOrchestrator(config=kiro_config)
        sns_client = SNSClient()
        
        logger.info("All clients initialized successfully")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for emergency detection.
    
    Args:
        event: Lambda event containing input data
        context: Lambda context object
        
    Returns:
        Response dictionary with status and results
    """
    try:
        # Initialize clients
        initialize_clients()
        
        # Parse input
        body = json.loads(event.get('body', '{}'))
        
        # Extract input data
        text = body.get('text')
        audio_url = body.get('audio_url')
        image_url = body.get('image_url')
        context_data = body.get('context', {})
        
        logger.info(f"Processing request with modalities: text={bool(text)}, audio={bool(audio_url)}, image={bool(image_url)}")
        
        # Prepare multimodal input
        input_data = multimodal_handler.prepare_input(
            text=text,
            audio_path=audio_url,  # TODO: Download from S3 if URL provided
            image_path=image_url,  # TODO: Download from S3 if URL provided
            context=context_data
        )
        
        # Format prompt
        prompt = prompt_manager.format_emergency_prompt(
            input_data=input_data,
            template_name='multimodal'
        )
        
        # Call Gemini 3 for analysis
        logger.info("Calling Gemini 3 for emergency analysis")
        gemini_response = gemini_client.analyze_emergency(
            input_data=input_data,
            prompt_template=prompt
        )
        
        # Validate response
        if not prompt_manager.validate_response(gemini_response):
            logger.error("Invalid Gemini 3 response structure")
            return error_response("Invalid AI response", 500)
        
        # KIRO orchestration - decide on action
        logger.info(f"KIRO processing risk level: {gemini_response['risk_level']}")
        action_decision = kiro_orchestrator.process_assessment(
            gemini_assessment=gemini_response,
            context=context_data
        )
        
        # Execute action if needed
        if action_decision.get('should_alert'):
            logger.info("Executing emergency alert")
            alert_result = execute_alert(
                gemini_response=gemini_response,
                context=context_data
            )
            action_decision['alert_result'] = alert_result
        
        # Return response
        return success_response({
            'risk_assessment': gemini_response,
            'action_decision': action_decision,
            'request_id': context.request_id
        })
        
    except Exception as e:
        logger.error(f"Lambda handler error: {str(e)}", exc_info=True)
        return error_response(str(e), 500)


def execute_alert(gemini_response: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute emergency alert via SNS.
    
    Args:
        gemini_response: Risk assessment from Gemini 3
        context: Contextual information
        
    Returns:
        Alert execution result
    """
    try:
        # Format alert message
        alert_message = format_alert_message(gemini_response, context)
        
        # Send via SNS
        topic_arn = os.environ.get('EMERGENCY_TOPIC_ARN')
        if not topic_arn:
            raise ValueError("EMERGENCY_TOPIC_ARN not configured")
        
        message_id = sns_client.publish_alert(
            topic_arn=topic_arn,
            message=alert_message,
            subject=f"EMERGENCY ALERT - {gemini_response['risk_level']}"
        )
        
        logger.info(f"Alert sent successfully: {message_id}")
        
        return {
            'status': 'SUCCESS',
            'message_id': message_id,
            'timestamp': context.get('timestamp')
        }
        
    except Exception as e:
        logger.error(f"Alert execution failed: {str(e)}")
        return {
            'status': 'FAILED',
            'error': str(e)
        }


def format_alert_message(gemini_response: Dict[str, Any], context: Dict[str, Any]) -> str:
    """
    Format emergency alert message.
    
    Args:
        gemini_response: Risk assessment from Gemini 3
        context: Contextual information
        
    Returns:
        Formatted alert message
    """
    message_parts = [
        f"EMERGENCY ALERT",
        f"Risk Level: {gemini_response['risk_level']}",
        f"Confidence: {gemini_response['confidence']:.2f}",
        f"",
        f"Analysis:",
        gemini_response['reasoning'],
        f"",
        f"Indicators:",
        ", ".join(gemini_response['indicators']),
        f"",
        f"Recommended Action: {gemini_response['recommended_action']}"
    ]
    
    # Add location if available
    if 'location' in context:
        loc = context['location']
        message_parts.append(f"")
        message_parts.append(f"Location: {loc.get('lat')}, {loc.get('lng')}")
    
    return "\n".join(message_parts)


def success_response(data: Dict[str, Any]) -> Dict[str, Any]:
    """Format successful Lambda response."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(data)
    }


def error_response(message: str, status_code: int = 400) -> Dict[str, Any]:
    """Format error Lambda response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': message
        })
    }
