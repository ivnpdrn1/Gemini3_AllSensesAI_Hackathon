"""
Error Code Translation Module for SMS Delivery

This module translates SNS and carrier error codes to user-friendly messages
with actionable remediation steps. It distinguishes between AWS-level errors
(e.g., invalid phone format) and carrier-level errors (e.g., carrier blocked).

Requirements: 2.1, 2.2, 2.4, 2.5
Properties: 4, 5
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class ErrorTranslation:
    """
    Represents translated error information
    
    Attributes:
        error_code: Machine-readable code (e.g., "COUNTRY_NOT_SUPPORTED")
        user_message: Human-readable message for display
        remediation: Actionable steps to fix the issue
        original_response: Original carrier response for debugging
        error_level: "AWS" or "CARRIER" indicating error source
    """
    error_code: str
    user_message: str
    remediation: str
    original_response: str
    error_level: str = "CARRIER"


class ErrorCodeTranslator:
    """
    Translates SNS/carrier error codes to user-friendly messages
    
    This class maintains a mapping of common error codes to user-friendly
    messages and remediation steps. It classifies errors as AWS-level or
    carrier-level to help with troubleshooting.
    
    Requirements: 2.1, 2.2, 2.4, 2.5
    """
    
    # Error code mapping with user messages and remediation steps
    ERROR_CODE_MAP = {
        "Country not supported": {
            "user_message": "Colombia SMS not enabled for this AWS account",
            "remediation": "Submit AWS support ticket to enable Colombia SMS",
            "error_code": "COUNTRY_NOT_SUPPORTED",
            "error_level": "AWS"
        },
        "Invalid phone number": {
            "user_message": "Phone number format is invalid",
            "remediation": "Use E.164 format: +573222063010",
            "error_code": "INVALID_PHONE_FORMAT",
            "error_level": "AWS"
        },
        "Price exceeded": {
            "user_message": "SMS cost exceeds maximum price limit",
            "remediation": "Increase MaxPrice to $1.00 in Lambda configuration",
            "error_code": "PRICE_EXCEEDED",
            "error_level": "AWS"
        },
        "Carrier blocked": {
            "user_message": "Colombia carrier rejected the message",
            "remediation": "Contact carrier for sender registration",
            "error_code": "CARRIER_BLOCKED",
            "error_level": "CARRIER"
        },
        "Spam detected": {
            "user_message": "Message flagged as spam by carrier",
            "remediation": "Modify message content to avoid spam triggers",
            "error_code": "SPAM_DETECTED",
            "error_level": "CARRIER"
        },
        "Rate limit exceeded": {
            "user_message": "Too many SMS messages sent in a short time",
            "remediation": "Wait 60 seconds and retry",
            "error_code": "RATE_LIMIT_EXCEEDED",
            "error_level": "AWS"
        },
        "Blocked as spam": {
            "user_message": "Message content flagged as spam",
            "remediation": "Modify message to remove spam-like content",
            "error_code": "SPAM_DETECTED",
            "error_level": "CARRIER"
        },
        "Destination unreachable": {
            "user_message": "Phone number is unreachable or invalid",
            "remediation": "Verify phone number is correct and active",
            "error_code": "DESTINATION_UNREACHABLE",
            "error_level": "CARRIER"
        },
        "Message too long": {
            "user_message": "SMS message exceeds maximum length",
            "remediation": "Shorten message to 160 characters or less",
            "error_code": "MESSAGE_TOO_LONG",
            "error_level": "AWS"
        },
        "Invalid sender ID": {
            "user_message": "Sender ID is not registered or invalid",
            "remediation": "Register sender ID with carrier or use default",
            "error_code": "INVALID_SENDER_ID",
            "error_level": "CARRIER"
        }
    }
    
    def translate_error(
        self,
        provider_response: str,
        status: str
    ) -> ErrorTranslation:
        """
        Translate carrier error to user-friendly message
        
        This method looks up the provider response in the ERROR_CODE_MAP and
        returns a structured error translation with user message, remediation
        steps, and error classification.
        
        Args:
            provider_response: Raw carrier response from CloudWatch
            status: Delivery status ("SUCCESS" or "FAILED")
            
        Returns:
            ErrorTranslation with user_message, remediation, error_code, and error_level
            
        Requirements: 2.1, 2.2, 2.4, 2.5
        Properties: 4, 5
        """
        print(f'[TRANSLATOR] Translating error: "{provider_response}" (status: {status})')
        
        # Handle None provider_response
        if provider_response is None:
            provider_response = "No provider response"
        
        # Handle SUCCESS status (no error)
        if status == "SUCCESS":
            return ErrorTranslation(
                error_code="SUCCESS",
                user_message="SMS delivered successfully",
                remediation="No action needed",
                original_response=provider_response,
                error_level="NONE"
            )
        
        # Handle PENDING status (logs not yet available)
        if status == "PENDING":
            return ErrorTranslation(
                error_code="PENDING",
                user_message="SMS delivery status pending",
                remediation="Check CloudWatch logs in a few minutes for delivery status",
                original_response=provider_response,
                error_level="NONE"
            )
        
        # Look up error in ERROR_CODE_MAP
        # Try exact match first
        if provider_response in self.ERROR_CODE_MAP:
            error_info = self.ERROR_CODE_MAP[provider_response]
            print(f'[TRANSLATOR] ✅ Found exact match: {error_info["error_code"]}')
            
            return ErrorTranslation(
                error_code=error_info["error_code"],
                user_message=error_info["user_message"],
                remediation=error_info["remediation"],
                original_response=provider_response,
                error_level=error_info["error_level"]
            )
        
        # Try partial match (case-insensitive)
        provider_response_lower = provider_response.lower()
        for key, error_info in self.ERROR_CODE_MAP.items():
            if key.lower() in provider_response_lower:
                print(f'[TRANSLATOR] ✅ Found partial match: {error_info["error_code"]}')
                
                return ErrorTranslation(
                    error_code=error_info["error_code"],
                    user_message=error_info["user_message"],
                    remediation=error_info["remediation"],
                    original_response=provider_response,
                    error_level=error_info["error_level"]
                )
        
        # No match found - return fallback error
        print(f'[TRANSLATOR] ⚠️ No match found, using fallback error')
        
        return ErrorTranslation(
            error_code="UNKNOWN_ERROR",
            user_message=f"SMS delivery failed: {provider_response}",
            remediation="Check CloudWatch logs for details or contact AWS support",
            original_response=provider_response,
            error_level="UNKNOWN"
        )
    
    def is_transient_error(self, error_code: str) -> bool:
        """
        Determine if an error is transient (can be retried)
        
        Transient errors are temporary issues that may resolve on retry:
        - RATE_LIMIT_EXCEEDED: Too many messages, wait and retry
        - DESTINATION_UNREACHABLE: Network issue, may resolve
        
        Permanent errors should not be retried:
        - COUNTRY_NOT_SUPPORTED: AWS account not approved
        - INVALID_PHONE_FORMAT: Phone number is invalid
        - CARRIER_BLOCKED: Carrier has blocked sender
        - SPAM_DETECTED: Message content flagged as spam
        - PRICE_EXCEEDED: MaxPrice too low
        
        Args:
            error_code: Machine-readable error code
            
        Returns:
            True if error is transient and can be retried, False otherwise
            
        Requirements: 8.1, 8.5
        """
        transient_errors = {
            "RATE_LIMIT_EXCEEDED",
            "DESTINATION_UNREACHABLE"
        }
        
        return error_code in transient_errors
    
    def classify_error_level(self, error_code: str) -> str:
        """
        Classify error as AWS-level or carrier-level
        
        AWS-level errors occur before the message reaches the carrier:
        - INVALID_PHONE_FORMAT
        - PRICE_EXCEEDED
        - RATE_LIMIT_EXCEEDED
        - MESSAGE_TOO_LONG
        - COUNTRY_NOT_SUPPORTED
        
        Carrier-level errors occur at the carrier:
        - CARRIER_BLOCKED
        - SPAM_DETECTED
        - DESTINATION_UNREACHABLE
        - INVALID_SENDER_ID
        
        Args:
            error_code: Machine-readable error code
            
        Returns:
            "AWS" or "CARRIER" indicating error source
            
        Requirements: 2.5
        Property: 5
        """
        # Find error in ERROR_CODE_MAP
        for key, error_info in self.ERROR_CODE_MAP.items():
            if error_info["error_code"] == error_code:
                return error_info["error_level"]
        
        # Unknown error - classify as UNKNOWN
        return "UNKNOWN"
