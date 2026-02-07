#!/usr/bin/env python3
"""
Restore gemini3-guardian-production-sms-FINAL.html from Git stable tag
and fix any remaining encoding issues.
"""

import re
import sys

def fix_encoding_issues(content):
    """Fix common encoding corruption patterns."""
    
    # Fix mojibake patterns
    replacements = {
        'Γ£à': '✓',  # Checkmark
        '≡ƒöì': '📋',  # Clipboard/document
        'Γ¥î': '⚠',  # Warning
        'Γ£ô': '✅',  # Check mark button
        'Γ£ö': '📤',  # Outbox tray
        'Γ£ò': '🎤',  # Microphone
        'Γ£ô': '📍',  # Round pushpin
        'Γ£ê': '🚨',  # Police car light
        'Γ¢ÿ': '⚠',  # Warning sign
        'Γ¢ö': '🔴',  # Red circle
        'Γ¢ÿ': '🟢',  # Green circle
        'Γ¢ÿ': '🟡',  # Yellow circle
    }
    
    for bad, good in replacements.items():
        content = content.replace(bad, good)
    
    # Remove all remaining emoji-like UTF-8 artifacts
    # Keep only ASCII and basic Latin characters
    content = re.sub(r'[^\x00-\x7F\u00A0-\u00FF\u0100-\u017F\u0180-\u024F]+', '', content)
    
    return content

def main():
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL-RESTORED.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html'
    
    print(f"[RESTORE] Reading from Git stable version: {input_file}")
    
    try:
        with open(input_file, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        print(f"[ERROR] Failed to read file: {e}")
        sys.exit(1)
    
    print(f"[FIX] Fixing encoding issues...")
    content = fix_encoding_issues(content)
    
    # Remove all emojis completely for ASCII-only compliance
    print(f"[CLEAN] Removing all emoji characters for ASCII compliance...")
    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"  # emoticons
        "\U0001F300-\U0001F5FF"  # symbols & pictographs
        "\U0001F680-\U0001F6FF"  # transport & map symbols
        "\U0001F1E0-\U0001F1FF"  # flags (iOS)
        "\U00002702-\U000027B0"
        "\U000024C2-\U0001F251"
        "\U0001F900-\U0001F9FF"  # Supplemental Symbols and Pictographs
        "\U0001FA00-\U0001FA6F"  # Chess Symbols
        "\U00002600-\U000026FF"  # Miscellaneous Symbols
        "\U00002700-\U000027BF"  # Dingbats
        "]+",
        flags=re.UNICODE
    )
    content = emoji_pattern.sub('', content)
    
    print(f"[SAVE] Writing cleaned file: {output_file}")
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
    except Exception as e:
        print(f"[ERROR] Failed to write file: {e}")
        sys.exit(1)
    
    print(f"[SUCCESS] File restored and cleaned from Git stable tag!")
    print(f"\nNext steps:")
    print(f"1. Verify with: getDiagnostics")
    print(f"2. Test Step 1 button functionality")
    print(f"3. Deploy when ready")

if __name__ == '__main__':
    main()
