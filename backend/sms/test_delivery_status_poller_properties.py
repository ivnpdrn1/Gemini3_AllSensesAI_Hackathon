"""
Property-Based Tests for DeliveryStatusPoller

These tests verify universal correctness properties of the CloudWatch log
polling module using property-based testing with Hypothesis.

Feature: colombia-sms-unknown-error-fix
Requirements: 4.2, 5.1, 5.2
Properties: 10, 11
"""

import pytest
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import json
import time

from delivery_status_poller import DeliveryStatusPoller, DeliveryStatus


# Strategy for generating valid MessageIds (UUID format)
message_id_strategy = st.from_regex(
    r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
    fullmatch=True
)

# Strategy for generating delivery statuses
delivery_status_strategy = st.sampled_from(['SUCCESS', 'FAILED', 'PENDING'])

# Strategy for generating provider responses
provider_response_strategy = st.sampled_from([
    'Message delivered successfully',
    'Country not supported',
    'Invalid phone number',
    'Price exceeded',
    'Carrier blocked',
    'Spam detected',
    'Rate limit exceeded'
])


# Feature: colombia-sms-unknown-error-fix, Property 10: Delivery Status Polling
@settings(max_examples=100, deadline=None)
@given(
    message_id=message_id_strategy,
    status=delivery_status_strategy,
    provider_response=provider_response_strategy
)
def test_property_10_delivery_status_polling(message_id, status, provider_response):
    """
    Property 10: Delivery Status Polling
    
    For any SMS send that returns a MessageId, the Lambda SHALL poll 
    CloudWatch logs for delivery status at least once.
    
    Validates: Requirements 4.2, 5.1
    
    This property verifies that:
    1. The poller queries CloudWatch logs when given a MessageId
    2. The poller returns a DeliveryStatus object
    3. The returned status contains the correct MessageId
    4. The poller makes at least one query attempt
    """
    # Create mock CloudWatch logs client
    mock_logs_client = Mock()
    
    # Create mock log entry
    mock_log_entry = {
        'message': json.dumps({
            'notification': {
                'messageId': message_id,
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            },
            'delivery': {
                'phoneCarrier': 'Test Carrier',
                'destination': '+1234567890',
                'priceInUSD': 0.05,
                'smsType': 'Transactional',
                'providerResponse': provider_response,
                'dwellTimeMs': 1234
            },
            'status': status
        }),
        'timestamp': int(datetime.utcnow().timestamp() * 1000)
    }
    
    # Configure mock to return log entry
    mock_logs_client.filter_log_events.return_value = {
        'events': [mock_log_entry]
    }
    
    # Create poller with mocked client
    poller = DeliveryStatusPoller()
    poller.logs_client = mock_logs_client
    
    # Poll for delivery status
    result = poller.poll_delivery_status(message_id, max_attempts=1)
    
    # Verify poller made at least one query
    assert mock_logs_client.filter_log_events.call_count >= 1, \
        "Poller must query CloudWatch logs at least once"
    
    # Verify result is a DeliveryStatus object
    assert isinstance(result, DeliveryStatus), \
        "Poller must return a DeliveryStatus object"
    
    # Verify MessageId matches
    assert result.message_id == message_id, \
        f"Returned MessageId {result.message_id} must match queried MessageId {message_id}"
    
    # Verify status is set
    assert result.status in ['SUCCESS', 'FAILED', 'PENDING'], \
        f"Status must be SUCCESS, FAILED, or PENDING, got {result.status}"
    
    # Verify provider response is captured
    assert result.provider_response is not None, \
        "Provider response must be captured"
    
    # Verify timestamp is set
    assert result.timestamp is not None, \
        "Timestamp must be set"


# Feature: colombia-sms-unknown-error-fix, Property 11: Polling Retry with Exponential Backoff
@settings(max_examples=100, deadline=None)
@given(
    message_id=message_id_strategy,
    max_attempts=st.integers(min_value=1, max_value=5)
)
def test_property_11_polling_retry_exponential_backoff(message_id, max_attempts):
    """
    Property 11: Polling Retry with Exponential Backoff
    
    For any CloudWatch query that returns no results, the system SHALL retry 
    up to 3 times with exponential backoff (2s, 4s, 8s).
    
    Validates: Requirements 5.2
    
    This property verifies that:
    1. The poller retries when no results are found
    2. The number of retries does not exceed max_attempts
    3. Backoff time increases exponentially between retries
    4. The poller eventually returns PENDING status if no results found
    """
    # Create mock CloudWatch logs client that returns no results
    mock_logs_client = Mock()
    mock_logs_client.filter_log_events.return_value = {'events': []}
    
    # Create poller with mocked client
    poller = DeliveryStatusPoller()
    poller.logs_client = mock_logs_client
    
    # Track sleep calls to verify exponential backoff
    sleep_times = []
    original_sleep = time.sleep
    
    def mock_sleep(seconds):
        sleep_times.append(seconds)
        # Don't actually sleep in tests
        pass
    
    with patch('time.sleep', side_effect=mock_sleep):
        # Poll for delivery status (will retry and fail)
        result = poller.poll_delivery_status(
            message_id,
            max_attempts=max_attempts,
            initial_backoff_seconds=2
        )
    
    # Verify retry count does not exceed max_attempts
    assert mock_logs_client.filter_log_events.call_count == max_attempts, \
        f"Poller must make exactly {max_attempts} attempts, made {mock_logs_client.filter_log_events.call_count}"
    
    # Verify exponential backoff (only if retries occurred)
    if max_attempts > 1:
        expected_sleep_count = max_attempts - 1  # Sleep between attempts
        assert len(sleep_times) == expected_sleep_count, \
            f"Expected {expected_sleep_count} sleep calls, got {len(sleep_times)}"
        
        # Verify exponential backoff pattern (2s, 4s, 8s, ...)
        for i, sleep_time in enumerate(sleep_times):
            expected_sleep = 2 * (2 ** i)  # 2, 4, 8, 16, ...
            assert sleep_time == expected_sleep, \
                f"Sleep time at retry {i+1} should be {expected_sleep}s, got {sleep_time}s"
    
    # Verify result is PENDING when no logs found
    assert result.status == 'PENDING', \
        f"Status must be PENDING when no logs found, got {result.status}"
    
    # Verify MessageId is preserved
    assert result.message_id == message_id, \
        f"MessageId must be preserved in PENDING status"
    
    # Verify provider response indicates pending status
    assert 'not yet available' in result.provider_response.lower(), \
        "Provider response must indicate delivery status is pending"


# Feature: colombia-sms-unknown-error-fix, Property 12: Error Extraction from FAILED Status
@settings(max_examples=100, deadline=None)
@given(
    message_id=message_id_strategy,
    provider_response=provider_response_strategy
)
def test_property_12_error_extraction_from_failed_status(message_id, provider_response):
    """
    Property 12: Error Extraction from FAILED Status
    
    For any delivery status showing FAILED, the system SHALL extract the 
    providerResponse field and translate it to a user-friendly error.
    
    Validates: Requirements 5.3
    
    This property verifies that:
    1. FAILED status logs are parsed correctly
    2. providerResponse field is extracted
    3. The extracted response is non-empty
    4. The response is available for error translation
    """
    # Create mock CloudWatch logs client
    mock_logs_client = Mock()
    
    # Create mock log entry with FAILED status
    mock_log_entry = {
        'message': json.dumps({
            'notification': {
                'messageId': message_id,
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            },
            'delivery': {
                'phoneCarrier': 'Test Carrier',
                'destination': '+1234567890',
                'priceInUSD': 0.05,
                'smsType': 'Transactional',
                'providerResponse': provider_response,
                'dwellTimeMs': 1234
            },
            'status': 'FAILED'
        }),
        'timestamp': int(datetime.utcnow().timestamp() * 1000)
    }
    
    # Configure mock to return log entry
    mock_logs_client.filter_log_events.return_value = {
        'events': [mock_log_entry]
    }
    
    # Create poller with mocked client
    poller = DeliveryStatusPoller()
    poller.logs_client = mock_logs_client
    
    # Poll for delivery status
    result = poller.poll_delivery_status(message_id, max_attempts=1)
    
    # Verify status is FAILED
    assert result.status == 'FAILED', \
        f"Status must be FAILED, got {result.status}"
    
    # Verify providerResponse is extracted
    assert result.provider_response is not None, \
        "Provider response must be extracted from FAILED status"
    
    # Verify providerResponse is non-empty
    assert len(result.provider_response) > 0, \
        "Provider response must be non-empty for FAILED status"
    
    # Verify providerResponse matches the log entry
    assert result.provider_response == provider_response, \
        f"Provider response {result.provider_response} must match log entry {provider_response}"
    
    # Verify MessageId is preserved
    assert result.message_id == message_id, \
        "MessageId must be preserved in FAILED status"


# Edge case: Empty MessageId
def test_empty_message_id_raises_error():
    """
    Test that empty MessageId raises ValueError
    
    This is an edge case test to ensure the poller validates input.
    """
    poller = DeliveryStatusPoller()
    
    with pytest.raises(ValueError, match="message_id cannot be empty"):
        poller.poll_delivery_status("", max_attempts=1)


# Edge case: CloudWatch query exception
@settings(max_examples=50, deadline=None)
@given(message_id=message_id_strategy)
def test_cloudwatch_query_exception_handling(message_id):
    """
    Test that CloudWatch query exceptions are handled gracefully
    
    This verifies that the poller retries on exceptions and eventually
    raises an exception if all retries fail.
    """
    # Create mock CloudWatch logs client that raises exception
    mock_logs_client = Mock()
    mock_logs_client.filter_log_events.side_effect = Exception("CloudWatch unavailable")
    
    # Create poller with mocked client
    poller = DeliveryStatusPoller()
    poller.logs_client = mock_logs_client
    
    # Mock sleep to avoid delays
    with patch('time.sleep'):
        # Poll should raise exception after retries
        with pytest.raises(Exception, match="CloudWatch query failed"):
            poller.poll_delivery_status(message_id, max_attempts=3)
    
    # Verify all retries were attempted
    assert mock_logs_client.filter_log_events.call_count == 3, \
        "Poller must retry 3 times before raising exception"


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
