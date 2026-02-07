"""
Unit tests for Lambda Function URL Handler V4
Tests MaxPrice, SMSType, and SenderID attribute inclusion
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lambda_function_url_handler_v4 import lambda_handler, error_response, mask_phone


class TestMaxPriceAttributeInclusion(unittest.TestCase):
    """Test suite for MaxPrice attribute inclusion in SNS publish"""
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_sns_publish_includes_maxprice_attribute(self, mock_sns):
        """Test that SNS publish includes MaxPrice attribute"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-123'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test emergency message',
                'buildId': 'test-build',
                'meta': {'victimName': 'Test User', 'risk': 'HIGH', 'lat': 4.6, 'lng': -74.08}
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 200)
        mock_sns.publish.assert_called_once()
        
        # Verify MaxPrice attribute is included
        call_args = mock_sns.publish.call_args
        message_attributes = call_args[1]['MessageAttributes']
        
        self.assertIn('AWS.SNS.SMS.MaxPrice', message_attributes)
        self.assertEqual(message_attributes['AWS.SNS.SMS.MaxPrice']['DataType'], 'String')
        self.assertEqual(message_attributes['AWS.SNS.SMS.MaxPrice']['StringValue'], '0.50')
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_maxprice_value_is_at_least_005(self, mock_sns):
        """Test that MaxPrice value is >= $0.05 (minimum for international SMS)"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-456'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        call_args = mock_sns.publish.call_args
        message_attributes = call_args[1]['MessageAttributes']
        max_price_str = message_attributes['AWS.SNS.SMS.MaxPrice']['StringValue']
        max_price_value = float(max_price_str)
        
        self.assertGreaterEqual(max_price_value, 0.05, 
                                f"MaxPrice {max_price_value} is less than minimum $0.05")
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_sns_publish_includes_smstype_transactional(self, mock_sns):
        """Test that SNS publish includes SMSType=Transactional"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-789'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        call_args = mock_sns.publish.call_args
        message_attributes = call_args[1]['MessageAttributes']
        
        self.assertIn('AWS.SNS.SMS.SMSType', message_attributes)
        self.assertEqual(message_attributes['AWS.SNS.SMS.SMSType']['StringValue'], 'Transactional')
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_sns_publish_includes_senderid(self, mock_sns):
        """Test that SNS publish includes SenderID=AllSenses"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id-abc'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        call_args = mock_sns.publish.call_args
        message_attributes = call_args[1]['MessageAttributes']
        
        self.assertIn('AWS.SNS.SMS.SenderID', message_attributes)
        self.assertEqual(message_attributes['AWS.SNS.SMS.SenderID']['StringValue'], 'AllSenses')


class TestPhoneNumberValidation(unittest.TestCase):
    """Test suite for phone number validation"""
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_valid_colombia_number_accepted(self, mock_sns):
        """Test that valid Colombia number (+57) is accepted"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertTrue(body['ok'])
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_valid_usa_number_accepted(self, mock_sns):
        """Test that valid USA number (+1) is accepted"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+12025551234',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertTrue(body['ok'])
    
    def test_invalid_phone_format_rejected(self):
        """Test that invalid phone format is rejected"""
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '3001234567',  # Missing + prefix
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertFalse(body['ok'])
        self.assertEqual(body['errorCode'], 'INVALID_PHONE_FORMAT')


class TestErrorHandling(unittest.TestCase):
    """Test suite for error handling"""
    
    def test_missing_phone_number_returns_400(self):
        """Test that missing phone number returns HTTP 400"""
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertFalse(body['ok'])
        self.assertEqual(body['errorCode'], 'MISSING_PHONE')
    
    def test_missing_message_returns_400(self):
        """Test that missing message returns HTTP 400"""
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertFalse(body['ok'])
        self.assertEqual(body['errorCode'], 'MISSING_MESSAGE')
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_sns_publish_failure_returns_502(self, mock_sns):
        """Test that SNS publish failure returns HTTP 502"""
        # Arrange
        mock_sns.publish.side_effect = Exception('SNS service unavailable')
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 502)
        body = json.loads(response['body'])
        self.assertFalse(body['ok'])
        self.assertEqual(body['errorCode'], 'SNS_PUBLISH_FAILED')


class TestCORSHeaders(unittest.TestCase):
    """Test suite for CORS headers"""
    
    def test_options_request_returns_cors_headers(self):
        """Test that OPTIONS request returns CORS headers"""
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'OPTIONS'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'}
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertEqual(response['statusCode'], 200)
        self.assertIn('Access-Control-Allow-Origin', response['headers'])
        self.assertIn('Access-Control-Allow-Methods', response['headers'])
        self.assertIn('Access-Control-Allow-Headers', response['headers'])
    
    @patch('lambda_function_url_handler_v4.sns')
    def test_success_response_includes_cors_headers(self, mock_sns):
        """Test that success response includes CORS headers"""
        # Arrange
        mock_sns.publish.return_value = {'MessageId': 'test-message-id'}
        
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'to': '+573001234567',
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertIn('Access-Control-Allow-Origin', response['headers'])
        self.assertEqual(response['headers']['Access-Control-Allow-Origin'], 
                        'https://dfc8ght8abwqc.cloudfront.net')
    
    def test_error_response_includes_cors_headers(self):
        """Test that error response includes CORS headers"""
        # Arrange
        event = {
            'requestContext': {'http': {'method': 'POST'}, 'requestId': 'test-request-id'},
            'headers': {'origin': 'https://dfc8ght8abwqc.cloudfront.net'},
            'body': json.dumps({
                'message': 'Test message',
                'buildId': 'test-build'
            })
        }
        
        context = Mock()
        context.aws_request_id = 'test-request-id'
        
        # Act
        response = lambda_handler(event, context)
        
        # Assert
        self.assertIn('Access-Control-Allow-Origin', response['headers'])


class TestHelperFunctions(unittest.TestCase):
    """Test suite for helper functions"""
    
    def test_mask_phone_masks_middle_digits(self):
        """Test that mask_phone masks middle digits"""
        # Act
        masked = mask_phone('+573001234567')
        
        # Assert
        self.assertEqual(masked, '+57***4567')
    
    def test_mask_phone_handles_short_numbers(self):
        """Test that mask_phone handles short numbers"""
        # Act
        masked = mask_phone('+1234')
        
        # Assert
        self.assertEqual(masked, '+1234')
    
    def test_mask_phone_handles_none(self):
        """Test that mask_phone handles None"""
        # Act
        masked = mask_phone(None)
        
        # Assert
        self.assertEqual(masked, 'N/A')
    
    def test_error_response_structure(self):
        """Test that error_response returns correct structure"""
        # Act
        response = error_response(400, 'TEST_ERROR', 'Test error message', '+573001234567', 'test-request-id')
        
        # Assert
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertFalse(body['ok'])
        self.assertEqual(body['errorCode'], 'TEST_ERROR')
        self.assertEqual(body['errorMessage'], 'Test error message')
        self.assertEqual(body['requestId'], 'test-request-id')


if __name__ == '__main__':
    unittest.main()
