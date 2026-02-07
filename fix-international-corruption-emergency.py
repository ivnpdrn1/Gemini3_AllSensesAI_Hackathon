#!/usr/bin/env python3
"""
Emergency Fix: Remove "International" Corruption from FINAL.html
Fixes the corruption that prevents JavaScript from loading
"""

import re
import sys
from pathlib import Path

def fix_international_corruption(file_path):
    """Remove International corruption from file"""
    
    print(f"Reading: {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    fixes_applied = []
    
    # Fix 1: step1StatInternational -> step1Status
    if 'step1StatInternational' in content:
        content = content.replace('step1StatInternational', 'step1Status')
        fixes_applied.append('step1StatInternational -> step1Status')
    
    # Fix 2: Internationaling -> Using
    if 'Internationaling' in content:
        content = content.replace('Internationaling', 'Using')
        fixes_applied.append('Internationaling -> Using')
    
    # Fix 3: Any other "International" suffixes that shouldn't be there
    # Look for common patterns like "wordInternational" where it should just be "word"
    patterns = [
        (r'(\w+)International([\'"\s\)])', r'\1\2'),  # wordInternational" -> word"
    ]
    
    for pattern, replacement in patterns:
        matches = re.findall(pattern, content)
        if matches:
            content = re.sub(pattern, replacement, content)
            fixes_applied.append(f'Removed International suffix: {len(matches)} occurrences')
    
    # Check if any changes were made
    if content == original_content:
        print("No International corruption found")
        return False
    
    # Create backup
    backup_path = f"{file_path}.before-international-fix.bak"
    print(f"Creating backup: {backup_path}")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(original_content)
    
    # Write fixed content
    print(f"Writing fixed content to: {file_path}")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\nFixes Applied:")
    for fix in fixes_applied:
        print(f"  - {fix}")
    
    return True

def main():
    file_path = Path("Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html")
    
    if not file_path.exists():
        print(f"ERROR: File not found: {file_path}")
        sys.exit(1)
    
    print("=" * 60)
    print("Emergency Fix: International Corruption")
    print("=" * 60)
    print()
    
    success = fix_international_corruption(file_path)
    
    if success:
        print()
        print("=" * 60)
        print("Fix Complete!")
        print("=" * 60)
        print()
        print("Next Steps:")
        print("  1. Deploy: .\\Gemini3_AllSensesAI\\deployment\\deploy-step3-keywords-config.ps1")
        print("  2. Wait 60 seconds for CloudFront cache")
        print("  3. Test: Hard refresh (Ctrl+Shift+R) and click Step 1 button")
    else:
        print()
        print("No fixes needed - file appears clean")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
