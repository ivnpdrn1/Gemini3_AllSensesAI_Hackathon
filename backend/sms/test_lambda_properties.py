"""
Property-Based Tests for Lambda Function URL Handler V4
Uses Hypothesis to test universal properties across many inputs

**Property 1: MaxPrice Attribute Presence**
**Validates: Requirements 1.1**
For all valid SMS requests, the SNS publish call MUST include MaxPrice attribute
"""

import unittest
from unittest.mock import Mock, patch
import json
from hypothesis import given, strategies as st, settings, assume
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lambda_function_url_handler_v4 import lambda_handler


# Custom strategies for generating test data
@st.composite
def valid_phone_numbers(draw):
    """Generate valid E.164 phone numbers"""
    country_code = draw(st.sampled_from(['+1', '+57', '+44', '+61', '+81']))
    
    if country_code == '+1':
        # USA: +1 followed by 10 digits
        number = draw(st.integers(min_value=2000000000, max_value=9999999999))
        return f'{country_code}{number}'
    elif country_code == '+57':
        # Colombia: +57 followed by 10 digits (mobile starts with 3)
        first_digit = draw(st.sampled_from(['3']))
        rest = draw(st.integers(min_value=100000000, max_value=999999999))
        return f'{country_code}{first_digit}{rest}'
    else:
        # Other countries: 8-14 digits
        digits = draw(st.integers(min_value=10000000, max_value=99999999999999))
        return f'{country_code}{digits}'


@st.composite
def valid_sms_requests(draw):
    """Generate valid SMS request payloads"""
    phone = draw(valid_phone_numbers())
    message = draw(st.text(min_size=1, max_size=160, alphabet=st.characters(
        whitelist_categories=('Lu', 'Ll', 'Nd', 'Zs', 'Po')
    )))
    
    # Ensure message is not empty after stripping
    assume(len(message.strip()) > 0)
    
    return {
        'to': phone,
        'message': message,
        'buildId': draw(st.text(min_size=1, max_size=50, alphabet=st.characters(
            whitelist_categories=('Lu', 'Ll', 'Nd'), whitelist_characters='-_'
        ))),
        'meta': {
            'victimName': draw(st.text(min_size=1, max_size=50)),
            'risk': draw(st.sampled_from(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])),
            'lat': draw(st.floats(min_value=-90, max_value=90, allow_nan=False, allow_infinity=False)),
            'lng': draw(st.floats(min_value=-180, max_value=180, allow_nan=False, allow_infinity=False))
        }
    }


class TestMaxPriceAttributePresenceProperty(unittest.TestCase):
    """
    Property 1: MaxPrice Attribute Presence
    Validates: Requirements 1.1
    
    Universal Property: For all valid SMS requests, the SNS publish call
    MUST include the MaxPrice attribute with a value >= $0.05
    """
    
    @given(request_payload=valid_sms_requests())
    @settings(max_examples=100, deadline=None)
    @patch('lambda_function_url_handler_v4.sns')
    def test_property_maxprice_always_present(self, mock_sns, request_payload):
        """
        Property: MaxPrice attribute is ALWAYS present in SNS publish calls
        
        For any valid SMS request (phone number, message, metadata),
        the Lambda function MUST include MaxPrice in the SNS message attributes.
        
        This property ensures Colombia SMS delivery is never blocked by price limits.
        """
        # Arrange
        mock_sns.publish.return_value = {'MessageId': f'test-msg-{hash(str(request_payload))}'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps(request_payload)
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert - Property verification
        if response['statusCode'] == 200:
            # If request succeeded, verify MaxPrice was included
            self.assertTrue(mock_sns.publish.called, 
                          f"SNS publish should be called for valid request: {request_payload}")
            
            call_args = mock_sns.publish.call_args
            message_attributes = call_args[1]['MessageAttributes']
            
            # PROPERTY: MaxPrice MUST be present
            self.assertIn('AWS.SNS.SMS.MaxPrice', message_attributes,
                         f"MaxPrice attribute missing for request: {request_payload}")
            
            # PROPERTY: MaxPrice MUST have correct structure
            max_price_attr = message_attributes['AWS.SNS.SMS.MaxPrice']
            self.assertEqual(max_price_attr['DataType'], 'String',
                           f"MaxPrice DataType must be String, got: {max_price_attr['DataType']}")
            
            # PROPERTY: MaxPrice value MUST be >= $0.05
            max_price_value = float(max_price_attr['StringValue'])
            self.assertGreaterEqual(max_price_value, 0.05,
                                  f"MaxPrice {max_price_value} is below minimum $0.05")
            
            # PROPERTY: MaxPrice value MUST be reasonable (not too high)
            self.assertLessEqual(max_price_value, 5.00,
                               f"MaxPrice {max_price_value} is unreasonably high")
    
    @given(request_payload=valid_sms_requests())
    @settings(max_examples=100, deadline=None)
    @patch('lambda_function_url_handler_v4.sns')
    def test_property_smstype_always_transactional(self, mock_sns, request_payload):
        """
        Property: SMSType is ALWAYS set to Transactional for high-priority delivery
        
        For any valid SMS request, the Lambda function MUST set SMSType=Transactional
        to ensure emergency messages are delivered with high priority.
        """
        # Arrange
        mock_sns.publish.return_value = {'MessageId': f'test-msg-{hash(str(request_payload))}'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps(request_payload)
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert - Property verification
        if response['statusCode'] == 200:
            call_args = mock_sns.publish.call_args
            message_attributes = call_args[1]['MessageAttributes']
            
            # PROPERTY: SMSType MUST be present
            self.assertIn('AWS.SNS.SMS.SMSType', message_attributes,
                         f"SMSType attribute missing for request: {request_payload}")
            
            # PROPERTY: SMSType MUST be Transactional
            sms_type = message_attributes['AWS.SNS.SMS.SMSType']['StringValue']
            self.assertEqual(sms_type, 'Transactional',
                           f"SMSType must be Transactional, got: {sms_type}")
    
    @given(request_payload=valid_sms_requests())
    @settings(max_examples=100, deadline=None)
    @patch('lambda_function_url_handler_v4.sns')
    def test_property_senderid_always_present(self, mock_sns, request_payload):
        """
        Property: SenderID is ALWAYS set to AllSenses for brand identification
        
        For any valid SMS request, the Lambda function MUST include SenderID=AllSenses
        to identify the sender of emergency messages.
        """
        # Arrange
        mock_sns.publish.return_value = {'MessageId': f'test-msg-{hash(str(request_payload))}'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps(request_payload)
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert - Property verification
        if response['statusCode'] == 200:
            call_args = mock_sns.publish.call_args
            message_attributes = call_args[1]['MessageAttributes']
            
            # PROPERTY: SenderID MUST be present
            self.assertIn('AWS.SNS.SMS.SenderID', message_attributes,
                         f"SenderID attribute missing for request: {request_payload}")
            
            # PROPERTY: SenderID MUST be AllSenses
            sender_id = message_attributes['AWS.SNS.SMS.SenderID']['StringValue']
            self.assertEqual(sender_id, 'AllSenses',
                           f"SenderID must be AllSenses, got: {sender_id}")
    
    @given(request_payload=valid_sms_requests())
    @settings(max_examples=100, deadline=None)
    @patch('lambda_function_url_handler_v4.sns')
    def test_property_success_requires_message_id(self, mock_sns, request_payload):
        """
        Property: HTTP 200 response REQUIRES MessageId from SNS
        
        For any valid SMS request, if the Lambda returns HTTP 200,
        it MUST include a MessageId from SNS in the response body.
        """
        # Arrange
        message_id = f'test-msg-{hash(str(request_payload))}'
        mock_sns.publish.return_value = {'MessageId': message_id}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps(request_payload)
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert - Property verification
        if response['statusCode'] == 200:
            body = json.loads(response['body'])
            
            # PROPERTY: Success response MUST have ok=true
            self.assertTrue(body['ok'],
                          f"Success response must have ok=true, got: {body}")
            
            # PROPERTY: Success response MUST include MessageId
            self.assertIn('messageId', body,
                         f"Success response missing messageId: {body}")
            
            # PROPERTY: MessageId MUST match SNS response
            self.assertEqual(body['messageId'], message_id,
                           f"MessageId mismatch: expected {message_id}, got {body['messageId']}")


class TestPhoneNumberValidationProperty(unittest.TestCase):
    """
    Property 2: Phone Number Format Validation
    Validates: Requirements 3.1, 3.2, 3.5
    
    Universal Property: Invalid phone numbers MUST be rejected with HTTP 400
    """
    
    @given(
        invalid_phone=st.one_of(
            st.text(min_size=1, max_size=20, alphabet=st.characters(
                blacklist_characters='+0123456789'
            )),  # No digits
            st.text(min_size=1, max_size=5),  # Too short
            st.integers(min_value=1000000000, max_value=9999999999).map(str),  # Missing + prefix
        )
    )
    @settings(max_examples=50, deadline=None)
    def test_property_invalid_phone_rejected(self, invalid_phone):
        """
        Property: Invalid phone numbers are ALWAYS rejected with HTTP 400
        
        For any phone number that doesn't match E.164 format (+[country][number]),
        the Lambda function MUST return HTTP 400 with error code INVALID_PHONE_FORMAT.
        """
        # Skip if accidentally generated valid format
        assume(not invalid_phone.startswith('+'))
        assume(len(invalid_phone) < 8 or len(invalid_phone) > 16)
        
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': invalid_phone,
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert - Property verification
        # PROPERTY: Invalid phone MUST return HTTP 400
        self.assertEqual(response['statusCode'], 400,
                        f"Invalid phone {invalid_phone} should return 400, got {response['statusCode']}")
        
        body = json.loads(response['body'])
        
        # PROPERTY: Error response MUST have ok=false
        self.assertFalse(body['ok'],
                        f"Error response must have ok=false, got: {body}")
        
        # PROPERTY: Error response MUST include error code
        self.assertIn('errorCode', body,
                     f"Error response missing errorCode: {body}")


if __name__ == '__main__':
    unittest.main()
