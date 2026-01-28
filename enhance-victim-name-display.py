#!/usr/bin/env python3
"""
Enhance Victim Name Display in SMS
- Change "Contact:" to "Victim:" in SMS messages
- Add explicit "Victim Name:" line item in Step 5 preview panel
- Add proof logging for victim name
- Ensure fallback to "Unknown User" if name is empty
"""

import re

def enhance_victim_name_display(html_content):
    """Enhance victim name display in SMS and preview"""
    
    # 1. Update SMS message format: Change "Contact:" to "Victim:"
    html_content = html_content.replace(
        'Contact: ${payload.victimName}',
        'Victim: ${payload.victimName}'
    )
    
    # 2. Add victim name normalization with fallback in composeAlertSms
    compose_function_pattern = r'(function composeAlertSms\(payload\) \{[\s\S]*?)(// Validate required fields)'
    
    def add_normalization(match):
        return match.group(1) + '''// Normalize victim name with fallback
            const victimName = (payload.victimName || '').trim() || 'Unknown User';
            payload.victimName = victimName;
            
            ''' + match.group(2)
    
    html_content = re.sub(compose_function_pattern, add_normalization, html_content)
    
    # 3. Add victim name line item to SMS preview panel checklist
    # Find the checklist and add victim name as first item after product identity
    checklist_pattern = r'(<li id="smsCheckIdentity">Product identity:.*?</li>)'
    victim_name_item = r'''\1
                            <li id="smsCheckVictimName">Victim name: <span id="smsCheckVictimNameValue">—</span></li>'''
    
    html_content = re.sub(checklist_pattern, victim_name_item, html_content)
    
    # 4. Add victim name display in preview meta section (before destination)
    meta_pattern = r'(<div id="smsPreviewContent"[^>]*>)'
    victim_meta = r'''\1
                    <div class="sms-preview-meta">
                        <span class="sms-preview-label">Victim Name:</span>
                        <span class="sms-preview-value" id="smsPreviewVictimName">—</span>
                    </div>
                    '''
    
    html_content = re.sub(meta_pattern, victim_meta, html_content)
    
    # 5. Update updateSmsPreview function to display victim name
    # Find the section where we display preview and add victim name update
    preview_display_pattern = r'(document\.getElementById\(\'smsPreviewDestination\'\)\.textContent = emergencyContact;)'
    
    victim_name_update = r'''// Display victim name in preview
            const displayVictimName = victimName || 'Unknown User';
            document.getElementById('smsPreviewVictimName').textContent = displayVictimName;
            document.getElementById('smsCheckVictimNameValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            
            // Show warning if using fallback
            if (!victimName) {
                document.getElementById('smsCheckVictimNameValue').innerHTML = '<span style="color:#ffc107;">⚠ Using fallback: Unknown User</span>';
            }
            
            \1'''
    
    html_content = re.sub(preview_display_pattern, victim_name_update, html_content)
    
    # 6. Add proof logging when victim name is set in completeStep1
    # This is already present, but let's ensure it's visible
    proof_pattern = r'(console\.log\(\`\[STEP1\] Victim name set: "\$\{name\}"\`\);)'
    
    enhanced_proof = r'''\1
                
                // Add UI-visible proof for victim name
                if (!name) {
                    addStep1ProofToUI('[STEP1][WARNING] Victim name empty - will use fallback: "Unknown User"');
                    console.log('[STEP1][WARNING] Victim name empty - will use fallback');
                }'''
    
    html_content = re.sub(proof_pattern, enhanced_proof, html_content)
    
    # 7. Add proof logging in SMS preview update
    preview_log_pattern = r'(console\.log\(\'\[SMS-PREVIEW\] Preview updated successfully)'
    
    preview_proof = r'''// Log victim name in preview
            console.log('[STEP5] SMS composed for:', displayVictimName);
            
            \1'''
    
    html_content = re.sub(preview_log_pattern, preview_proof, html_content)
    
    # 8. Update build stamp
    html_content = re.sub(
        r'Build: GEMINI3-VICTIM-NAME-SMS-\d+',
        'Build: GEMINI3-VICTIM-NAME-ENHANCED-20260128',
        html_content
    )
    
    return html_content


def main():
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-victim-name-sms.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-victim-name-enhanced.html'
    
    print(f"Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("Enhancing victim name display...")
    enhanced_content = enhance_victim_name_display(content)
    
    print(f"Writing {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(enhanced_content)
    
    print("✅ Enhancement complete!")
    print("\nChanges made:")
    print("1. Changed 'Contact:' to 'Victim:' in SMS messages")
    print("2. Added 'Victim Name:' line item in Step 5 preview panel")
    print("3. Added fallback to 'Unknown User' if name is empty")
    print("4. Added proof logging for victim name in Step 1 and Step 5")
    print("5. Added warning display if using fallback name")
    print("\nOutput file:", output_file)


if __name__ == '__main__':
    main()
