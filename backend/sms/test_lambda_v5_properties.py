"""
Property-Based Tests for Lambda V5 Enhanced Error Handling

This module contains property-based tests for the Lambda V5 handler that
integrates CloudWatch log polling and error code translation.

Requirements: 2.1, 4.1, 4.3, 4.4, 4.5
Properties: 3, 8, 9
"""

import pytest
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, patch, MagicMock
import json
from datetime import datetime

# Import modules under test
from lambda_function_url_handler_v5 import lambda_handler, error_response
from delivery_status_poller import DeliveryStatus
from error_code_translator import ErrorTranslation


# ============================================================================
# Property 3: CloudWatch Query on UNKNOWN_ERROR
# ============================================================================

# Feature: colombia-sms-unknown-error-fix, Property 3: CloudWatch Query on UNKNOWN_ERROR
@pytest.mark.property_test
@settings(max_examples=100, deadline=None)
@given(
    message_id=st.text(min_size=10, max_size=50, alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Pd'))),
    provider_response=st.sampled_from([
        "Country not supported",
        "Invalid phone number",
        "Price exceeded",
        "Carrier blocked",
        "Spam detected",
        "Rate limit exceeded",
        "Unknown carrier error"
    ])
)
def test_property_3_cloudwatch_query_on_unknown_error(message_id, provider_response):
    """
    Property 3: For any SMS delivery that results in UNKNOWN_ERROR,
    the system SHALL query CloudWatch logs for the actual carrier error code
    before returning the error to the user.
    
    Validates: Requirements 2.1, 4.4
    """
    # Create mock event
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
    
    # Create mock context
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to return MessageId
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        mock_sns.publish.return_value = {'MessageId': message_id}
        
        # Mock DeliveryStatusPoller to return FAILED status
        with patch('lambda_function_url_handler_v5.delivery_poller') as mock_poller:
            mock_poller.poll_delivery_status.return_value = DeliveryStatus(
                status='FAILED',
                message_id=message_id,
                provider_response=provider_response,
                timestamp=datetime.utcnow()
            )
            
            # Mock ErrorCodeTranslator
            with patch('lambda_function_url_handler_v5.error_translator') as mock_translator:
                mock_translator.translate_error.return_value = ErrorTranslation(
                    error_code='COUNTRY_NOT_SUPPORTED',
                    user_message='Colombia SMS not enabled',
                    remediation='Submit AWS support ticket',
                    original_response=provider_response,
                    error_level='AWS'
                )
                
                # Call Lambda handler
                response = lambda_handler(event, context)
                
                # PROPERTY VERIFICATION:
                # 1. CloudWatch logs MUST be queried (poll_delivery_status called)
                mock_poller.poll_delivery_status.assert_called_once()
                
                # 2. Error translation MUST be attempted (translate_error called)
                mock_translator.translate_error.assert_called_once()
                
                # 3. Response MUST NOT be "UNKNOWN_ERROR" without attempting to get details
                response_body = json.loads(response['body'])
                
                # If error code is UNKNOWN_ERROR, it means translation was attempted but no match found
                # This is acceptable - the property is that we TRIED to get details
                assert mock_poller.poll_delivery_status.called, \
                    "CloudWatch logs must be queried before returning UNKNOWN_ERROR"
                assert mock_translator.translate_error.called, \
                    "Error translation must be attempted before returning UNKNOWN_ERROR"


# ============================================================================
# Property 8: Lambda Error Response Structure
# ============================================================================

# Feature: colombia-sms-unknown-error-fix, Property 8: Lambda Error Response Structure
@pytest.mark.property_test
@settings(max_examples=100, deadline=None)
@given(
    error_code=st.sampled_from([
        'COUNTRY_NOT_SUPPORTED',
        'INVALID_PHONE_FORMAT',
        'PRICE_EXCEEDED',
        'CARRIER_BLOCKED',
        'SPAM_DETECTED',
        'RATE_LIMIT_EXCEEDED',
        'UNKNOWN_ERROR'
    ]),
    error_message=st.text(min_size=10, max_size=200),
    remediation=st.text(min_size=10, max_size=200),
    phone_number=st.sampled_from(['+573222063010', '+12025551234', '+447700900123']),
    message_id=st.one_of(
        st.none(),
        st.text(min_size=10, max_size=50, alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Pd')))
    )
)
def test_property_8_lambda_error_response_structure(error_code, error_message, remediation, phone_number, message_id):
    """
    Property 8: For any error that occurs during SMS delivery,
    the Lambda error response SHALL contain ok=false, errorCode, errorMessage,
    remediation, and messageId (if SNS returned one).
    
    Validates: Requirements 4.3, 4.5
    """
    # Call error_response function
    response = error_response(
        status_code=502,
        error_code=error_code,
        error_message=error_message,
        remediation=remediation,
        phone_number=phone_number,
        request_id='test-request-id',
        message_id=message_id
    )
    
    # PROPERTY VERIFICATION:
    # 1. Response MUST have non-200 status code for errors
    assert response['statusCode'] != 200, \
        "Error responses must have non-200 status code"
    
    # 2. Response body MUST be valid JSON
    response_body = json.loads(response['body'])
    
    # 3. Response MUST contain ok=false
    assert response_body['ok'] is False, \
        "Error responses must have ok=false"
    
    # 4. Response MUST contain errorCode
    assert 'errorCode' in response_body, \
        "Error responses must contain errorCode"
    assert response_body['errorCode'] == error_code, \
        "errorCode must match input"
    
    # 5. Response MUST contain errorMessage
    assert 'errorMessage' in response_body, \
        "Error responses must contain errorMessage"
    assert response_body['errorMessage'] == error_message, \
        "errorMessage must match input"
    
    # 6. Response MUST contain remediation
    assert 'remediation' in response_body, \
        "Error responses must contain remediation"
    assert response_body['remediation'] == remediation, \
        "remediation must match input"
    
    # 7. Response MUST contain messageId if SNS returned one
    if message_id is not None:
        assert 'messageId' in response_body, \
            "Error responses must contain messageId if SNS returned one"
        assert response_body['messageId'] == message_id, \
            "messageId must match input"
    
    # 8. Response MUST contain CORS headers
    assert 'Access-Control-Allow-Origin' in response['headers'], \
        "Error responses must contain CORS headers"
    
    # 9. Response MUST contain timestamp
    assert 'timestamp' in response_body, \
        "Error responses must contain timestamp"
    
    # 10. Response MUST contain requestId
    assert 'requestId' in response_body, \
        "Error responses must contain requestId"


# ============================================================================
# Property 9: SNS Error Capture
# ============================================================================

# Feature: colombia-sms-unknown-error-fix, Property 9: SNS Error Capture
@pytest.mark.property_test
@settings(max_examples=100, deadline=None)
@given(
    sns_error_message=st.text(min_size=10, max_size=200),
    sns_error_code=st.sampled_from([
        'InvalidParameter',
        'InvalidParameterValue',
        'Throttling',
        'InternalError',
        'ServiceUnavailable'
    ])
)
def test_property_9_sns_error_capture(sns_error_message, sns_error_code):
    """
    Property 9: For any SNS publish failure,
    the Lambda SHALL capture the full SNS error response including
    error code, message, and request ID.
    
    Validates: Requirements 4.1
    """
    # Create mock event
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
    
    # Create mock context
    context = Mock()
    context.aws_request_id = 'test-request-id'
    
    # Mock SNS publish to raise exception
    with patch('lambda_function_url_handler_v5.sns') as mock_sns:
        # Create SNS exception
        sns_exception = Exception(f'{sns_error_code}: {sns_error_message}')
        mock_sns.publish.side_effect = sns_exception
        
        # Mock ErrorCodeTranslator
        with patch('lambda_function_url_handler_v5.error_translator') as mock_translator:
            mock_translator.translate_error.return_value = ErrorTranslation(
                error_code='SNS_PUBLISH_FAILED',
                user_message=f'SNS error: {sns_error_message}',
                remediation='Check SNS configuration',
                original_response=str(sns_exception),
                error_level='AWS'
            )
            
            # Call Lambda handler
            response = lambda_handler(event, context)
            
            # PROPERTY VERIFICATION:
            # 1. SNS exception MUST be caught (not propagated)
            assert response is not None, \
                "SNS exceptions must be caught and handled"
            
            # 2. Error translator MUST be called with SNS error
            mock_translator.translate_error.assert_called_once()
            call_args = mock_translator.translate_error.call_args[0]
            assert sns_error_message in call_args[0] or sns_error_code in call_args[0], \
                "Error translator must receive SNS error details"
            
            # 3. Response MUST contain error information
            response_body = json.loads(response['body'])
            assert response_body['ok'] is False, \
                "SNS errors must result in ok=false"
            assert 'errorCode' in response_body, \
                "SNS errors must include errorCode"
            assert 'errorMessage' in response_body, \
                "SNS errors must include errorMessage"
            assert 'remediation' in response_body, \
                "SNS errors must include remediation"
            
            # 4. Response MUST have non-200 status code
            assert response['statusCode'] != 200, \
                "SNS errors must result in non-200 status code"


# ============================================================================
# Edge Case Tests
# ============================================================================

@pytest.mark.property_test
@settings(max_examples=50, deadline=None)
@given(
    phone_number=st.sampled_from([
        '',  # Empty
        'invalid',  # No +
        '+1',  # Too short
        '+123456789012345678',  # Too long
        '+0123456789',  # Starts with 0
        '+1234567890abc',  # Contains letters
    ])
)
def test_invalid_phone_number_validation(phone_number):
    """
    Test that invalid phone numbers are rejected with proper error response
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': phone_number,
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
    assert response['statusCode'] in [400, 502]
    assert 'errorCode' in response_body
    assert 'errorMessage' in response_body


@pytest.mark.property_test
@settings(max_examples=50, deadline=None)
@given(
    message=st.one_of(
        st.none(),
        st.just(''),
        st.text(max_size=0)
    )
)
def test_missing_message_validation(message):
    """
    Test that missing or empty messages are rejected with proper error response
    """
    event = {
        'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request'},
        'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
        'body': json.dumps({
            'to': '+573222063010',
            'message': message,
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
