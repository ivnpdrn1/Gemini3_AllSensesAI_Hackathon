"""
Unit Tests for Lambda V5 Enhanced Error Handling

This module contains unit tests for specific error handling scenarios
in the Lambda V5 handler.

Requirements: 4.1, 4.2, 4.3, 4.5
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
import json
from datetime import datetime

# Import modules under test
from lambda_function_url_handler_v5 import lambda_handler, error_response, mask_phone
from delivery_status_poller import DeliveryStatus
from error_code_translator import ErrorTranslation


# ============================================================================
# Test SNS Publish Failure Handling
# ============================================================================

def test_sns_publish_failure_handling():
    """
    Test that SNS publish failures are captured and translated
    
    Requirements: 4.1
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to raise exception
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.side_effect = Exception('InvalidParameter: Phone number is invalid')
        
        # Mock ErrorCodeTranslator
        with patch('lambda_function_url_handler_v5.error_translator') as mock_translator:
            mock_translator.translate_error.return_value = ErrorTranslation(
                error_code='INVALID_PHONE_FORMAT',
                user_message='Phone number format is invalid',
                remediation='Use E.164 format: +573222063010',
                original_response='InvalidParameter: Phone number is invalid',
                error_level='AWS'
            )
            
            response = lambda_handler(event, context)
            response_body = json.loads(response['body'])
            
            # Verify error response
            assert response_body['ok'] is False
            assert response['statusCode'] == 502
            assert response_body['errorCode'] == 'INVALID_PHONE_FORMAT'
            assert 'Phone number format is invalid' in response_body['errorMessage']
            assert 'E.164 format' in response_body['remediation']


def test_sns_no_message_id_handling():
    """
    Test that missing MessageId is handled correctly
    
    Requirements: 4.1
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return response without MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {}  # No MessageId
        
        response = lambda_handler(event, context)
        response_body = json.loads(response['body'])
        
        # Verify error response
        assert response_body['ok'] is False
        assert response['statusCode'] == 502
        assert response_body['errorCode'] == 'NO_MESSAGE_ID'
        assert 'no MessageId' in response_body['errorMessage']


# ============================================================================
# Test MessageId Returned but Delivery Failed
# ============================================================================

def test_message_id_returned_delivery_failed():
    """
    Test that delivery failures are detected and translated
    
    Requirements: 4.2
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-123'}
        
        # Mock DeliveryStatusPoller to return FAILED status
        with patch('lambda_function_url_handler_v5.delivery_poller') as mock_poller:
            mock_poller.poll_delivery_status.return_value = DeliveryStatus(
                status='FAILED',
                message_id='test-message-id-123',
                provider_response='Country not supported',
                timestamp=datetime.utcnow()
            )
            
            # Mock ErrorCodeTranslator
            with patch('lambda_function_url_handler_v5.error_translator') as mock_translator:
                mock_translator.translate_error.return_value = ErrorTranslation(
                    error_code='COUNTRY_NOT_SUPPORTED',
                    user_message='Colombia SMS not enabled for this AWS account',
                    remediation='Submit AWS support ticket to enable Colombia SMS',
                    original_response='Country not supported',
                    error_level='AWS'
                )
                
                response = lambda_handler(event, context)
                response_body = json.loads(response['body'])
                
                # Verify error response
                assert response_body['ok'] is False
                assert response['statusCode'] == 502
                assert response_body['errorCode'] == 'COUNTRY_NOT_SUPPORTED'
                assert 'Colombia SMS not enabled' in response_body['errorMessage']
                assert 'AWS support ticket' in response_body['remediation']
                assert response_body['messageId'] == 'test-message-id-123'


def test_message_id_returned_delivery_success():
    """
    Test that successful deliveries are handled correctly
    
    Requirements: 4.2
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+12025551234',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 38.9, 'lng': -77.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-456'}
        
        # Mock DeliveryStatusPoller to return SUCCESS status
        with patch('lambda_function_url_handler_v5.delivery_poller') as mock_poller:
            mock_poller.poll_delivery_status.return_value = DeliveryStatus(
                status='SUCCESS',
                message_id='test-message-id-456',
                provider_response='Message delivered',
                timestamp=datetime.utcnow(),
                phone_carrier='Verizon',
                price_usd=0.00645
            )
            
            response = lambda_handler(event, context)
            response_body = json.loads(response['body'])
            
            # Verify success response
            assert response_body['ok'] is True
            assert response['statusCode'] == 200
            assert response_body['messageId'] == 'test-message-id-456'
            assert response_body['deliveryStatus'] == 'SUCCESS'
            assert response_body['carrier'] == 'Verizon'
            assert response_body['priceUSD'] == 0.00645


# ============================================================================
# Test CloudWatch Polling Timeout
# ============================================================================

def test_cloudwatch_polling_timeout():
    """
    Test that CloudWatch polling timeouts are handled gracefully
    
    Requirements: 4.2
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-789'}
        
        # Mock DeliveryStatusPoller to raise timeout exception
        with patch('lambda_function_url_handler_v5.delivery_poller') as mock_poller:
            mock_poller.poll_delivery_status.side_effect = Exception('CloudWatch query timeout')
            
            response = lambda_handler(event, context)
            response_body = json.loads(response['body'])
            
            # Verify success response with warning
            assert response_body['ok'] is True
            assert response['statusCode'] == 200
            assert response_body['messageId'] == 'test-message-id-789'
            assert response_body['deliveryStatus'] == 'UNKNOWN'
            assert 'could not be retrieved' in response_body['note']


def test_cloudwatch_polling_pending():
    """
    Test that PENDING delivery status is handled correctly
    
    Requirements: 4.2
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-pending'}
        
        # Mock DeliveryStatusPoller to return PENDING status
        with patch('lambda_function_url_handler_v5.delivery_poller') as mock_poller:
            mock_poller.poll_delivery_status.return_value = DeliveryStatus(
                status='PENDING',
                message_id='test-message-id-pending',
                provider_response='Delivery status not yet available',
                timestamp=datetime.utcnow()
            )
            
            response = lambda_handler(event, context)
            response_body = json.loads(response['body'])
            
            # Verify success response with pending note
            assert response_body['ok'] is True
            assert response['statusCode'] == 200
            assert response_body['messageId'] == 'test-message-id-pending'
            assert response_body['deliveryStatus'] == 'PENDING'
            assert 'within 2-5 minutes' in response_body['note']


# ============================================================================
# Test Error Response Includes All Required Fields
# ============================================================================

def test_error_response_all_fields():
    """
    Test that error responses include all required fields
    
    Requirements: 4.3, 4.5
    """
    response = error_response(
        status_code=502,
        error_code='COUNTRY_NOT_SUPPORTED',
        error_message='Colombia SMS not enabled',
        remediation='Submit AWS support ticket',
        phone_number='+573222063010',
        request_id='test-request-id',
        message_id='test-message-id'
    )
    
    response_body = json.loads(response['body'])
    
    # Verify all required fields
    assert response['statusCode'] == 502
    assert response_body['ok'] is False
    assert response_body['provider'] == 'sns'
    assert response_body['errorCode'] == 'COUNTRY_NOT_SUPPORTED'
    assert response_body['errorMessage'] == 'Colombia SMS not enabled'
    assert response_body['remediation'] == 'Submit AWS support ticket'
    assert response_body['messageId'] == 'test-message-id'
    assert response_body['toMasked'] == '+57***3010'
    assert response_body['requestId'] == 'test-request-id'
    assert 'timestamp' in response_body
    
    # Verify CORS headers
    assert 'Access-Control-Allow-Origin' in response['headers']
    assert response['headers']['Access-Control-Allow-Origin'] == 'https://dfc8ght8abwqc.cloudfront.net'


def test_error_response_without_message_id():
    """
    Test that error responses work without MessageId
    
    Requirements: 4.3, 4.5
    """
    response = error_response(
        status_code=400,
        error_code='MISSING_PHONE',
        error_message='Missing required field: to',
        remediation='Provide phone number in E.164 format',
        phone_number=None,
        request_id='test-request-id',
        message_id=None
    )
    
    response_body = json.loads(response['body'])
    
    # Verify required fields
    assert response['statusCode'] == 400
    assert response_body['ok'] is False
    assert response_body['errorCode'] == 'MISSING_PHONE'
    assert response_body['errorMessage'] == 'Missing required field: to'
    assert response_body['remediation'] == 'Provide phone number in E.164 format'
    assert 'messageId' not in response_body  # Should not be present
    assert response_body['toMasked'] == 'N/A'


# ============================================================================
# Test Phone Number Masking
# ============================================================================

def test_mask_phone():
    """Test phone number masking for privacy"""
    assert mask_phone('+12025551234') == '+12***1234'
    assert mask_phone('+573222063010') == '+57***3010'
    assert mask_phone('+447700900123') == '+44***0123'
    assert mask_phone(None) == 'N/A'
    assert mask_phone('') == 'N/A'
    assert mask_phone('+123') == '+123'  # Too short to mask


# ============================================================================
# Test CORS Preflight Handling
# ============================================================================

def test_cors_preflight_options():
    """Test that OPTIONS requests are handled correctly"""
    event = {
        'requestContext': {'http': {'method': 'OPTIONS'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'}
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    response = lambda_handler(event, context)
    
    # Verify CORS preflight response
    assert response['statusCode'] == 200
    assert response['body'] == ''
    assert 'Access-Control-Allow-Origin' in response['headers']
    assert 'Access-Control-Allow-Methods' in response['headers']
    assert 'Access-Control-Allow-Headers' in response['headers']
    assert 'Access-Control-Max-Age' in response['headers']


# ============================================================================
# Test Request Validation
# ============================================================================

def test_missing_phone_number():
    """Test that missing phone number is rejected"""
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    response = lambda_handler(event, context)
    response_body = json.loads(response['body'])
    
    # Verify error response
    assert response_body['ok'] is False
    assert response['statusCode'] == 400
    assert response_body['errorCode'] == 'MISSING_PHONE'
    assert 'Missing required field: to' in response_body['errorMessage']


def test_missing_message():
    """Test that missing message is rejected"""
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    response = lambda_handler(event, context)
    response_body = json.loads(response['body'])
    
    # Verify error response
    assert response_body['ok'] is False
    assert response['statusCode'] == 400
    assert response_body['errorCode'] == 'MISSING_MESSAGE'
    assert 'Missing required field: message' in response_body['errorMessage']


def test_invalid_phone_format():
    """Test that invalid phone format is rejected"""
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '573222063010',  # Missing +
            'message': 'Test emergency message',
            'buildId': 'test-build',
            'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.0}
        })
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    response = lambda_handler(event, context)
    response_body = json.loads(response['body'])
    
    # Verify error response
    assert response_body['ok'] is False
    assert response['statusCode'] == 400
    assert response_body['errorCode'] == 'INVALID_PHONE_FORMAT'
    assert 'E.164 format' in response_body['errorMessage']


def test_invalid_json():
    """Test that invalid JSON is rejected"""
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': 'invalid json {'
    }
    
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    response = lambda_handler(event, context)
    response_body = json.loads(response['body'])
    
    # Verify error response
    assert response_body['ok'] is False
    assert response['statusCode'] == 400
    assert response_body['errorCode'] == 'INVALID_JSON'
    assert 'Invalid JSON' in response_body['errorMessage']
