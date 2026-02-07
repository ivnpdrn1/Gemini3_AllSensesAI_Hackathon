"""
Unit Tests for DeliveryStatusPoller

These tests verify specific examples, edge cases, and error conditions for
the CloudWatch log parsing functionality.

Feature: colombia-sms-unknown-error-fix
Requirements: 5.3
"""

import pytest
import json
from datetime import datetime
from unittest.mock import Mock

from delivery_status_poller import DeliveryStatusPoller, DeliveryStatus


class TestCloudWatchLogParsing:
    """Test CloudWatch log parsing functionality"""
    
    def test_parse_success_status_log(self):
        """
        Test parsing SUCCESS status logs
        
        Verifies that SUCCESS logs are parsed correctly with all fields.
        Requirements: 5.3
        """
        message_id = '05f4ef3-a91f-153a-d224-9c7d9a2ae9a3'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-06T22:51:41.655Z'
                },
                'delivery': {
                    'phoneCarrier': 'AT&T',
                    'destination': '+12025551234',
                    'priceInUSD': 0.00645,
                    'smsType': 'Transactional',
                    'providerResponse': 'Message delivered successfully',
                    'dwellTimeMs': 1234,
                    'dwellTimeMsUntilDeviceAck': 5678
                },
                'status': 'SUCCESS'
            }),
            'timestamp': 1707259901655
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None, "Parsing should succeed"
        assert result.status == 'SUCCESS'
        assert result.message_id == message_id
        assert result.provider_response == 'Message delivered successfully'
        assert result.phone_carrier == 'AT&T'
        assert result.price_usd == 0.00645
        assert result.dwell_time_ms == 1234
        assert isinstance(result.timestamp, datetime)
    
    def test_parse_failed_status_log_country_not_supported(self):
        """
        Test parsing FAILED status logs with "Country not supported" error
        
        Verifies that FAILED logs with carrier error codes are parsed correctly.
        Requirements: 5.3
        """
        message_id = 'abc-123-def-456-ghi'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-06T23:00:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'Claro Colombia',
                    'destination': '+573222063010',
                    'priceInUSD': 0.05,
                    'smsType': 'Transactional',
                    'providerResponse': 'Country not supported',
                    'dwellTimeMs': 2000
                },
                'status': 'FAILED'
            }),
            'timestamp': 1707260400000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None, "Parsing should succeed"
        assert result.status == 'FAILED'
        assert result.message_id == message_id
        assert result.provider_response == 'Country not supported'
        assert result.phone_carrier == 'Claro Colombia'
        assert result.price_usd == 0.05
    
    def test_parse_failed_status_log_price_exceeded(self):
        """
        Test parsing FAILED status logs with "Price exceeded" error
        
        Verifies that price-related errors are captured correctly.
        Requirements: 5.3
        """
        message_id = 'price-test-123'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-06T23:15:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'International Carrier',
                    'destination': '+573227863818',
                    'priceInUSD': 0.75,
                    'smsType': 'Transactional',
                    'providerResponse': 'Price exceeded',
                    'dwellTimeMs': 500
                },
                'status': 'FAILED'
            }),
            'timestamp': 1707261300000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'FAILED'
        assert result.provider_response == 'Price exceeded'
        assert result.price_usd == 0.75
    
    def test_parse_failed_status_log_carrier_blocked(self):
        """
        Test parsing FAILED status logs with "Carrier blocked" error
        
        Verifies that carrier blocking errors are captured.
        Requirements: 5.3
        """
        message_id = 'carrier-block-456'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-06T23:30:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'Movistar Colombia',
                    'destination': '+573001234567',
                    'priceInUSD': 0.04,
                    'smsType': 'Transactional',
                    'providerResponse': 'Carrier blocked',
                    'dwellTimeMs': 1500
                },
                'status': 'FAILED'
            }),
            'timestamp': 1707262200000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'FAILED'
        assert result.provider_response == 'Carrier blocked'
        assert result.phone_carrier == 'Movistar Colombia'
    
    def test_parse_log_missing_provider_response(self):
        """
        Test parsing logs with missing providerResponse field
        
        Verifies that missing fields are handled gracefully with defaults.
        Requirements: 5.3
        """
        message_id = 'missing-response-789'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-06T23:45:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'Unknown Carrier',
                    'destination': '+1234567890',
                    'priceInUSD': 0.01,
                    'smsType': 'Transactional',
                    # providerResponse is missing
                    'dwellTimeMs': 1000
                },
                'status': 'FAILED'
            }),
            'timestamp': 1707263100000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'FAILED'
        assert result.provider_response == 'No provider response'  # Default value
        assert result.message_id == message_id
    
    def test_parse_log_malformed_json(self):
        """
        Test handling malformed JSON in log entry
        
        Verifies that malformed JSON returns None instead of crashing.
        Requirements: 5.3
        """
        message_id = 'malformed-json-123'
        
        log_entry = {
            'message': 'This is not valid JSON {broken',
            'timestamp': 1707263400000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is None, "Malformed JSON should return None"
    
    def test_parse_log_missing_notification_section(self):
        """
        Test handling logs with missing notification section
        
        Verifies that incomplete log structure is handled gracefully.
        Requirements: 5.3
        """
        message_id = 'missing-notification-456'
        
        log_entry = {
            'message': json.dumps({
                # notification section is missing
                'delivery': {
                    'phoneCarrier': 'Test Carrier',
                    'destination': '+1234567890',
                    'providerResponse': 'Test response'
                },
                'status': 'FAILED'
            }),
            'timestamp': 1707263700000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        # Should return None because MessageId cannot be validated
        assert result is None, "Missing notification section should return None"
    
    def test_parse_log_message_id_mismatch(self):
        """
        Test handling logs where MessageId doesn't match expected value
        
        Verifies that MessageId validation prevents returning wrong log entries.
        Requirements: 5.3
        """
        expected_message_id = 'expected-123'
        wrong_message_id = 'wrong-456'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': wrong_message_id,  # Wrong MessageId
                    'timestamp': '2026-02-06T23:55:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'Test Carrier',
                    'destination': '+1234567890',
                    'providerResponse': 'Test response'
                },
                'status': 'SUCCESS'
            }),
            'timestamp': 1707264300000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, expected_message_id)
        
        assert result is None, "MessageId mismatch should return None"
    
    def test_parse_log_missing_status_field(self):
        """
        Test handling logs with missing status field
        
        Verifies that missing status defaults to UNKNOWN.
        Requirements: 5.3
        """
        message_id = 'missing-status-789'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-07T00:00:00.000Z'
                },
                'delivery': {
                    'phoneCarrier': 'Test Carrier',
                    'destination': '+1234567890',
                    'providerResponse': 'Test response'
                }
                # status field is missing
            }),
            'timestamp': 1707264600000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'UNKNOWN'  # Default value
        assert result.message_id == message_id
    
    def test_parse_log_optional_fields_missing(self):
        """
        Test parsing logs with optional fields missing
        
        Verifies that optional fields (carrier, price, dwell time) can be None.
        Requirements: 5.3
        """
        message_id = 'optional-fields-123'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': '2026-02-07T00:10:00.000Z'
                },
                'delivery': {
                    # phoneCarrier is missing
                    'destination': '+1234567890',
                    # priceInUSD is missing
                    'smsType': 'Transactional',
                    'providerResponse': 'Test response'
                    # dwellTimeMs is missing
                },
                'status': 'SUCCESS'
            }),
            'timestamp': 1707265200000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'SUCCESS'
        assert result.message_id == message_id
        assert result.phone_carrier is None
        assert result.price_usd is None
        assert result.dwell_time_ms is None
        assert result.provider_response == 'Test response'
    
    def test_parse_log_invalid_timestamp_format(self):
        """
        Test handling logs with invalid timestamp format
        
        Verifies that invalid timestamps default to current time.
        Requirements: 5.3
        """
        message_id = 'invalid-timestamp-456'
        
        log_entry = {
            'message': json.dumps({
                'notification': {
                    'messageId': message_id,
                    'timestamp': 'not-a-valid-timestamp'  # Invalid format
                },
                'delivery': {
                    'phoneCarrier': 'Test Carrier',
                    'destination': '+1234567890',
                    'providerResponse': 'Test response'
                },
                'status': 'SUCCESS'
            }),
            'timestamp': 1707265500000
        }
        
        poller = DeliveryStatusPoller()
        result = poller._parse_log_entry(log_entry, message_id)
        
        assert result is not None
        assert result.status == 'SUCCESS'
        assert result.message_id == message_id
        assert isinstance(result.timestamp, datetime)  # Should still be a datetime


class TestPollerIntegration:
    """Integration tests for the poller with mocked CloudWatch"""
    
    def test_poll_with_immediate_success(self):
        """
        Test polling when log entry is immediately available
        
        Verifies that the poller returns immediately when logs are found.
        """
        message_id = 'immediate-success-123'
        
        mock_logs_client = Mock()
        mock_logs_client.filter_log_events.return_value = {
            'events': [{
                'message': json.dumps({
                    'notification': {
                        'messageId': message_id,
                        'timestamp': '2026-02-07T00:20:00.000Z'
                    },
                    'delivery': {
                        'phoneCarrier': 'Test Carrier',
                        'destination': '+1234567890',
                        'providerResponse': 'Success',
                        'priceInUSD': 0.01
                    },
                    'status': 'SUCCESS'
                }),
                'timestamp': 1707266000000
            }]
        }
        
        poller = DeliveryStatusPoller()
        poller.logs_client = mock_logs_client
        
        result = poller.poll_delivery_status(message_id, max_attempts=3)
        
        assert result.status == 'SUCCESS'
        assert result.message_id == message_id
        # Should only query once since result was immediate
        assert mock_logs_client.filter_log_events.call_count == 1
    
    def test_poll_with_no_results_returns_pending(self):
        """
        Test polling when no log entries are found after all retries
        
        Verifies that PENDING status is returned instead of failing.
        """
        message_id = 'no-results-456'
        
        mock_logs_client = Mock()
        mock_logs_client.filter_log_events.return_value = {'events': []}
        
        poller = DeliveryStatusPoller()
        poller.logs_client = mock_logs_client
        
        # Mock sleep to avoid delays
        from unittest.mock import patch
        with patch('time.sleep'):
            result = poller.poll_delivery_status(message_id, max_attempts=3)
        
        assert result.status == 'PENDING'
        assert result.message_id == message_id
        assert 'not yet available' in result.provider_response.lower()
        # Should query 3 times (max_attempts)
        assert mock_logs_client.filter_log_events.call_count == 3


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
