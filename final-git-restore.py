#!/usr/bin/env python3
"""
Final restoration from Git stable tag with complete emoji removal.
"""

import re
import subprocess
import sys

def main():
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html'
    
    print("[GIT] Fetching file from v2026.01.31-step1-stable...")
    
    try:
        result = subprocess.run(
            ['git', 'show', 'v2026.01.31-step1-stable:current/gemini3-guardian-current.html'],
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace'
        )
        
        if result.returncode != 0:
            print(f"[ERROR] Git command failed: {result.stderr}")
            sys.exit(1)
        
        content = result.stdout
        
    except Exception as e:
        print(f"[ERROR] Failed to fetch from Git: {e}")
        sys.exit(1)
    
    print(f"[CLEAN] Removing all non-ASCII characters (emojis and mojibake)...")
    
    # Remove ALL non-ASCII characters for complete ASCII compliance
    content = content.encode('ascii', errors='ignore').decode('ascii')
    
    print(f"[SAVE] Writing cleaned file: {output_file}")
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
    except Exception as e:
        print(f"[ERROR] Failed to write file: {e}")
        sys.exit(1)
    
    print(f"[SUCCESS] File restored from Git stable tag with all non-ASCII removed!")
    print(f"\nVerification:")
    print(f"- All emoji characters: REMOVED")
    print(f"- All mojibake: REMOVED")
    print(f"- ASCII-only compliance: ENFORCED")
    print(f"\nNext steps:")
    print(f"1. Run getDiagnostics to verify")
    print(f"2. Test Step 1 button functionality")
    print(f"3. Deploy when ready")

if __name__ == '__main__':
    main()
