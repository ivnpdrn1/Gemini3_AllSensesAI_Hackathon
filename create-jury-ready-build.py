#!/usr/bin/env python3
"""
Create Jury-Ready Production Build
Build: JURY-READY-20260128-v1

This script creates a deploy-ready HTML build with:
1. Step 1 button fix (type="button", preventDefault, proof logging)
2. Step 5 always-visible SMS preview (8 fields + raw SMS text)
3. Configurable keywords UI
4. Build Identity proof for undeniable jury verification

Hard constraints:
- No git/repository actions
- No legacy system names
- Preserve 5-step flow and UX parity
- Deterministic SMS preview (preview = sent message exactly)
"""

import re
import sys
from pathlib import Path
from datetime import datetime

# Build identity
BUILD_ID = "JURY-READY-20260128-v1"
BUILD_TIMESTAMP = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")

def fail_hard(message):
    """Exit with error message"""
    print(f"❌ BUILD FAILED: {message}", file=sys.stderr)
    sys.exit(1)

def verify_required_functions(html):
    """Verify all required functions exist in the HTML"""
    required = [
        'function composeAlertPayload(',
        'function composeAlertSms(',
        'function renderSmsPreviewFields(',
        'function updateSmsPreview(',
        'function completeStep1('
    ]
    
    missing = []
    for func in required:
        if func not in html:
            missing.append(func)
    
    if missing:
        fail_hard(f"Missing required functions: {', '.join(missing)}")
    
    print(f"✓ All {len(required)} required functions present")

def verify_sms_preview_fields(html):
    """Verify all 8 SMS preview fields exist"""
    required_fields = [
        'id="sms-victim"',
        'id="sms-risk"',
        'id="sms-recommendation"',
        'id="sms-message"',
        'id="sms-location"',
        'id="sms-map"',
        'id="sms-time"',
        'id="sms-action"'
    ]
    
    missing = []
    for field in required_fields:
        if field not in html:
            missing.append(field)
    
    if missing:
        fail_hard(f"Missing SMS preview fields: {', '.join(missing)}")
    
    print(f"✓ All {len(required_fields)} SMS preview fields present")

def create_build():
    """Create the jury-ready production build"""
    
    print(f"========================================")
    print(f"Creating Jury-Ready Production Build")
    print(f"Build ID: {BUILD_ID}")
    print(f"========================================\n")
    
    # Read base file
    base_file = Path('Gemini3_AllSensesAI/gemini3-guardian-step1-step5-keywords-final.html')
    
    if not base_file.exists():
        fail_hard(f"Base file not found: {base_file}")
    
    print(f"✓ Base file found: {base_file}")
    
    with open(base_file, 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Update build stamp
    html = re.sub(
        r'Build: [A-Z0-9-]+',
        f'Build: {BUILD_ID}',
        html
    )
    
    # Add "Loaded Build ID" to Runtime Health Check
    # Find the health grid closing tag
    health_grid_marker = '<div class="health-item" id="health-location">'
    health_grid_pos = html.find(health_grid_marker)
    if health_grid_pos == -1:
        fail_hard("Could not find health grid location item")
    
    # Find the end of the location health item
    location_item_end = html.find('</div>\n                </div>', health_grid_pos)
    if location_item_end == -1:
        fail_hard("Could not find location item end")
    
    # Move past the closing tags
    insertion_point = location_item_end + len('</div>\n                </div>')
    
    loaded_build_id_html = '''
                <div class="health-item live" id="health-loaded-build">
                    <div class="health-label">Loaded Build ID</div>
                    <div class="health-value" style="font-family: monospace; font-size: 12px;">{BUILD_ID}</div>
                </div>'''.format(BUILD_ID=BUILD_ID)
    
    html = html[:insertion_point] + loaded_build_id_html + html[insertion_point:]
    
    print(f"✓ Added 'Loaded Build ID' to Runtime Health Check")
    
    # Verify all required functions exist
    verify_required_functions(html)
    
    # Verify all SMS preview fields exist
    verify_sms_preview_fields(html)
    
    # Verify Step 1 button is type="button"
    if 'type="button" class="button primary-btn" onclick="completeStep1()"' not in html:
        fail_hard("Step 1 button is not type='button'")
    print("✓ Step 1 button is type='button'")
    
    # Verify configurable keywords UI exists
    if 'class="keywords-config"' not in html:
        fail_hard("Configurable keywords UI missing")
    print("✓ Configurable keywords UI present")
    
    # Verify build validation exists
    if '[BUILD-VALIDATION]' not in html:
        fail_hard("Build validation script missing")
    print("✓ Build validation script present")
    
    # Write output file
    output_file = Path('Gemini3_AllSensesAI/jury-ready-production.html')
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)
    
    file_size = output_file.stat().st_size
    
    print(f"\n✅ BUILD SUCCESSFUL")
    print(f"   Output: {output_file}")
    print(f"   Build ID: {BUILD_ID}")
    print(f"   Size: {file_size:,} bytes ({file_size / 1024:.1f} KB)")
    print(f"   Timestamp: {BUILD_TIMESTAMP}")
    
    return True

if __name__ == '__main__':
    try:
        success = create_build()
        if success:
            print(f"\n✅ Ready for deployment")
            sys.exit(0)
        else:
            fail_hard("Build process returned False")
    except Exception as e:
        fail_hard(f"Unexpected error: {str(e)}")
