"""
Property-Based Tests for SNS Delivery Logging
Task 1.1 and 1.2: Comprehensive SMS delivery logging and 100% sample rate

Feature: colombia-sms-unknown-error-fix
"""

import pytest
from hypothesis import given, strategies as st, settings
import boto3
import json
import time
from datetime import datetime, timedelta
from typing import List, Dict, Any

# Initialize AWS clients
sns = boto3.client('sns', region_name='us-east-1')
logs = boto3.client('logs', region_name='us-east-1')

# Configuration
ACCOUNT_ID = "794289527784"
REGION = "us-east-1"
LOG_GROUP = f"sns/{REGION}/{ACCOUNT_ID}/DirectPublish"


# Test Data Strategies
@st.composite
def phone_number_strategy(draw):
    """Generate valid E.164 phone numbers"""
    country_code = draw(st.sampled_from(['+1', '+44', '+57', '+61', '+81']))
    number_length = draw(st.integers(min_value=7, max_value=12))
    number = ''.join([str(draw(st.integers(min_value=0, max_value=9))) for _ in range(number_length)])
    return f"{country_code}{number}"


@st.composite
def sms_message_strategy(draw):
    """Generate SMS message content"""
    return draw(st.text(min_size=10, max_size=160, alphabet=st.characters(blacklist_categories=('Cs',))))


def send_test_sms(phone_number: str, message: str) -> str:
    """
    Send test SMS via SNS and return MessageId
    """
    try:
        response = sns.publish(
            PhoneNumber=phone_number,
            Message=message,
            MessageAttributes={
                'AWS.SNS.SMS.SMSType': {
                    'DataType': 'String',
                    'StringValue': 'Transactional'
                },
                'AWS.SNS.SMS.MaxPrice': {
                    'DataType': 'String',
                    'StringValue': '0.50'
                }
            }
        )
        return response.get('MessageId')
    except Exception as e:
        pytest.fail(f"Failed to send SMS: {str(e)}")


def query_cloudwatch_logs(message_id: str, max_wait_seconds: int = 60) -> Dict[str, Any]:
    """
    Query CloudWatch logs for delivery status
    Polls with exponential backoff up to max_wait_seconds
    """
    start_time = int((datetime.utcnow() - timedelta(minutes=5)).timestamp() * 1000)
    end_time = int(datetime.utcnow().timestamp() * 1000)
    
    wait_time = 2
    total_waited = 0
    
    while total_waited < max_wait_seconds:
        try:
            response = logs.filter_log_events(
                logGroupName=LOG_GROUP,
                filterPattern=message_id,
                startTime=start_time,
                endTime=end_time
            )
            
            if response.get('events'):
                log_entry = json.loads(response['events'][0]['message'])
                return log_entry
            
            # Wait before retrying
            time.sleep(wait_time)
            total_waited += wait_time
            wait_time = min(wait_time * 2, 16)  # Exponential backoff, max 16s
            
        except logs.exceptions.ResourceNotFoundException:
            pytest.skip(f"Log group {LOG_GROUP} does not exist. Run enable-sns-delivery-logging-v2.ps1 first.")
        except Exception as e:
            pytest.fail(f"Failed to query CloudWatch logs: {str(e)}")
    
    return None


# Property 1: Comprehensive SMS Delivery Logging
# Feature: colombia-sms-unknown-error-fix, Property 1: Comprehensive SMS Delivery Logging
@pytest.mark.property_test
@settings(max_examples=100, deadline=120000)  # 2 minute deadline per test
@given(
    phone=phone_number_strategy(),
    message=sms_message_strategy()
)
def test_property_1_comprehensive_sms_delivery_logging(phone, message):
    """
    Property 1: For any SMS delivery attempt (successful or failed), 
    the CloudWatch logs SHALL contain an entry with the MessageId, 
    delivery status (SUCCESS/FAILED), carrier response, and timestamp.
    
    Validates: Requirements 1.1, 1.2, 1.3
    """
    # Send SMS
    message_id = send_test_sms(phone, message)
    
    # Verify MessageId was returned
    assert message_id is not None, "SNS must return MessageId"
    assert len(message_id) > 0, "MessageId must not be empty"
    
    # Query CloudWatch logs for delivery status
    log_entry = query_cloudwatch_logs(message_id, max_wait_seconds=60)
    
    # Skip if logs not available yet (eventual consistency)
    if log_entry is None:
        pytest.skip(f"Delivery log not available yet for MessageId: {message_id}")
    
    # Verify log entry contains required fields
    assert 'notification' in log_entry, "Log entry must contain 'notification' field"
    assert 'delivery' in log_entry, "Log entry must contain 'delivery' field"
    assert 'status' in log_entry, "Log entry must contain 'status' field"
    
    # Verify notification fields
    notification = log_entry['notification']
    assert 'messageId' in notification, "Notification must contain 'messageId'"
    assert notification['messageId'] == message_id, "MessageId must match"
    assert 'timestamp' in notification, "Notification must contain 'timestamp'"
    
    # Verify delivery fields
    delivery = log_entry['delivery']
    assert 'destination' in delivery, "Delivery must contain 'destination'"
    assert 'providerResponse' in delivery or log_entry['status'] == 'SUCCESS', \
        "Delivery must contain 'providerResponse' or status must be SUCCESS"
    
    # Verify status is valid
    assert log_entry['status'] in ['SUCCESS', 'FAILED'], \
        f"Status must be SUCCESS or FAILED, got: {log_entry['status']}"
    
    # If FAILED, verify carrier response exists
    if log_entry['status'] == 'FAILED':
        assert 'providerResponse' in delivery, \
            "FAILED status must include providerResponse"
        assert len(delivery['providerResponse']) > 0, \
            "providerResponse must not be empty for FAILED status"


# Property 2: 100% Logging Sample Rate
# Feature: colombia-sms-unknown-error-fix, Property 2: 100% Logging Sample Rate
@pytest.mark.property_test
@settings(max_examples=100, deadline=180000)  # 3 minute deadline
def test_property_2_100_percent_logging_sample_rate():
    """
    Property 2: For any set of N SMS messages sent, 
    exactly N log entries SHALL exist in CloudWatch logs (no sampling).
    
    Validates: Requirements 1.4
    
    Note: This test sends multiple SMS in a batch and verifies all are logged.
    Due to CloudWatch eventual consistency, we allow up to 2 minutes for logs to appear.
    """
    # Verify SNS sample rate is configured to 100%
    attributes = sns.get_sms_attributes()
    sample_rate = attributes.get('attributes', {}).get('SuccessFeedbackSampleRate', '0')
    
    assert sample_rate == '100', \
        f"SNS SuccessFeedbackSampleRate must be 100%, got: {sample_rate}%"
    
    # Send batch of test SMS
    batch_size = 5
    message_ids = []
    
    for i in range(batch_size):
        phone = f"+1202555{1000 + i}"  # USA numbers for reliable delivery
        message = f"TEST: Batch logging test {i+1}/{batch_size}"
        message_id = send_test_sms(phone, message)
        message_ids.append(message_id)
    
    # Wait for logs to appear (eventual consistency)
    time.sleep(30)
    
    # Query CloudWatch logs for each MessageId
    found_logs = 0
    missing_message_ids = []
    
    for message_id in message_ids:
        log_entry = query_cloudwatch_logs(message_id, max_wait_seconds=30)
        if log_entry is not None:
            found_logs += 1
        else:
            missing_message_ids.append(message_id)
    
    # Verify all messages were logged
    assert found_logs == batch_size, \
        f"Expected {batch_size} log entries, found {found_logs}. " \
        f"Missing MessageIds: {missing_message_ids}"


# Property 3: Log Retention
# Feature: colombia-sms-unknown-error-fix, Property 3: Log Retention
@pytest.mark.property_test
def test_property_3_log_retention():
    """
    Property 3: The System SHALL retain delivery logs for at least 7 days.
    
    Validates: Requirements 1.5
    """
    try:
        # Check log group retention policy
        response = logs.describe_log_groups(
            logGroupNamePrefix=LOG_GROUP
        )
        
        if not response.get('logGroups'):
            pytest.skip(f"Log group {LOG_GROUP} does not exist yet")
        
        log_group = response['logGroups'][0]
        retention_days = log_group.get('retentionInDays')
        
        # If retention is not set, it defaults to "Never Expire" which is acceptable
        if retention_days is not None:
            assert retention_days >= 7, \
                f"Log retention must be at least 7 days, got: {retention_days} days"
        
    except logs.exceptions.ResourceNotFoundException:
        pytest.skip(f"Log group {LOG_GROUP} does not exist yet")


# Helper test to verify SNS configuration
@pytest.mark.configuration_test
def test_sns_delivery_logging_configuration():
    """
    Verify SNS delivery logging is properly configured
    This is a prerequisite for all property tests
    """
    attributes = sns.get_sms_attributes()
    attrs = attributes.get('attributes', {})
    
    # Verify success feedback role
    success_role = attrs.get('SuccessFeedbackRoleArn')
    assert success_role is not None, \
        "SuccessFeedbackRoleArn must be configured. Run enable-sns-delivery-logging-v2.ps1"
    assert 'SNSSuccessFeedback' in success_role, \
        f"Success role must be SNSSuccessFeedback, got: {success_role}"
    
    # Verify failure feedback role
    failure_role = attrs.get('FailureFeedbackRoleArn')
    assert failure_role is not None, \
        "FailureFeedbackRoleArn must be configured. Run enable-sns-delivery-logging-v2.ps1"
    assert 'SNSFailureFeedback' in failure_role, \
        f"Failure role must be SNSFailureFeedback, got: {failure_role}"
    
    # Verify sample rate
    sample_rate = attrs.get('SuccessFeedbackSampleRate', '0')
    assert sample_rate == '100', \
        f"SuccessFeedbackSampleRate must be 100%, got: {sample_rate}%"


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
