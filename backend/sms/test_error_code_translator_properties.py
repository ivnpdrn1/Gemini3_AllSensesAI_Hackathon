"""
Property-Based Tests for Error Code Translator

This module contains property-based tests for the ErrorCodeTranslator class.
Property-based tests verify universal properties that should hold for all inputs.

Requirements: 2.2, 2.4, 2.5
Properties: 4, 5
"""

import pytest
from hypothesis import given, strategies as st, settings
from error_code_translator import ErrorCodeTranslator, ErrorTranslation


# Feature: colombia-sms-unknown-error-fix, Property 4: Error Code Translation Completeness
@given(st.sampled_from(list(ErrorCodeTranslator.ERROR_CODE_MAP.keys())))
@settings(max_examples=100, deadline=None)
def test_property_4_error_code_translation_completeness(provider_response):
    """
    Property 4: Error Code Translation Completeness
    
    For any error code in the ERROR_CODE_MAP, the translation SHALL contain
    a non-empty user_message, remediation, and error_code field.
    
    This property ensures that every error in our mapping has complete
    information for users to understand and fix the issue.
    
    Validates: Requirements 2.2, 2.4
    """
    translator = ErrorCodeTranslator()
    
    # Translate the error
    translation = translator.translate_error(provider_response, "FAILED")
    
    # Verify all required fields are non-empty
    assert translation.user_message != "", \
        f"user_message is empty for error: {provider_response}"
    
    assert translation.remediation != "", \
        f"remediation is empty for error: {provider_response}"
    
    assert translation.error_code != "", \
        f"error_code is empty for error: {provider_response}"
    
    assert translation.error_code != "UNKNOWN_ERROR", \
        f"error_code is UNKNOWN_ERROR for known error: {provider_response}"
    
    # Verify original response is preserved
    assert translation.original_response == provider_response, \
        f"original_response not preserved: expected {provider_response}, got {translation.original_response}"
    
    print(f'✅ Property 4: {provider_response} → {translation.error_code}')


# Feature: colombia-sms-unknown-error-fix, Property 5: Error Classification
@given(st.sampled_from(list(ErrorCodeTranslator.ERROR_CODE_MAP.keys())))
@settings(max_examples=100, deadline=None)
def test_property_5_error_classification(provider_response):
    """
    Property 5: Error Classification
    
    For any error response, the system SHALL correctly classify it as either
    AWS-level (e.g., INVALID_PHONE_FORMAT) or carrier-level (e.g., CARRIER_BLOCKED)
    based on the error source.
    
    This property ensures that errors are properly categorized to help with
    troubleshooting and determining where the issue occurred.
    
    Validates: Requirements 2.5
    """
    translator = ErrorCodeTranslator()
    
    # Translate the error
    translation = translator.translate_error(provider_response, "FAILED")
    
    # Verify error_level is either AWS or CARRIER
    assert translation.error_level in ["AWS", "CARRIER"], \
        f"error_level must be AWS or CARRIER, got: {translation.error_level}"
    
    # Verify classification matches the ERROR_CODE_MAP
    expected_level = ErrorCodeTranslator.ERROR_CODE_MAP[provider_response]["error_level"]
    assert translation.error_level == expected_level, \
        f"error_level mismatch for {provider_response}: expected {expected_level}, got {translation.error_level}"
    
    # Verify classify_error_level method returns same result
    classified_level = translator.classify_error_level(translation.error_code)
    assert classified_level == translation.error_level, \
        f"classify_error_level mismatch: expected {translation.error_level}, got {classified_level}"
    
    print(f'✅ Property 5: {provider_response} → {translation.error_level} level')


# Feature: colombia-sms-unknown-error-fix, Additional Property: Unknown Error Fallback
@given(st.text(min_size=1, max_size=100).filter(
    lambda x: x not in ErrorCodeTranslator.ERROR_CODE_MAP and 
              not any(key.lower() in x.lower() for key in ErrorCodeTranslator.ERROR_CODE_MAP.keys())
))
@settings(max_examples=100, deadline=None)
def test_property_unknown_error_fallback(unknown_response):
    """
    Additional Property: Unknown Error Fallback
    
    For any error response that is NOT in the ERROR_CODE_MAP, the system SHALL
    return a fallback error with error_code="UNKNOWN_ERROR" and include the
    original response in the user message.
    
    This property ensures that unknown errors are handled gracefully and users
    still receive actionable information.
    
    Validates: Requirements 2.3
    """
    translator = ErrorCodeTranslator()
    
    # Translate unknown error
    translation = translator.translate_error(unknown_response, "FAILED")
    
    # Verify fallback error code
    assert translation.error_code == "UNKNOWN_ERROR", \
        f"Unknown error should have error_code=UNKNOWN_ERROR, got: {translation.error_code}"
    
    # Verify original response is in user message
    assert unknown_response in translation.user_message, \
        f"Original response not in user_message: {translation.user_message}"
    
    # Verify remediation provides guidance
    assert "CloudWatch" in translation.remediation or "support" in translation.remediation, \
        f"Remediation should mention CloudWatch or support: {translation.remediation}"
    
    # Verify error level is UNKNOWN
    assert translation.error_level == "UNKNOWN", \
        f"Unknown error should have error_level=UNKNOWN, got: {translation.error_level}"
    
    print(f'✅ Unknown Error Fallback: {unknown_response[:30]}... → UNKNOWN_ERROR')


# Feature: colombia-sms-unknown-error-fix, Additional Property: SUCCESS Status Handling
@given(st.text(min_size=0, max_size=100))
@settings(max_examples=100, deadline=None)
def test_property_success_status_handling(provider_response):
    """
    Additional Property: SUCCESS Status Handling
    
    For any provider response with status="SUCCESS", the system SHALL return
    error_code="SUCCESS" with a success message, regardless of the provider
    response content.
    
    This property ensures that successful deliveries are handled correctly.
    
    Validates: Requirements 5.4
    """
    translator = ErrorCodeTranslator()
    
    # Translate with SUCCESS status
    translation = translator.translate_error(provider_response, "SUCCESS")
    
    # Verify success error code
    assert translation.error_code == "SUCCESS", \
        f"SUCCESS status should have error_code=SUCCESS, got: {translation.error_code}"
    
    # Verify success message
    assert "success" in translation.user_message.lower(), \
        f"SUCCESS status should have success message: {translation.user_message}"
    
    # Verify no action needed
    assert "no action" in translation.remediation.lower(), \
        f"SUCCESS status should have 'no action' remediation: {translation.remediation}"
    
    # Verify error level is NONE
    assert translation.error_level == "NONE", \
        f"SUCCESS status should have error_level=NONE, got: {translation.error_level}"
    
    print(f'✅ SUCCESS Status: {provider_response[:30]}... → SUCCESS')


# Feature: colombia-sms-unknown-error-fix, Additional Property: PENDING Status Handling
@given(st.text(min_size=0, max_size=100))
@settings(max_examples=100, deadline=None)
def test_property_pending_status_handling(provider_response):
    """
    Additional Property: PENDING Status Handling
    
    For any provider response with status="PENDING", the system SHALL return
    error_code="PENDING" with a pending message, regardless of the provider
    response content.
    
    This property ensures that pending deliveries (logs not yet available)
    are handled correctly.
    
    Validates: Requirements 5.5
    """
    translator = ErrorCodeTranslator()
    
    # Translate with PENDING status
    translation = translator.translate_error(provider_response, "PENDING")
    
    # Verify pending error code
    assert translation.error_code == "PENDING", \
        f"PENDING status should have error_code=PENDING, got: {translation.error_code}"
    
    # Verify pending message
    assert "pending" in translation.user_message.lower(), \
        f"PENDING status should have pending message: {translation.user_message}"
    
    # Verify remediation mentions checking logs
    assert "CloudWatch" in translation.remediation or "check" in translation.remediation.lower(), \
        f"PENDING status should mention checking logs: {translation.remediation}"
    
    # Verify error level is NONE
    assert translation.error_level == "NONE", \
        f"PENDING status should have error_level=NONE, got: {translation.error_level}"
    
    print(f'✅ PENDING Status: {provider_response[:30]}... → PENDING')


# Feature: colombia-sms-unknown-error-fix, Additional Property: Transient Error Classification
@given(st.sampled_from(["RATE_LIMIT_EXCEEDED", "DESTINATION_UNREACHABLE"]))
@settings(max_examples=50, deadline=None)
def test_property_transient_error_classification(error_code):
    """
    Additional Property: Transient Error Classification
    
    For any error code that is transient (can be retried), the is_transient_error
    method SHALL return True.
    
    This property ensures that transient errors are correctly identified for
    retry logic.
    
    Validates: Requirements 8.1, 8.5
    """
    translator = ErrorCodeTranslator()
    
    # Verify transient error is identified
    assert translator.is_transient_error(error_code) is True, \
        f"{error_code} should be classified as transient"
    
    print(f'✅ Transient Error: {error_code} → can retry')


# Feature: colombia-sms-unknown-error-fix, Additional Property: Permanent Error Classification
@given(st.sampled_from([
    "COUNTRY_NOT_SUPPORTED",
    "INVALID_PHONE_FORMAT",
    "CARRIER_BLOCKED",
    "SPAM_DETECTED",
    "PRICE_EXCEEDED"
]))
@settings(max_examples=50, deadline=None)
def test_property_permanent_error_classification(error_code):
    """
    Additional Property: Permanent Error Classification
    
    For any error code that is permanent (should not be retried), the
    is_transient_error method SHALL return False.
    
    This property ensures that permanent errors are not retried unnecessarily.
    
    Validates: Requirements 8.5
    """
    translator = ErrorCodeTranslator()
    
    # Verify permanent error is identified
    assert translator.is_transient_error(error_code) is False, \
        f"{error_code} should be classified as permanent (not transient)"
    
    print(f'✅ Permanent Error: {error_code} → no retry')


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
