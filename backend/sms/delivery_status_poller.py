"""
CloudWatch Log Polling Module for SMS Delivery Status

This module queries CloudWatch logs for SNS SMS delivery status and extracts
carrier error codes and responses. It implements retry logic with exponential
backoff to handle the delay between SNS accepting a message and CloudWatch
logs appearing.

Requirements: 5.1, 5.2, 5.3
Properties: 10, 11, 12
"""

import boto3
import time
import json
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional


@dataclass
class DeliveryStatus:
    """
    Represents SMS delivery status from CloudWatch logs
    
    Attributes:
        status: Delivery status ("SUCCESS" or "FAILED")
        message_id: SNS MessageId
        provider_response: Raw carrier response from CloudWatch
        timestamp: When the delivery attempt occurred
        phone_carrier: Carrier name (optional)
        price_usd: Cost of SMS in USD (optional)
        dwell_time_ms: Time to deliver in milliseconds (optional)
    """
    status: str
    message_id: str
    provider_response: str
    timestamp: datetime
    phone_carrier: Optional[str] = None
    price_usd: Optional[float] = None
    dwell_time_ms: Optional[int] = None


class DeliveryStatusPoller:
    """
    Polls CloudWatch logs for SMS delivery status
    
    This class queries the SNS DirectPublish log group for delivery status
    entries and extracts carrier error codes and responses. It implements
    retry logic with exponential backoff to handle CloudWatch log delays.
    
    Requirements: 5.1, 5.2, 5.3
    """
    
    # CloudWatch log group for SNS SMS delivery
    LOG_GROUP_NAME = 'sns/us-east-1/794289527784/DirectPublish'
    
    def __init__(self, region_name='us-east-1'):
        """
        Initialize CloudWatch Logs client
        
        Args:
            region_name: AWS region (default: us-east-1)
        """
        self.logs_client = boto3.client('logs', region_name=region_name)
        self.region_name = region_name
    
    def poll_delivery_status(
        self,
        message_id: str,
        max_attempts: int = 3,
        initial_backoff_seconds: int = 2
    ) -> DeliveryStatus:
        """
        Poll CloudWatch logs for delivery status with retry logic
        
        This method queries CloudWatch logs for the delivery status of an SMS
        message. It retries up to max_attempts times with exponential backoff
        if the log entry is not immediately available.
        
        Args:
            message_id: SNS MessageId to query
            max_attempts: Maximum polling attempts (default: 3)
            initial_backoff_seconds: Initial backoff between attempts (default: 2s)
            
        Returns:
            DeliveryStatus with status, error_code, and error_message
            
        Raises:
            ValueError: If message_id is empty or invalid
            Exception: If CloudWatch query fails after all retries
            
        Requirements: 5.1, 5.2, 5.3
        Properties: 10, 11
        """
        if not message_id:
            raise ValueError("message_id cannot be empty")
        
        print(f'[POLLER] Polling delivery status for MessageId: {message_id}')
        print(f'[POLLER] Max attempts: {max_attempts}, Initial backoff: {initial_backoff_seconds}s')
        
        # Calculate time range for log query (last 10 minutes)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=10)
        
        # Convert to milliseconds since epoch (CloudWatch format)
        start_time_ms = int(start_time.timestamp() * 1000)
        end_time_ms = int(end_time.timestamp() * 1000)
        
        backoff_seconds = initial_backoff_seconds
        
        for attempt in range(1, max_attempts + 1):
            print(f'[POLLER] Attempt {attempt}/{max_attempts}')
            
            try:
                # Query CloudWatch logs for this MessageId
                response = self.logs_client.filter_log_events(
                    logGroupName=self.LOG_GROUP_NAME,
                    startTime=start_time_ms,
                    endTime=end_time_ms,
                    filterPattern=f'"{message_id}"'
                )
                
                events = response.get('events', [])
                print(f'[POLLER] Found {len(events)} log events')
                
                if events:
                    # Parse the first matching log entry
                    log_entry = events[0]
                    delivery_status = self._parse_log_entry(log_entry, message_id)
                    
                    if delivery_status:
                        print(f'[POLLER] ✅ Found delivery status: {delivery_status.status}')
                        return delivery_status
                
                # No results yet - retry with exponential backoff
                if attempt < max_attempts:
                    print(f'[POLLER] No results yet, waiting {backoff_seconds}s before retry...')
                    time.sleep(backoff_seconds)
                    backoff_seconds *= 2  # Exponential backoff (2s, 4s, 8s)
                
            except Exception as e:
                print(f'[POLLER] CloudWatch query error on attempt {attempt}: {str(e)}')
                
                if attempt < max_attempts:
                    print(f'[POLLER] Retrying in {backoff_seconds}s...')
                    time.sleep(backoff_seconds)
                    backoff_seconds *= 2
                else:
                    # All retries exhausted
                    raise Exception(f'CloudWatch query failed after {max_attempts} attempts: {str(e)}')
        
        # No delivery status found after all retries
        print(f'[POLLER] ⚠️ No delivery status found after {max_attempts} attempts')
        
        # Return PENDING status instead of failing
        return DeliveryStatus(
            status='PENDING',
            message_id=message_id,
            provider_response='Delivery status not yet available in CloudWatch logs',
            timestamp=datetime.utcnow()
        )
    
    def _parse_log_entry(self, log_entry: dict, message_id: str) -> Optional[DeliveryStatus]:
        """
        Parse CloudWatch log entry to extract delivery status
        
        CloudWatch log format:
        {
          "notification": {
            "messageId": "05f4ef3-a91f-153a-d224-9c7d9a2ae9a3",
            "timestamp": "2026-02-06T22:51:41.655Z"
          },
          "delivery": {
            "phoneCarrier": "Claro Colombia",
            "destination": "+573227863818",
            "priceInUSD": 0.05,
            "smsType": "Transactional",
            "providerResponse": "Country not supported",
            "dwellTimeMs": 1234
          },
          "status": "FAILED"
        }
        
        Args:
            log_entry: CloudWatch log event
            message_id: Expected MessageId
            
        Returns:
            DeliveryStatus if parsing succeeds, None otherwise
            
        Requirements: 5.3
        Property: 12
        """
        try:
            message = log_entry.get('message', '')
            
            # Parse JSON log message
            log_data = json.loads(message)
            
            # Extract fields
            notification = log_data.get('notification', {})
            delivery = log_data.get('delivery', {})
            status = log_data.get('status', 'UNKNOWN')
            
            # Validate MessageId matches
            log_message_id = notification.get('messageId', '')
            if log_message_id != message_id:
                print(f'[POLLER] MessageId mismatch: expected {message_id}, got {log_message_id}')
                return None
            
            # Extract timestamp
            timestamp_str = notification.get('timestamp', '')
            try:
                timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            except:
                timestamp = datetime.utcnow()
            
            # Extract delivery details
            provider_response = delivery.get('providerResponse', 'No provider response')
            phone_carrier = delivery.get('phoneCarrier')
            price_usd = delivery.get('priceInUSD')
            dwell_time_ms = delivery.get('dwellTimeMs')
            
            print(f'[POLLER] Parsed log entry:')
            print(f'[POLLER]   Status: {status}')
            print(f'[POLLER]   Provider Response: {provider_response}')
            print(f'[POLLER]   Carrier: {phone_carrier}')
            print(f'[POLLER]   Price: ${price_usd}')
            
            return DeliveryStatus(
                status=status,
                message_id=message_id,
                provider_response=provider_response,
                timestamp=timestamp,
                phone_carrier=phone_carrier,
                price_usd=price_usd,
                dwell_time_ms=dwell_time_ms
            )
            
        except json.JSONDecodeError as e:
            print(f'[POLLER] Failed to parse log entry as JSON: {str(e)}')
            print(f'[POLLER] Log message: {log_entry.get("message", "")}')
            return None
            
        except Exception as e:
            print(f'[POLLER] Error parsing log entry: {str(e)}')
            return None
