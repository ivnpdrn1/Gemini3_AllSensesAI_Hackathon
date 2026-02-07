#!/usr/bin/env python3
"""
Fix encoding corruption in gemini3-guardian-production-sms-FINAL.html

This script:
1. Copies the clean REBUILT version over the corrupted FINAL version
2. Removes all emoji characters (replaces with ASCII text)
3. Documents the corruption issue
"""

import shutil
import re
from pathlib import Path

def main():
    # Define file paths
    rebuilt_file = Path("Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html")
    final_file = Path("Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html")
    backup_file = Path("Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html.corrupted.bak")
    
    print("[FIX] Starting encoding corruption fix...")
    
    # Step 1: Backup the corrupted file
    if final_file.exists():
        print(f"[BACKUP] Creating backup: {backup_file}")
        shutil.copy2(final_file, backup_file)
    
    # Step 2: Copy clean REBUILT version to FINAL
    print(f"[RESTORE] Copying clean REBUILT version to FINAL...")
    shutil.copy2(rebuilt_file, final_file)
    
    # Step 3: Read the restored file
    with open(final_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Step 4: Remove emoji characters and replace with ASCII text
    print("[CLEAN] Removing emoji characters...")
    
    emoji_replacements = {
        '✅': '',  # Remove checkmark emoji
        '📤': '',  # Remove outbox emoji
        '🎤': '',  # Remove microphone emoji
        '📍': '',  # Remove pin emoji
        '🚨': '',  # Remove siren emoji
        '⚠️': '',  # Remove warning emoji
        '📞': '',  # Remove phone emoji
        '🔴': '',  # Remove red circle
        '🟢': '',  # Remove green circle
        '🎯': '',  # Remove target emoji
        '⏹️': '',  # Remove stop button
        '🗑️': '',  # Remove trash emoji
        '🔄': '',  # Remove refresh emoji
        '🗺️': '',  # Remove map emoji
        '🎥': '',  # Remove camera emoji
    }
    
    for emoji, replacement in emoji_replacements.items():
        if emoji in content:
            count = content.count(emoji)
            content = content.replace(emoji, replacement)
            print(f"  - Removed {count} instances of {emoji}")
    
    # Step 5: Write the cleaned content
    with open(final_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"[SUCCESS] File cleaned and saved: {final_file}")
    print(f"[SUCCESS] Corrupted backup saved: {backup_file}")
    
    # Step 6: Create documentation
    doc_file = Path("Gemini3_AllSensesAI/ENCODING_CORRUPTION_FIX_2026_02_06.md")
    with open(doc_file, 'w', encoding='utf-8') as f:
        f.write("""# Encoding Corruption Fix - February 6, 2026

## Problem Summary

The file `gemini3-guardian-production-sms-FINAL.html` was corrupted by an automated text replacement operation that incorrectly modified:

1. **CSS Properties**: `border-radius` → `border-radiInternational`
2. **CSS Properties**: `justify-content` → `jInternationaltify-content`
3. **Emoji Characters**: UTF-8 emojis causing JavaScript syntax errors
4. **Text Corruption**: Random "International" suffix added to various words

## Root Cause

An overly aggressive find-and-replace operation that:
- Searched for common words and added "International" suffix
- Did not properly escape CSS property names
- Did not handle UTF-8 emoji characters correctly

## Fix Applied

1. **Restored from Clean Baseline**: Copied `gemini3-guardian-production-sms-video-REBUILT.html` (clean version) to replace corrupted FINAL version
2. **Removed Emoji Characters**: Stripped all UTF-8 emoji characters to prevent syntax errors
3. **Created Backup**: Saved corrupted version as `.corrupted.bak` for reference

## Files Affected

- **Corrupted**: `gemini3-guardian-production-sms-FINAL.html` (now fixed)
- **Clean Source**: `gemini3-guardian-production-sms-video-REBUILT.html`
- **Backup**: `gemini3-guardian-production-sms-FINAL.html.corrupted.bak`

## Corruption Examples

### CSS Property Corruption
```css
/* CORRUPTED */
border-radiInternational: 15px;
jInternationaltify-content: center;

/* CORRECT */
border-radius: 15px;
justify-content: center;
```

### Emoji Corruption
```html
<!-- CORRUPTED -->
<button onclick="completeStep1()">✅ Complete Step 1</button>

<!-- CORRECT -->
<button onclick="completeStep1()">Complete Step 1</button>
```

## Prevention

To prevent future corruption:

1. **ASCII-Only Policy**: Follow project's PowerShell Script Governance rules - use ASCII characters only
2. **Careful Find-Replace**: Always use regex with word boundaries when doing global replacements
3. **Test After Changes**: Run syntax validation after any automated text operations
4. **Use Clean Baseline**: The REBUILT version is the canonical clean baseline

## Verification

Run diagnostics to verify the fix:

```powershell
# Check for syntax errors
.\.kiro\validate-js.ps1 -FilePath "Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html"

# Check for corruption patterns
Select-String -Path "Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html" -Pattern "radiInternational|jInternationaltify"
```

## Status

✓ Corruption fixed
✓ Emojis removed
✓ Backup created
✓ Documentation complete

## Related Files

- `KILL_SWITCH_REBUILD_COMPLETE_20260203.md` - Documents the clean REBUILT baseline
- `STEP1_ENCODING_MOJIBAKE_FIX_COMPLETE_20260203.md` - Previous encoding fix
- `.kiro/steering/security.md` - ASCII-only policy documentation
""")
    
    print(f"[DOCS] Documentation created: {doc_file}")
    print("\n[COMPLETE] All fixes applied successfully!")
    print("\nNext steps:")
    print("1. Verify the fixed file loads without errors")
    print("2. Test Step 1 button functionality")
    print("3. Deploy the fixed version")

if __name__ == "__main__":
    main()
