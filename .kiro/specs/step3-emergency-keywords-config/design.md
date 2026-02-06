# Design Document

## Overview

This design document specifies the Step 3 Emergency Keywords Configuration feature for the AllSenses AI Guardian system. The feature adds a user interface within Step 3 to display current emergency keywords and allow users to add custom keywords. The implementation follows a non-invasive approach that enhances Step 3 without modifying Steps 1 or 2, ensuring backward compatibility and zero regression.

The design leverages the existing `EMERGENCY_KEYWORDS` array and `checkForEmergencyKeywords()` function, extending them with persistence and UI management capabilities.

## Architecture

### Component Structure

```
Step 3 Section (Enhanced)
├── Voice Detection Controls (Existing)
├── Emergency Keywords Manager (NEW)
│   ├── Keyword Display List
│   ├── Keyword Input Field
│   ├── Add Keyword Button
│   └── Validation Feedback
└── Voice Status Display (Existing)
```

### Data Flow

```
User Input → Validation → Normalization → Storage → UI Update → Detection Logic Update
                ↓                                                        ↓
            Error Display                                    Emergency Detection Active
```

### Storage Architecture

```
localStorage
└── "allsenses_custom_keywords" (JSON array)
    ├── Persists across sessions
    ├── Merged with default keywords at runtime
    └── Validated on load
```

## Components and Interfaces

### 1. KeywordManager Class

**Purpose**: Manages emergency keyword storage, validation, and UI rendering

**Interface**:
```javascript
class KeywordManager {
    constructor(defaultKeywords, storageKey)
    
    // Core Methods
    getActiveKeywords()           // Returns: string[] - All active keywords
    addKeyword(keyword)           // Returns: {success: boolean, error?: string}
    removeKeyword(keyword)        // Returns: boolean
    
    // Persistence Methods
    loadCustomKeywords()          // Returns: string[] - Loads from localStorage
    saveCustomKeywords()          // Returns: void - Saves to localStorage
    
    // Validation Methods
    validateKeyword(keyword)      // Returns: {valid: boolean, error?: string}
    normalizeKeyword(keyword)     // Returns: string - Trimmed, lowercase
    isDuplicate(keyword)          // Returns: boolean
    
    // UI Methods
    renderKeywordList(containerId) // Returns: void - Renders keyword list to DOM
    attachEventHandlers()          // Returns: void - Attaches UI event listeners
}
```

**Properties**:
- `defaultKeywords`: string[] - Immutable default keywords
- `customKeywords`: string[] - User-added keywords
- `storageKey`: string - localStorage key for persistence

### 2. UI Components

#### Keyword Display List
```html
<div id="keywordList" class="keyword-list">
    <div class="keyword-item default">
        <span class="keyword-text">help</span>
        <span class="keyword-badge">Default</span>
    </div>
    <div class="keyword-item custom">
        <span class="keyword-text">socorro</span>
        <span class="keyword-badge">Custom</span>
        <button class="keyword-remove">×</button>
    </div>
</div>
```

#### Keyword Input Form
```html
<div class="keyword-input-section">
    <input type="text" id="keywordInput" placeholder="Add custom keyword..." />
    <button id="addKeywordBtn" class="button">Add Keyword</button>
    <div id="keywordFeedback" class="feedback"></div>
</div>
```

### 3. Integration with Existing Code

**Modification Points** (Step 3 only):
1. Replace hardcoded `EMERGENCY_KEYWORDS` array with dynamic getter
2. Inject KeywordManager UI into Step 3 section
3. Initialize KeywordManager on page load

**Non-Modification Guarantee**:
- Steps 1 and 2: Zero changes to HTML, CSS, or JavaScript
- Global state: No new global variables that conflict with existing code
- Event handlers: No modifications to Step 1 or Step 2 event listeners

## Data Models

### Keyword Data Structure

```javascript
// Default Keywords (Immutable)
const DEFAULT_EMERGENCY_KEYWORDS = [
    "help",
    "help me",
    "ayuda",
    "emergency",
    "call police",
    "someone is following me",
    "kidnapped",
    "rape",
    "robbery",
    "gun",
    "knife"
];

// Custom Keywords (Persisted)
// Stored in localStorage as JSON array
// Example: ["socorro", "auxilio", "danger"]

// Active Keywords (Runtime)
// Computed by merging default + custom
// Used by checkForEmergencyKeywords()
```

### Validation Rules

```javascript
const VALIDATION_RULES = {
    minLength: 1,
    maxLength: 50,
    allowedPattern: /^[a-zA-Z0-9\s]+$/,  // Alphanumeric and spaces only
    normalization: {
        trim: true,
        lowercase: true
    }
};
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Acceptance Criteria Testing Prework

1.1 WHEN Step 3 is displayed, THE Keyword_Manager SHALL render the complete list of active emergency keywords
  Thoughts: This is about ensuring the UI correctly displays all keywords. We can test this by generating random sets of default and custom keywords, then verifying the rendered DOM contains all keywords.
  Testable: yes - property

1.2 THE displayed keywords SHALL match exactly the terms used by the Emergency_Detection_Logic
  Thoughts: This is about consistency between UI and detection logic. We can test this by comparing the displayed keywords with the keywords used in detection for any configuration.
  Testable: yes - property

1.3 WHEN the keyword list is empty, THE Keyword_Manager SHALL display a message indicating no keywords are configured
  Thoughts: This is a specific edge case - when there are no keywords. This is an edge case we should handle.
  Testable: edge-case

1.4 THE keyword display SHALL clearly distinguish between Default_Keywords and user-added keywords
  Thoughts: This is about UI rendering. We can test that for any keyword, we can determine from the DOM whether it's marked as default or custom.
  Testable: yes - property

2.1 WHEN a user enters a new keyword, THE Keyword_Manager SHALL validate the input before acceptance
  Thoughts: This is about validation happening for all inputs. We can generate random inputs (valid and invalid) and ensure validation runs.
  Testable: yes - property

2.2 WHEN a valid keyword is submitted, THE Keyword_Manager SHALL add it to the active keyword list
  Thoughts: This is about the add operation working correctly for all valid inputs. We can generate random valid keywords and verify they appear in the active list.
  Testable: yes - property

2.3 WHEN a keyword is added, THE Emergency_Detection_Logic SHALL immediately include it in trigger evaluation
  Thoughts: This is about the detection logic using the updated keyword list. We can add a random keyword, then test that transcripts containing it trigger detection.
  Testable: yes - property

2.4 THE Keyword_Manager SHALL provide clear feedback when a keyword is successfully added
  Thoughts: This is about UI feedback. We can test that after adding any valid keyword, feedback is displayed.
  Testable: yes - property

3.1 WHEN a user attempts to add an empty string, THE Keyword_Manager SHALL reject the input and display an error message
  Thoughts: This is testing the empty string case specifically.
  Testable: yes - example

3.2 WHEN a user attempts to add a whitespace-only string, THE Keyword_Manager SHALL reject the input and display an error message
  Thoughts: This is testing that validation rejects whitespace-only strings. We can generate random whitespace strings and ensure they're all rejected.
  Testable: yes - property

3.3 WHEN a user attempts to add a duplicate keyword, THE Keyword_Manager SHALL reject the input and display an error message
  Thoughts: This is about duplicate detection working for all keywords. We can generate random keywords, add them, then try to add them again and verify rejection.
  Testable: yes - property

3.4 THE Keyword_Manager SHALL normalize keywords by trimming whitespace and converting to lowercase for consistency
  Thoughts: This is about normalization working correctly for all inputs. We can generate random strings with various whitespace and casing, and verify normalization produces consistent results.
  Testable: yes - property

3.5 WHEN validation fails, THE Keyword_Manager SHALL maintain the current keyword list unchanged
  Thoughts: This is about state immutability on validation failure. We can attempt to add invalid keywords and verify the keyword list remains unchanged.
  Testable: yes - property

4.1 WHEN a keyword is added, THE Persistence_Layer SHALL store the updated keyword list immediately
  Thoughts: This is about persistence happening for all additions. We can add random keywords and verify localStorage is updated.
  Testable: yes - property

4.2 WHEN the application loads, THE Keyword_Manager SHALL retrieve all stored keywords from the Persistence_Layer
  Thoughts: This is about load working correctly. We can store random keyword sets, reload, and verify they're restored.
  Testable: yes - property

4.3 WHEN the page is reloaded, THE Keyword_Manager SHALL restore all user-added keywords
  Thoughts: This is the same as 4.2 - it's about the round-trip property of persistence.
  Testable: yes - property (redundant with 4.2)

4.4 THE Persistence_Layer SHALL maintain keyword data across browser sessions
  Thoughts: This is about localStorage persistence, which is the same as 4.2 and 4.3.
  Testable: yes - property (redundant with 4.2)

5.1 WHEN transcribed text contains any active keyword, THE Emergency_Detection_Logic SHALL trigger the emergency procedure
  Thoughts: This is about detection working for all keywords. We can generate random transcripts containing random keywords and verify detection triggers.
  Testable: yes - property

5.2 THE Emergency_Detection_Logic SHALL evaluate both Default_Keywords and user-added keywords
  Thoughts: This is about detection working for both types of keywords. We can test with random combinations of default and custom keywords.
  Testable: yes - property

5.3 WHEN no custom keywords are added, THE Emergency_Detection_Logic SHALL continue using Default_Keywords
  Thoughts: This is about backward compatibility - the default case should work.
  Testable: yes - example

5.4 THE keyword matching SHALL be case-insensitive to maximize detection reliability
  Thoughts: This is about case-insensitive matching working for all keywords. We can generate random keywords with various casings and verify matching works.
  Testable: yes - property

6.1 WHEN Step 3 modifications are deployed, THE Step_1 SHALL function identically to its previous behavior
  Thoughts: This is about non-regression. We can test that Step 1 functionality is unchanged by running existing Step 1 tests.
  Testable: yes - example

6.2 WHEN Step 3 modifications are deployed, THE Step_2 SHALL function identically to its previous behavior
  Thoughts: This is about non-regression. We can test that Step 2 functionality is unchanged by running existing Step 2 tests.
  Testable: yes - example

6.3 THE Step_3 modifications SHALL not alter any DOM elements, event handlers, or logic in Steps 1 and 2
  Thoughts: This is about isolation. We can verify that the DOM structure and event handlers for Steps 1 and 2 are unchanged.
  Testable: yes - example

6.4 THE Step_3 modifications SHALL not introduce any global variable conflicts or side effects affecting other steps
  Thoughts: This is about namespace isolation. We can verify that no new global variables conflict with existing ones.
  Testable: yes - example

7.1 WHEN no custom keywords are configured, THE Emergency_Detection_Logic SHALL use only Default_Keywords
  Thoughts: This is the same as 5.3 - testing the default case.
  Testable: yes - example (redundant with 5.3)

7.2 THE Default_Keywords SHALL remain active regardless of user customization
  Thoughts: This is about default keywords always being present. We can add random custom keywords and verify defaults are still active.
  Testable: yes - property

7.3 WHEN custom keywords are added, THE Emergency_Detection_Logic SHALL evaluate both default and custom keywords
  Thoughts: This is the same as 5.2 - testing that both types work.
  Testable: yes - property (redundant with 5.2)

7.4 THE system SHALL not require any user action to maintain existing emergency detection functionality
  Thoughts: This is about backward compatibility - the system should work without user interaction.
  Testable: yes - example

### Property Reflection

After reviewing all testable properties, I've identified the following redundancies:

**Redundant Properties:**
- 4.3 and 4.4 are redundant with 4.2 (all test persistence round-trip)
- 7.1 is redundant with 5.3 (both test default-only case)
- 7.3 is redundant with 5.2 (both test default + custom evaluation)

**Consolidation:**
- Properties 4.2, 4.3, 4.4 can be combined into a single comprehensive persistence round-trip property
- Properties 5.3 and 7.1 can be combined into a single backward compatibility example
- Properties 5.2 and 7.3 can be combined into a single dual-evaluation property

### Correctness Properties

Property 1: Keyword Display Completeness
*For any* set of default and custom keywords, the rendered keyword list should contain all keywords from both sets
**Validates: Requirements 1.1, 1.2**

Property 2: Keyword Type Distinction
*For any* keyword in the active list, the UI should clearly indicate whether it is a default or custom keyword
**Validates: Requirements 1.4**

Property 3: Validation Enforcement
*For any* input string, the Keyword_Manager should validate it before adding to the active list
**Validates: Requirements 2.1**

Property 4: Valid Keyword Addition
*For any* valid keyword input, adding it should result in the keyword appearing in the active keyword list
**Validates: Requirements 2.2**

Property 5: Detection Logic Integration
*For any* keyword added to the active list, transcripts containing that keyword should trigger emergency detection
**Validates: Requirements 2.3**

Property 6: Whitespace Rejection
*For any* string composed entirely of whitespace characters, the Keyword_Manager should reject it with an error message
**Validates: Requirements 3.2**

Property 7: Duplicate Prevention
*For any* keyword already in the active list, attempting to add it again should be rejected with an error message
**Validates: Requirements 3.3**

Property 8: Keyword Normalization
*For any* input string with leading/trailing whitespace or mixed case, normalization should produce a trimmed lowercase version
**Validates: Requirements 3.4**

Property 9: State Immutability on Validation Failure
*For any* invalid keyword input, the active keyword list should remain unchanged after validation failure
**Validates: Requirements 3.5**

Property 10: Persistence Round-Trip
*For any* set of custom keywords, storing them to localStorage and then reloading the page should restore the exact same set of keywords
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

Property 11: Dual Keyword Evaluation
*For any* transcript containing either a default keyword or a custom keyword, the Emergency_Detection_Logic should trigger the emergency procedure
**Validates: Requirements 5.1, 5.2, 7.3**

Property 12: Case-Insensitive Matching
*For any* keyword and any transcript, matching should succeed regardless of the case of characters in the transcript
**Validates: Requirements 5.4**

Property 13: Default Keywords Always Active
*For any* configuration of custom keywords (including empty), default keywords should always be included in emergency detection
**Validates: Requirements 7.2**

## Error Handling

### Validation Errors

```javascript
const ERROR_MESSAGES = {
    EMPTY_INPUT: "Keyword cannot be empty",
    WHITESPACE_ONLY: "Keyword cannot be only whitespace",
    DUPLICATE: "This keyword already exists",
    INVALID_CHARACTERS: "Keyword contains invalid characters",
    TOO_LONG: "Keyword is too long (max 50 characters)",
    STORAGE_ERROR: "Failed to save keywords. Please try again."
};
```

### Error Recovery

1. **Validation Failure**: Display error message, clear input field, maintain current state
2. **Storage Failure**: Display error message, log to console, attempt retry on next operation
3. **Load Failure**: Fall back to default keywords only, log warning to console

### Edge Cases

1. **Empty Custom Keywords**: Display only default keywords
2. **Corrupted localStorage**: Clear corrupted data, fall back to defaults
3. **Browser Without localStorage**: Disable persistence, show warning, keywords work for session only
4. **Maximum Keywords**: No hard limit, but UI should handle large lists gracefully

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests**: Verify specific examples, edge cases, and error conditions
- Empty string rejection (Requirement 3.1)
- Step 1 non-regression (Requirement 6.1)
- Step 2 non-regression (Requirement 6.2)
- DOM isolation verification (Requirement 6.3)
- Global variable conflict check (Requirement 6.4)
- Default-only mode (Requirements 5.3, 7.1, 7.4)

**Property Tests**: Verify universal properties across all inputs
- All other testable properties (Properties 1-13)
- Minimum 100 iterations per property test
- Each test tagged with feature name and property reference

### Property-Based Testing Configuration

**Library**: fast-check (JavaScript property-based testing library)

**Test Configuration**:
```javascript
fc.assert(
    fc.property(
        fc.array(fc.string()),  // Generate random keyword arrays
        (keywords) => {
            // Test property
        }
    ),
    { numRuns: 100 }  // Minimum 100 iterations
);
```

**Test Tags**:
```javascript
// Feature: step3-emergency-keywords-config, Property 1: Keyword Display Completeness
test('Property 1: Keyword Display Completeness', () => {
    // Test implementation
});
```

### Integration Testing

1. **End-to-End Flow**: Add keyword → Speak keyword → Verify emergency trigger
2. **Persistence Flow**: Add keyword → Reload page → Verify keyword restored
3. **Non-Regression Flow**: Run existing Step 1 and Step 2 tests → Verify no failures

### Manual Testing Checklist

- [ ] Add valid keyword and verify it appears in list
- [ ] Add duplicate keyword and verify rejection
- [ ] Add empty keyword and verify rejection
- [ ] Add whitespace-only keyword and verify rejection
- [ ] Reload page and verify custom keywords persist
- [ ] Speak custom keyword and verify emergency triggers
- [ ] Verify Steps 1 and 2 work identically to before
- [ ] Test with localStorage disabled (private browsing)
- [ ] Test with large number of custom keywords (50+)

## Implementation Notes

### CSS Styling

```css
.keyword-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin: 15px 0;
}

.keyword-item {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 0.9em;
}

.keyword-item.default {
    background: #e3f2fd;
    border: 1px solid #2196f3;
}

.keyword-item.custom {
    background: #f3e5f5;
    border: 1px solid #9c27b0;
}

.keyword-badge {
    font-size: 0.75em;
    font-weight: bold;
    text-transform: uppercase;
}

.keyword-remove {
    background: none;
    border: none;
    color: #666;
    cursor: pointer;
    font-size: 1.2em;
    padding: 0;
    margin-left: 4px;
}

.keyword-input-section {
    display: flex;
    gap: 10px;
    align-items: center;
    margin: 15px 0;
}

.feedback {
    padding: 8px 12px;
    border-radius: 5px;
    font-size: 0.9em;
    margin-top: 8px;
}

.feedback.success {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
}

.feedback.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
}
```

### Backward Compatibility Strategy

1. **Feature Detection**: Check for localStorage support before using
2. **Graceful Degradation**: If localStorage unavailable, keywords work for session only
3. **Default Preservation**: Default keywords always active, never removed
4. **Zero Breaking Changes**: No modifications to existing Step 1 or Step 2 code

### Performance Considerations

1. **Keyword Matching**: Use lowercase comparison for O(n) performance
2. **UI Rendering**: Batch DOM updates to minimize reflows
3. **Storage Operations**: Debounce saves to reduce localStorage writes
4. **Memory**: No memory leaks from event listeners (proper cleanup)
