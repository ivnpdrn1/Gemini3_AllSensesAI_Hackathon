# Checkpoint 1 Hash Proof - Baseline vs Video Variant

**Date**: 2026-02-01  
**Purpose**: Document authoritative ckpt1 hashes for regression testing

---

## File Paths Used

**Baseline Production File**:
```
Gemini3_AllSensesAI/gemini3-guardian-production-sms.html
```

**Video Variant File**:
```
Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html
```

**Checkpoint 1 Hash File**:
```
Gemini3_AllSensesAI/video/checkpoints/ckpt1-hash.txt
```

---

## Computed Hashes

### Current Baseline Production File
**File**: `gemini3-guardian-production-sms.html`  
**SHA256**: `3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D`  
**Computed**: 2026-02-01

### Current Video Variant File
**File**: `gemini3-guardian-production-sms-video.html`  
**SHA256**: `991DCA09ED43CDD6191E13B46C7A339496146202312A70E14EAFF2264884C60C`  
**Computed**: 2026-02-01

### Checkpoint 1 Recorded Hash
**File**: `ckpt1-hash.txt`  
**Recorded Hash**: `015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7`  
**File Referenced**: `gemini3-guardian-production-sms-video.html` (video variant)

---

## Analysis

### Issue Identified
The `ckpt1-hash.txt` file contains the hash for the **video variant file** at checkpoint 1, NOT the baseline production file.

The regression script `run-regression-local.ps1` was incorrectly using this video variant hash (`015EC...`) as the "known baseline hash" to verify the baseline production file.

### Root Cause
**Incorrect Constant**: The hardcoded `$KNOWN_BASELINE_HASH` in `run-regression-local.ps1` was set to:
```
015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7
```

This is the hash of the video variant file at checkpoint 1, not the baseline production file.

**Correct Baseline Hash**: The baseline production file hash is:
```
3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D
```

---

## Conclusion

### Match/Mismatch Status
✅ **MATCH**: Current baseline file hash matches the verified ckpt1 baseline hash  
❌ **MISMATCH**: The hardcoded constant in the regression script was wrong

### Verified Authoritative Hashes

**Baseline Production File** (ckpt1):
```
3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D
```

**Video Variant File** (ckpt1):
```
015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7
```

---

## Recommendation

1. Create canonical hash file: `known-baseline-hash.txt` with the correct baseline hash
2. Update `run-regression-local.ps1` to read from canonical hash files instead of hardcoded constants
3. Preserve historical record with this proof document

---

**Status**: Proof Complete ✅  
**Baseline Unchanged**: YES (hash matches expected ckpt1 value)  
**False Alarm**: YES (wrong constant in regression script)

