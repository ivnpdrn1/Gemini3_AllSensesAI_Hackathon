# Implementation Plan: Step 3 Emergency Keywords Configuration

## Overview

This implementation plan breaks down the Step 3 Emergency Keywords Configuration feature into discrete coding tasks. The approach follows a test-driven development pattern with incremental integration, ensuring each component is validated before proceeding. All tasks focus on Step 3 modifications only, with explicit non-regression verification for Steps 1 and 2.

## Tasks

- [ ] 1. Create KeywordManager class with core functionality
  - Implement KeywordManager class with constructor accepting defaultKeywords and storageKey
  - Implement getActiveKeywords() method to return merged default + custom keywords
  - Implement normalizeKeyword() method for trimming and lowercase conversion
  - Implement isDuplicate() method to check for existing keywords
  - _Requirements: 2.1, 3.3, 3.4_

- [ ] 1.1 Write property test for KeywordManager core methods
  - **Property 8: Keyword Normalization**
  - **Validates: Requirements 3.4**

- [ ] 2. Implement keyword validation logic
  - Implement validateKeyword() method with empty string check
  - Add whitespace-only string validation
  - Add duplicate keyword detection
  - Add character validation (alphanumeric and spaces only)
  - Add length validation (max 50 characters)
  - Return validation result object with {valid: boolean, error?: string}
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 2.1 Write property test for validation logic
  - **Property 6: Whitespace Rejection**
  - **Validates: Requirements 3.2**

- [ ] 2.2 Write property test for duplicate prevention
  - **Property 7: Duplicate Prevention**
  - **Validates: Requirements 3.3**

- [ ] 2.3 Write unit test for empty string rejection
  - Test that empty string is rejected with appropriate error message
  - _Requirements: 3.1_

- [ ] 3. Implement keyword addition and removal
  - Implement addKeyword() method with validation integration
  - Implement removeKeyword() method for custom keywords only
  - Ensure state immutability on validation failure
  - Return success/error feedback for UI display
  - _Requirements: 2.2, 3.5_

- [ ] 3.1 Write property test for valid keyword addition
  - **Property 4: Valid Keyword Addition**
  - **Validates: Requirements 2.2**

- [ ] 3.2 Write property test for state immutability
  - **Property 9: State Immutability on Validation Failure**
  - **Validates: Requirements 3.5**

- [ ] 4. Implement localStorage persistence
  - Implement saveCustomKeywords() method to write to localStorage
  - Implement loadCustomKeywords() method to read from localStorage
  - Add error handling for storage failures
  - Add fallback for browsers without localStorage support
  - Handle corrupted data gracefully (clear and use defaults)
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 4.1 Write property test for persistence round-trip
  - **Property 10: Persistence Round-Trip**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [ ] 5. Create keyword list UI component
  - Add HTML structure for keyword list display to Step 3 section
  - Implement renderKeywordList() method to generate keyword DOM elements
  - Add CSS styling for keyword items (default vs custom badges)
  - Add remove button for custom keywords only
  - Ensure UI clearly distinguishes default from custom keywords
  - _Requirements: 1.1, 1.2, 1.4_

- [ ] 5.1 Write property test for keyword display completeness
  - **Property 1: Keyword Display Completeness**
  - **Validates: Requirements 1.1, 1.2**

- [ ] 5.2 Write property test for keyword type distinction
  - **Property 2: Keyword Type Distinction**
  - **Validates: Requirements 1.4**

- [ ] 6. Create keyword input UI component
  - Add HTML structure for keyword input field and add button
  - Add feedback div for success/error messages
  - Implement attachEventHandlers() method for UI interactions
  - Add event listener for add button click
  - Add event listener for Enter key in input field
  - Add event listeners for remove buttons
  - _Requirements: 2.1, 2.4_

- [ ] 6.1 Write property test for validation enforcement
  - **Property 3: Validation Enforcement**
  - **Validates: Requirements 2.1**

- [ ] 7. Integrate KeywordManager with existing emergency detection
  - Replace hardcoded EMERGENCY_KEYWORDS array with KeywordManager.getActiveKeywords()
  - Update checkForEmergencyKeywords() to use dynamic keyword list
  - Ensure case-insensitive matching is preserved
  - Verify both default and custom keywords trigger detection
  - _Requirements: 5.1, 5.2, 5.4_

- [ ] 7.1 Write property test for detection logic integration
  - **Property 5: Detection Logic Integration**
  - **Validates: Requirements 2.3**

- [ ] 7.2 Write property test for dual keyword evaluation
  - **Property 11: Dual Keyword Evaluation**
  - **Validates: Requirements 5.1, 5.2**

- [ ] 7.3 Write property test for case-insensitive matching
  - **Property 12: Case-Insensitive Matching**
  - **Validates: Requirements 5.4**

- [ ] 7.4 Write property test for default keywords always active
  - **Property 13: Default Keywords Always Active**
  - **Validates: Requirements 7.2**

- [ ] 7.5 Write unit test for default-only mode
  - Test that system works with no custom keywords added
  - _Requirements: 5.3, 7.1, 7.4_

- [ ] 8. Initialize KeywordManager on page load
  - Instantiate KeywordManager in DOMContentLoaded event handler
  - Load custom keywords from localStorage
  - Render initial keyword list UI
  - Attach event handlers for keyword management
  - Ensure initialization happens after existing Step 3 setup
  - _Requirements: 4.2_

- [ ] 9. Checkpoint - Verify Step 3 functionality
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Non-regression verification for Steps 1 and 2
  - Verify Step 1 button click handler still works correctly
  - Verify Step 2 location services work identically
  - Verify no DOM modifications in Step 1 or Step 2 sections
  - Verify no global variable conflicts introduced
  - Run existing Step 1 and Step 2 tests if available
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 10.1 Write unit test for Step 1 non-regression
  - Test that Step 1 completeStep1() function works unchanged
  - _Requirements: 6.1_

- [ ] 10.2 Write unit test for Step 2 non-regression
  - Test that Step 2 location functions work unchanged
  - _Requirements: 6.2_

- [ ] 10.3 Write unit test for DOM isolation
  - Test that Steps 1 and 2 DOM elements are unmodified
  - _Requirements: 6.3_

- [ ] 10.4 Write unit test for global variable isolation
  - Test that no new global variables conflict with existing ones
  - _Requirements: 6.4_

- [ ] 11. Add error handling and edge case support
  - Add error message display for storage failures
  - Add warning for browsers without localStorage
  - Handle empty custom keywords list gracefully
  - Handle corrupted localStorage data
  - Add user feedback for all error conditions
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 12. Final integration and polish
  - Ensure all UI feedback messages are clear and helpful
  - Verify keyword list scrolls properly with many keywords
  - Test with 50+ custom keywords for performance
  - Verify mobile responsiveness of keyword UI
  - Add inline documentation for KeywordManager class
  - _Requirements: 1.1, 2.4_

- [ ] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with minimum 100 iterations
- Unit tests validate specific examples, edge cases, and non-regression
- Checkpoints ensure incremental validation
- All modifications are isolated to Step 3 only
- Steps 1 and 2 must remain completely unchanged
