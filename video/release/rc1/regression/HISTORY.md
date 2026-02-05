# Regression Test Harness History

**Purpose**: Document changes and incidents in the regression test harness

---

## Incident 1: False FAIL Due to Wrong Hardcoded Hash

**Date**: 2026-02-01  
**Status**: RESOLVED ✅

### What Happened

The local regression test (`run-regression-local.ps1`) reported a FAIL when comparing the baseline production file hash against the "known ckpt1 hash" constant.

**Evidence**:
- Current baseline SHA256: `3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D`
- Script's hardcoded "Known hash (ckpt1)": `015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7`
- Result: MISMATCH → FALSE ALARM

### Root Cause

The hardcoded `$KNOWN_BASELINE_HASH` constant in `run-regression-local.ps1` was set to the wrong value.

**Incorrect Value** (hardcoded in script):
```
015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7
```

This hash belongs to the **video variant file** (`gemini3-guardian-production-sms-video.html`) at checkpoint 1, NOT the baseline production file.

**Correct Value** (verified from checkpoint artifacts):
```
3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D
```

This is the actual hash of the **baseline production file** (`gemini3-guardian-production-sms.html`) at checkpoint 1.

### How It Was Fixed

**1. Created Canonical Hash File**:
- File: `known-baseline-hash.txt`
- Content: `3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D`
- Location: `Gemini3_AllSensesAI/video/release/rc1/regression/`

**2. Updated Regression Script**:
- Removed hardcoded `$KNOWN_BASELINE_HASH` constant
- Added file-based hash loading with fallback chain:
  1. Prefer: `Gemini3_AllSensesAI/video/checkpoints/ckpt1-baseline-hash.txt`
  2. Fallback: `Gemini3_AllSensesAI/video/release/rc1/regression/known-baseline-hash.txt`
  3. Fail: Clear error message if neither exists

**3. Created Proof Document**:
- File: `ckpt1-hash-proof.md`
- Documents: File paths, computed hashes, analysis, conclusion
- Preserves: Historical record of the incident

### Why This Preserves Non-Destructive Guarantees

✅ **No Production File Changes**: The baseline production file was never modified  
✅ **No Feature Changes**: Only regression test harness was updated  
✅ **Historical Integrity**: Proof document preserves complete audit trail  
✅ **Future-Proof**: File-based hashes prevent hardcoded constant drift  

### Verification

After the fix, the regression test now:
- Reads authoritative hash from `known-baseline-hash.txt`
- Compares current baseline hash: `3EE4...` against known hash: `3EE4...`
- Reports: **PASS** ✅

---

## Lessons Learned

1. **Never Hardcode Hashes**: Use canonical hash files instead of hardcoded constants
2. **Document Hash Sources**: Clearly label which file each hash belongs to
3. **Verify Before Alarming**: False alarms erode trust in regression tests
4. **Preserve History**: Document incidents to prevent future confusion

---

## Future Improvements

1. **Checkpoint 1 Canonical File**: Create `ckpt1-baseline-hash.txt` in checkpoints folder
2. **Automated Hash Verification**: Add script to verify all checkpoint hashes
3. **Hash File Format**: Standardize format with metadata (file name, date, purpose)

---

**History Status**: Up to Date ✅  
**Last Updated**: 2026-02-01

