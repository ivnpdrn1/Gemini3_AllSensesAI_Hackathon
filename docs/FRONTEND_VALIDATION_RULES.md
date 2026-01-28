# Frontend Validation Rules

**Document Purpose**: Technical specification of E.164 phone number validation logic implemented in the frontend.

**Build**: GEMINI3-E164-PARITY-20260128  
**Implementation**: JavaScript (browser-side)

---

## Required E.164 Regex

### Pattern
```javascript
const e164Regex = /^\+[1-9]\d{6,14}$/;
```

### Pattern Components

**Start Anchor** (`^`):
- Ensures pattern matches from beginning of string
- Prevents partial matches
- Example: "+1234567890extra" would fail

**Plus Sign** (`\+`):
- Literal plus character (escaped)
- Required as first character
- Example: "1234567890" fails, "+1234567890" passes

**Country Code First Digit** (`[1-9]`):
- Character class matching digits 1-9
- Excludes leading zero (no country code starts with 0)
- Example: "+0123456789" fails, "+1234567890" passes

**Remaining Digits** (`\d{6,14}`):
- Matches 6 to 14 additional digits
- Combined with country code digit: 7-15 total digits
- Example: "+1" (1 digit) fails, "+1234567" (7 digits) passes

**End Anchor** (`$`):
- Ensures pattern matches to end of string
- Prevents trailing characters
- Example: "+1234567890 " (trailing space) would fail

### Total Length Constraint
- Minimum: 7 digits (e.g., +1234567)
- Maximum: 15 digits (e.g., +123456789012345)
- ITU-T E.164 standard allows up to 15 digits total

---

## Validation Function

### Implementation
```javascript
function validateE164Phone(phoneNumber) {
    const trimmed = phoneNumber.trim();
    
    // E.164 regex: must start with +, followed by country code (1-9), then 6-14 more digits
    const e164Regex = /^\+[1-9]\d{6,14}$/;
    
    if (!trimmed) {
        return {
            valid: false,
            message: 'Phone number required',
            color: '#dc3545'
        };
    }
    
    if (!trimmed.startsWith('+')) {
        return {
            valid: false,
            message: 'Must start with + (E.164 format)',
            color: '#dc3545'
        };
    }
    
    if (!e164Regex.test(trimmed)) {
        return {
            valid: false,
            message: 'Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)',
            color: '#dc3545'
        };
    }
    
    // Detect country for user feedback
    let country = 'International';
    if (trimmed.startsWith('+1')) country = 'US';
    else if (trimmed.startsWith('+57')) country = 'Colombia';
    else if (trimmed.startsWith('+52')) country = 'Mexico';
    else if (trimmed.startsWith('+58')) country = 'Venezuela';
    
    return {
        valid: true,
        message: `✓ Valid E.164 (${country})`,
        color: '#28a745',
        country: country
    };
}
```

### Return Object Structure
```javascript
{
    valid: boolean,        // true if passes all checks
    message: string,       // User-facing feedback message
    color: string,         // CSS color for feedback (#28a745 green or #dc3545 red)
    country?: string       // Detected country (only if valid)
}
```

---

## Validation Sequence

### Step 1: Trim Whitespace
```javascript
const trimmed = phoneNumber.trim();
```

**Purpose**: Remove leading/trailing spaces  
**Example**: " +14155552671 " → "+14155552671"

### Step 2: Empty Check
```javascript
if (!trimmed) {
    return {
        valid: false,
        message: 'Phone number required',
        color: '#dc3545'
    };
}
```

**Triggers**: Empty string or whitespace-only input  
**User Feedback**: "Phone number required" (red)

### Step 3: Plus Sign Check
```javascript
if (!trimmed.startsWith('+')) {
    return {
        valid: false,
        message: 'Must start with + (E.164 format)',
        color: '#dc3545'
    };
}
```

**Triggers**: Input doesn't start with +  
**User Feedback**: "Must start with + (E.164 format)" (red)  
**Example**: "14155552671" fails this check

### Step 4: Format Check
```javascript
if (!e164Regex.test(trimmed)) {
    return {
        valid: false,
        message: 'Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)',
        color: '#dc3545'
    };
}
```

**Triggers**: Input doesn't match E.164 regex  
**User Feedback**: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)" (red)  
**Examples**:
- "+1" (too short)
- "+57 3001234567" (contains space)
- "+52-55-1234-5678" (contains dashes)

### Step 5: Country Detection
```javascript
let country = 'International';
if (trimmed.startsWith('+1')) country = 'US';
else if (trimmed.startsWith('+57')) country = 'Colombia';
else if (trimmed.startsWith('+52')) country = 'Mexico';
else if (trimmed.startsWith('+58')) country = 'Venezuela';
```

**Purpose**: Provide user feedback about detected country  
**Fallback**: "International" for other valid E.164 numbers

### Step 6: Success Return
```javascript
return {
    valid: true,
    message: `✓ Valid E.164 (${country})`,
    color: '#28a745',
    country: country
};
```

**User Feedback**: "✓ Valid E.164 (Country)" (green)

---

## What Happens on Valid Input

### UI Updates
1. Validation feedback div displays
2. Message text: "✓ Valid E.164 (Country)"
3. Message color: Green (#28a745)
4. Input field data attribute: `data-valid="true"`

### Form State
1. "Complete Step 1" button remains enabled
2. Form submission allowed
3. Configuration saved to session state
4. Step 2 "Enable Location" button enabled

### User Experience
1. Immediate positive feedback
2. Clear indication of detected country
3. Confidence to proceed
4. No blocking errors

---

## What Happens on Invalid Input

### UI Updates
1. Validation feedback div displays
2. Message text: Specific error message
3. Message color: Red (#dc3545)
4. Input field data attribute: `data-valid="false"`

### Form State
1. "Complete Step 1" button remains enabled (but submission blocked)
2. Form submission blocked via JavaScript
3. Alert shown with error message
4. User returned to Step 1 to correct input

### User Experience
1. Immediate negative feedback
2. Clear explanation of error
3. Guidance on correct format
4. Opportunity to correct immediately

### Error Messages by Type

**Empty Input**:
```
Message: "Phone number required"
Trigger: Empty string or whitespace-only
```

**Missing Plus**:
```
Message: "Must start with + (E.164 format)"
Trigger: First character is not +
Example: "14155552671"
```

**Too Short**:
```
Message: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
Trigger: Less than 7 total digits
Example: "+1"
```

**Contains Spaces**:
```
Message: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
Trigger: Whitespace in number
Example: "+57 3001234567"
```

**Contains Dashes**:
```
Message: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
Trigger: Dash characters in number
Example: "+52-55-1234-5678"
```

**Contains Parentheses**:
```
Message: "Must start with + (E.164 format)"
Trigger: First character is not +
Example: "(415) 555-2671"
```

---

## Why Validation is Enforced at UI Layer

### 1. Immediate User Feedback
**Benefit**: User knows instantly if input is valid  
**Alternative**: Server-side validation requires round-trip  
**Impact**: Better user experience, faster iteration

### 2. Reduced Backend Load
**Benefit**: Invalid inputs never reach backend  
**Alternative**: Backend validates and rejects  
**Impact**: Lower API costs, faster response times

### 3. Progressive Disclosure
**Benefit**: Validation runs on every keystroke  
**Alternative**: Validation only on form submission  
**Impact**: User can correct errors as they type

### 4. Client-Side Performance
**Benefit**: Regex validation is instant (< 1ms)  
**Alternative**: Network round-trip (100-500ms)  
**Impact**: No perceived latency

### 5. Offline Capability
**Benefit**: Validation works without internet  
**Alternative**: Requires server connection  
**Impact**: Better reliability, works in poor network conditions

### 6. Security (Defense in Depth)
**Benefit**: First line of defense against invalid input  
**Alternative**: Rely solely on backend validation  
**Impact**: Reduces attack surface, prevents injection

### 7. Consistency
**Benefit**: Same validation logic across all browsers  
**Alternative**: Browser-specific validation  
**Impact**: Predictable behavior, easier testing

### 8. User Guidance
**Benefit**: Error messages guide user to correct format  
**Alternative**: Generic "invalid input" message  
**Impact**: Higher success rate, less frustration

---

## Event Binding

### Input Event
```javascript
phoneInput.addEventListener('input', updatePhoneValidation);
```

**Trigger**: Every keystroke in phone input field  
**Purpose**: Real-time validation as user types  
**Behavior**: Validation runs immediately, feedback updates

### Blur Event
```javascript
phoneInput.addEventListener('blur', updatePhoneValidation);
```

**Trigger**: User leaves phone input field (focus lost)  
**Purpose**: Final validation check before proceeding  
**Behavior**: Validation runs, feedback persists

### Form Submission
```javascript
function completeStep1() {
    const phoneValidation = validateE164Phone(phone);
    if (!phoneValidation.valid) {
        alert('Invalid phone number: ' + phoneValidation.message);
        updatePhoneValidation(); // Show feedback
        return; // Block progression
    }
    // Proceed to Step 2
}
```

**Trigger**: User clicks "Complete Step 1" button  
**Purpose**: Final gate before saving configuration  
**Behavior**: Validation runs, invalid input blocks progression

---

## UI Feedback Mechanism

### Feedback Div
```html
<div id="phoneValidationFeedback" class="note" style="margin-top: 5px; font-weight: bold; display: none;"></div>
```

**Initial State**: Hidden (`display: none`)  
**After First Input**: Visible with validation message

### Update Function
```javascript
function updatePhoneValidation() {
    const phoneInput = document.getElementById('emergencyPhone');
    const feedback = document.getElementById('phoneValidationFeedback');
    
    if (!phoneInput || !feedback) return;
    
    const result = validateE164Phone(phoneInput.value);
    
    feedback.style.display = 'block';
    feedback.style.color = result.color;
    feedback.textContent = result.message;
    
    phoneInput.setAttribute('data-valid', result.valid ? 'true' : 'false');
}
```

**Behavior**:
1. Gets current input value
2. Runs validation
3. Shows feedback div
4. Sets text color (green or red)
5. Sets message text
6. Updates data attribute for form submission check

---

## Test Cases

### Valid Inputs

**US Number**:
```
Input: "+14155552671"
Expected: valid=true, message="✓ Valid E.164 (US)", color="#28a745"
```

**Colombia Number**:
```
Input: "+573001234567"
Expected: valid=true, message="✓ Valid E.164 (Colombia)", color="#28a745"
```

**Mexico Number**:
```
Input: "+5215512345678"
Expected: valid=true, message="✓ Valid E.164 (Mexico)", color="#28a745"
```

**Venezuela Number**:
```
Input: "+584121234567"
Expected: valid=true, message="✓ Valid E.164 (Venezuela)", color="#28a745"
```

**Generic International**:
```
Input: "+441234567890"
Expected: valid=true, message="✓ Valid E.164 (International)", color="#28a745"
```

### Invalid Inputs

**Empty**:
```
Input: ""
Expected: valid=false, message="Phone number required", color="#dc3545"
```

**Missing Plus**:
```
Input: "14155552671"
Expected: valid=false, message="Must start with + (E.164 format)", color="#dc3545"
```

**Too Short**:
```
Input: "+1"
Expected: valid=false, message="Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)", color="#dc3545"
```

**Spaces**:
```
Input: "+57 3001234567"
Expected: valid=false, message="Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)", color="#dc3545"
```

**Dashes**:
```
Input: "+52-55-1234-5678"
Expected: valid=false, message="Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)", color="#dc3545"
```

**Parentheses**:
```
Input: "(415) 555-2671"
Expected: valid=false, message="Must start with + (E.164 format)", color="#dc3545"
```

**Leading Zero in Country Code**:
```
Input: "+0123456789"
Expected: valid=false, message="Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)", color="#dc3545"
```

**Too Long**:
```
Input: "+1234567890123456"
Expected: valid=false, message="Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)", color="#dc3545"
```

---

## Browser Compatibility

### Regex Support
- Chrome: Full support
- Edge: Full support
- Firefox: Full support
- Safari: Full support
- IE11: Full support (if needed)

**Note**: E.164 regex uses basic regex features supported by all modern browsers.

### String Methods
- `trim()`: Supported in all browsers
- `startsWith()`: Supported in all modern browsers (IE11 requires polyfill)
- `test()`: Supported in all browsers

### DOM Methods
- `getElementById()`: Supported in all browsers
- `addEventListener()`: Supported in all browsers
- `setAttribute()`: Supported in all browsers

---

## Performance Characteristics

### Validation Speed
- Regex test: < 1ms
- String operations: < 1ms
- Total validation: < 5ms

### UI Update Speed
- DOM manipulation: < 5ms
- Style updates: < 5ms
- Total UI update: < 10ms

### User-Perceived Latency
- Input event to feedback: < 20ms
- Imperceptible to user
- Feels instant

---

## Known Limitations

### Format-Only Validation
- Validates format, not existence
- "+1234567890" is valid format but may not be a real number
- No carrier validation
- No real-time number lookup

### Country Detection
- Based on prefix only
- "+1" could be US or Canada (both use +1)
- No geographic validation
- No area code validation

### No Normalization
- Doesn't convert national format to E.164
- User must enter E.164 format directly
- No automatic formatting

### No Carrier Validation
- Doesn't check if number is active
- Doesn't check if SMS is supported
- Doesn't check if number is mobile vs landline

---

**Document Status**: Complete  
**Last Updated**: January 28, 2026  
**Audience**: Developers, technical reviewers, QA engineers
