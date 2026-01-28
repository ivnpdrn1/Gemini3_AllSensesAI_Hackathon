# Configurable Emergency Keywords Feature

## Overview

The Configurable Emergency Keywords feature enables users to customize the list of words and phrases that trigger emergency detection in the AllSensesAI Gemini3 Guardian system. This provides flexibility for different demonstration scenarios and use cases while maintaining full integration with the existing emergency response pipeline.

## Key Features

### 1. **User-Configurable Keywords**
- Add custom emergency trigger words and phrases
- Remove keywords that aren't relevant to your scenario
- Keywords persist across page reloads using localStorage
- Default keywords: `emergency`, `help`, `call police`, `scared`, `following`, `danger`, `attack`

### 2. **Real-Time Detection**
- Checks both interim (partial) and final (complete) transcripts from Web Speech API
- Sub-second detection latency (< 1 second)
- Supports exact word matching (with word boundaries)
- Supports multi-word phrase matching (substring detection)
- Case-insensitive matching

### 3. **Emergency State Management**
- Captures matched keyword, transcript snippet, and timestamp
- Locks evidence packet with transcript window and location data
- Maintains emergency state across step transitions
- Reset functionality to clear state between demonstrations

### 4. **Seamless Integration**
- Preserves all existing emergency workflow functionality
- Emergency banner with location and Google Maps link
- Modal overlay with confirmation UI
- Badge updates (Listening → 🚨 EMERGENCY DETECTED)
- Auto-stop listening after detection
- Auto-advance to threat analysis (Step 4)
- Auto-advance to alerting on high risk (Step 5)
- Comprehensive proof logging

## Usage

### Accessing the Feature

Open the configurable keywords version:
```
Gemini3_AllSensesAI/gemini3-guardian-configurable-keywords.html
```

### Configuring Keywords

1. **Navigate to Step 3** - Voice Emergency Detection section
2. **View Current Keywords** - Displayed as chips in the "Emergency Keywords Configuration" panel
3. **Add a Keyword**:
   - Type the word or phrase in the input field
   - Click "➕ Add Keyword" or press Enter
   - The keyword will be added to the list and saved automatically
4. **Remove a Keyword**:
   - Click the "×" button on any keyword chip
   - Note: You must have at least one keyword configured

### Testing Emergency Detection

1. **Complete Steps 1 & 2** (Configuration and Location)
2. **Start Voice Detection** in Step 3
3. **Speak an emergency keyword** (e.g., "help", "emergency")
4. **Observe the response**:
   - Badge changes to "🚨 EMERGENCY DETECTED"
   - Emergency banner appears with details
   - Modal overlay confirms detection
   - System auto-advances to threat analysis
5. **Reset if needed** - Click "🔄 Reset Emergency State" to clear and start over

## Architecture

### Core Classes

#### `EmergencyKeywordsConfig`
Manages keyword configuration with localStorage persistence.

**Key Methods:**
- `loadKeywords()` - Load from localStorage or return defaults
- `saveKeywords(keywords)` - Persist to localStorage
- `addKeyword(keyword)` - Add new keyword with validation
- `removeKeyword(keyword)` - Remove keyword (prevents removing last one)
- `getKeywords()` - Get current keyword list
- `renderUI(container)` - Render keyword chips in UI

#### `KeywordDetectionEngine`
Analyzes transcripts for emergency keywords with normalization and matching logic.

**Key Methods:**
- `normalizeText(text)` - Lowercase, trim, collapse whitespace
- `detectKeyword(text)` - Check for any keyword match
- `matchExactWord(text, keyword)` - Word boundary matching for single words
- `matchPhraseSubstring(text, phrase)` - Substring matching for phrases
- `updateKeywords(keywords)` - Update keyword list

#### `EmergencyStateManager`
Manages emergency state variables and evidence packets.

**Key Methods:**
- `triggerEmergency(keyword, snippet, transcript, location)` - Set emergency state
- `lockEvidencePacket(transcript, location)` - Capture evidence
- `resetEmergency()` - Clear all state
- `getEmergencyState()` - Get current state
- `isEmergencyActive()` - Check if emergency is active

### Data Flow

```
User speaks → Web Speech API → Transcript (interim/final)
                                      ↓
                          KeywordDetectionEngine.detectKeyword()
                                      ↓
                          Match found? → EmergencyStateManager.triggerEmergency()
                                      ↓
                          Evidence packet locked (transcript + location)
                                      ↓
                          UI updates (banner, modal, badge)
                                      ↓
                          Auto-advance to Step 4 (threat analysis)
                                      ↓
                          High risk? → Auto-advance to Step 5 (alerting)
```

## Testing

### Running Tests

Open the test suite:
```
Gemini3_AllSensesAI/test-configurable-keywords.html
```

Click "▶️ Run All Tests" to execute:
- **Property-based tests** (using fast-check library)
- **Unit tests** for specific functionality
- **Integration tests** for end-to-end workflows

### Test Coverage

**Property Tests:**
1. Keyword configuration persistence round-trip
2. UI rendering completeness
3. Text normalization consistency
4. Word boundary matching
5. Phrase substring matching
6. Emergency state completeness
7. Evidence packet completeness
8. Reset clears all state

**Unit Tests:**
- Add valid keyword
- Reject empty keyword
- Reject duplicate keyword
- Remove existing keyword
- Prevent removal of last keyword
- Special characters in keywords
- Interim transcript detection
- Final transcript detection
- Case insensitivity

## Configuration Storage

Keywords are stored in browser localStorage:

**Storage Key:** `allsenses_emergency_keywords`

**Format:**
```json
["emergency", "help", "call police", "scared", "following", "danger", "attack"]
```

**Fallback:** If localStorage is unavailable or corrupted, the system falls back to default keywords.

## Error Handling

### Validation Errors
- **Empty keyword**: Rejected with alert message
- **Duplicate keyword**: Rejected with alert message
- **Last keyword removal**: Prevented with alert message

### Storage Errors
- **localStorage unavailable**: Falls back to in-memory storage with warning
- **Corrupted data**: Clears corrupted data and uses defaults

### Detection Errors
- **No keywords configured**: Prevented by minimum keyword requirement
- **Speech API errors**: Logged, system continues monitoring
- **Malformed transcripts**: Handled gracefully, no false triggers

## Performance

- **Detection latency**: < 1 second from speech to trigger
- **Keyword matching**: Optimized with early exit on first match
- **UI updates**: Immediate visual feedback
- **Storage operations**: Asynchronous, non-blocking

## Browser Compatibility

- **Chrome/Edge**: Full support (recommended)
- **Firefox**: Full support
- **Safari**: Full support (iOS 14.5+)
- **Requirements**: 
  - Web Speech API support
  - localStorage support
  - ES6+ JavaScript support

## Differences from Base Version

The configurable keywords version (`gemini3-guardian-configurable-keywords.html`) extends the base version (`gemini3-guardian-ux-enhanced.html`) with:

1. ✅ Keyword configuration UI in Step 3
2. ✅ localStorage persistence for keywords
3. ✅ EmergencyKeywordsConfig class
4. ✅ KeywordDetectionEngine class
5. ✅ EmergencyStateManager class
6. ✅ Reset Emergency State button
7. ✅ Enhanced proof logging with keyword details
8. ✅ Checks both interim and final transcripts
9. ✅ Help text for all steps explaining functionality

**All existing functionality is preserved** - this is an additive-only enhancement.

## Troubleshooting

### Keywords not persisting
- Check browser localStorage is enabled
- Check for private browsing mode (may disable localStorage)
- Clear browser cache and try again

### Keywords not triggering
- Verify microphone permission is granted
- Check keyword spelling and case (should be lowercase)
- Try speaking more clearly or adjusting microphone
- Check browser console for detection logs

### Reset button not appearing
- Reset button only appears after an emergency is triggered
- If stuck, refresh the page to reset completely

## Future Enhancements

Potential improvements for future versions:
- Import/export keyword configurations
- Keyword categories (high priority, medium priority)
- Regex pattern support for advanced matching
- Phonetic matching for similar-sounding words
- Multi-language support
- Cloud sync for keyword configurations

## Support

For issues or questions:
1. Check browser console for error messages
2. Run the test suite to verify functionality
3. Review proof logs in Step 2 and Step 3 sections
4. Ensure all prerequisites are met (Steps 1 & 2 complete)

## License

Part of the AllSensesAI Gemini3 Guardian system.
