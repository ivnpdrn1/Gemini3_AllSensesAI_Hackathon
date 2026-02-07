"""
Unit Tests for Error Code Translator

This module contains unit tests for the ErrorCodeTranslator class.
Unit tests verify specific examples, edge cases, and error conditions.

Requirements: 2.2, 2.3
"""

import pytest
from error_code_translator import ErrorCodeTranslator, ErrorTranslation


class TestErrorCodeTranslator:
    """Unit tests for ErrorCodeTranslator class"""
    
    def setup_method(self):
        """Setup test fixtures"""
        self.translator = ErrorCodeTranslator()
    
    # Test specific error code translations
    
    def test_country_not_supported_translation(self):
        """
        Test "Country not supported" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Country not supported", "FAILED")
        
        assert translation.error_code == "COUNTRY_NOT_SUPPORTED"
        assert "Colombia SMS not enabled" in translation.user_message
        assert "AWS support ticket" in translation.remediation
        assert translation.error_level == "AWS"
        assert translation.original_response == "Country not supported"
        
        print('✅ Country not supported → COUNTRY_NOT_SUPPORTED')
    
    def test_invalid_phone_number_translation(self):
        """
        Test "Invalid phone number" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Invalid phone number", "FAILED")
        
        assert translation.error_code == "INVALID_PHONE_FORMAT"
        assert "Phone number format is invalid" in translation.user_message
        assert "E.164 format" in translation.remediation
        assert translation.error_level == "AWS"
        assert translation.original_response == "Invalid phone number"
        
        print('✅ Invalid phone number → INVALID_PHONE_FORMAT')
    
    def test_price_exceeded_translation(self):
        """
        Test "Price exceeded" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Price exceeded", "FAILED")
        
        assert translation.error_code == "PRICE_EXCEEDED"
        assert "SMS cost exceeds maximum price limit" in translation.user_message
        assert "Increase MaxPrice" in translation.remediation
        assert translation.error_level == "AWS"
        assert translation.original_response == "Price exceeded"
        
        print('✅ Price exceeded → PRICE_EXCEEDED')
    
    def test_carrier_blocked_translation(self):
        """
        Test "Carrier blocked" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Carrier blocked", "FAILED")
        
        assert translation.error_code == "CARRIER_BLOCKED"
        assert "Colombia carrier rejected" in translation.user_message
        assert "Contact carrier" in translation.remediation
        assert translation.error_level == "CARRIER"
        assert translation.original_response == "Carrier blocked"
        
        print('✅ Carrier blocked → CARRIER_BLOCKED')
    
    def test_spam_detected_translation(self):
        """
        Test "Spam detected" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Spam detected", "FAILED")
        
        assert translation.error_code == "SPAM_DETECTED"
        assert "Message flagged as spam" in translation.user_message
        assert "Modify message content" in translation.remediation
        assert translation.error_level == "CARRIER"
        assert translation.original_response == "Spam detected"
        
        print('✅ Spam detected → SPAM_DETECTED')
    
    def test_rate_limit_exceeded_translation(self):
        """
        Test "Rate limit exceeded" error translation
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Rate limit exceeded", "FAILED")
        
        assert translation.error_code == "RATE_LIMIT_EXCEEDED"
        assert "Too many SMS messages" in translation.user_message
        assert "Wait 60 seconds" in translation.remediation
        assert translation.error_level == "AWS"
        assert translation.original_response == "Rate limit exceeded"
        
        print('✅ Rate limit exceeded → RATE_LIMIT_EXCEEDED')
    
    # Test unknown error fallback
    
    def test_unknown_error_fallback(self):
        """
        Test unknown error returns fallback message
        
        Validates: Requirements 2.3
        """
        unknown_response = "Some unknown carrier error"
        translation = self.translator.translate_error(unknown_response, "FAILED")
        
        assert translation.error_code == "UNKNOWN_ERROR"
        assert unknown_response in translation.user_message
        assert "CloudWatch logs" in translation.remediation
        assert translation.error_level == "UNKNOWN"
        assert translation.original_response == unknown_response
        
        print('✅ Unknown error → UNKNOWN_ERROR with fallback')
    
    def test_empty_provider_response_fallback(self):
        """
        Test empty provider response returns fallback message
        
        Validates: Requirements 2.3
        """
        translation = self.translator.translate_error("", "FAILED")
        
        assert translation.error_code == "UNKNOWN_ERROR"
        assert "SMS delivery failed" in translation.user_message
        assert "CloudWatch logs" in translation.remediation
        assert translation.error_level == "UNKNOWN"
        
        print('✅ Empty provider response → UNKNOWN_ERROR')
    
    # Test partial matching
    
    def test_partial_match_case_insensitive(self):
        """
        Test partial matching with case insensitivity
        
        For example, "COUNTRY NOT SUPPORTED" should match "Country not supported"
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("COUNTRY NOT SUPPORTED", "FAILED")
        
        assert translation.error_code == "COUNTRY_NOT_SUPPORTED"
        assert "Colombia SMS not enabled" in translation.user_message
        
        print('✅ Partial match (case insensitive) works')
    
    def test_partial_match_with_extra_text(self):
        """
        Test partial matching with extra text
        
        For example, "Error: Carrier blocked by network" should match "Carrier blocked"
        
        Validates: Requirements 2.2
        """
        translation = self.translator.translate_error("Error: Carrier blocked by network", "FAILED")
        
        assert translation.error_code == "CARRIER_BLOCKED"
        assert "Colombia carrier rejected" in translation.user_message
        
        print('✅ Partial match with extra text works')
    
    # Test SUCCESS and PENDING status handling
    
    def test_success_status_handling(self):
        """
        Test SUCCESS status returns success message
        
        Validates: Requirements 5.4
        """
        translation = self.translator.translate_error("Message delivered", "SUCCESS")
        
        assert translation.error_code == "SUCCESS"
        assert "successfully" in translation.user_message.lower()
        assert "no action" in translation.remediation.lower()
        assert translation.error_level == "NONE"
        
        print('✅ SUCCESS status → SUCCESS code')
    
    def test_pending_status_handling(self):
        """
        Test PENDING status returns pending message
        
        Validates: Requirements 5.5
        """
        translation = self.translator.translate_error("Delivery status not yet available", "PENDING")
        
        assert translation.error_code == "PENDING"
        assert "pending" in translation.user_message.lower()
        assert "CloudWatch" in translation.remediation
        assert translation.error_level == "NONE"
        
        print('✅ PENDING status → PENDING code')
    
    # Test error classification
    
    def test_classify_aws_level_error(self):
        """
        Test AWS-level error classification
        
        Validates: Requirements 2.5
        """
        # Test multiple AWS-level errors
        aws_errors = [
            "INVALID_PHONE_FORMAT",
            "PRICE_EXCEEDED",
            "RATE_LIMIT_EXCEEDED",
            "COUNTRY_NOT_SUPPORTED"
        ]
        
        for error_code in aws_errors:
            level = self.translator.classify_error_level(error_code)
            assert level == "AWS", f"{error_code} should be AWS-level"
        
        print('✅ AWS-level errors classified correctly')
    
    def test_classify_carrier_level_error(self):
        """
        Test carrier-level error classification
        
        Validates: Requirements 2.5
        """
        # Test multiple carrier-level errors
        carrier_errors = [
            "CARRIER_BLOCKED",
            "SPAM_DETECTED",
            "DESTINATION_UNREACHABLE",
            "INVALID_SENDER_ID"
        ]
        
        for error_code in carrier_errors:
            level = self.translator.classify_error_level(error_code)
            assert level == "CARRIER", f"{error_code} should be CARRIER-level"
        
        print('✅ Carrier-level errors classified correctly')
    
    def test_classify_unknown_error(self):
        """
        Test unknown error classification
        
        Validates: Requirements 2.5
        """
        level = self.translator.classify_error_level("SOME_UNKNOWN_ERROR")
        assert level == "UNKNOWN"
        
        print('✅ Unknown error classified as UNKNOWN')
    
    # Test transient error detection
    
    def test_transient_error_detection(self):
        """
        Test transient error detection
        
        Validates: Requirements 8.1, 8.5
        """
        # Transient errors (can retry)
        assert self.translator.is_transient_error("RATE_LIMIT_EXCEEDED") is True
        assert self.translator.is_transient_error("DESTINATION_UNREACHABLE") is True
        
        # Permanent errors (no retry)
        assert self.translator.is_transient_error("COUNTRY_NOT_SUPPORTED") is False
        assert self.translator.is_transient_error("INVALID_PHONE_FORMAT") is False
        assert self.translator.is_transient_error("CARRIER_BLOCKED") is False
        assert self.translator.is_transient_error("SPAM_DETECTED") is False
        assert self.translator.is_transient_error("PRICE_EXCEEDED") is False
        
        print('✅ Transient error detection works correctly')
    
    # Test edge cases
    
    def test_none_provider_response(self):
        """
        Test None provider response is handled gracefully
        
        Edge case: CloudWatch log may have None for providerResponse
        
        Validates: Requirements 2.3
        """
        # Python will convert None to string "None" in translate_error
        # This should be treated as unknown error
        translation = self.translator.translate_error(None, "FAILED")
        
        # The method will receive None and should handle it
        assert translation.error_code == "UNKNOWN_ERROR"
        
        print('✅ None provider response handled gracefully')
    
    def test_very_long_provider_response(self):
        """
        Test very long provider response is handled
        
        Edge case: Some carriers may return very long error messages
        
        Validates: Requirements 2.3
        """
        long_response = "A" * 1000  # 1000 character error message
        translation = self.translator.translate_error(long_response, "FAILED")
        
        assert translation.error_code == "UNKNOWN_ERROR"
        assert translation.original_response == long_response
        
        print('✅ Very long provider response handled')
    
    def test_special_characters_in_response(self):
        """
        Test special characters in provider response
        
        Edge case: Carrier responses may contain special characters
        
        Validates: Requirements 2.3
        """
        special_response = "Error: ñ á é í ó ú ¿ ¡ $ € £"
        translation = self.translator.translate_error(special_response, "FAILED")
        
        assert translation.error_code == "UNKNOWN_ERROR"
        assert translation.original_response == special_response
        
        print('✅ Special characters in response handled')


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
