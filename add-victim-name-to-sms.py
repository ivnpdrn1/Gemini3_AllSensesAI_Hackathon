#!/usr/bin/env python3
"""
Add Victim Name to SMS Preview + Sent SMS
Enhance Step 5 SMS Preview to include victim name from Step 1
"""

import re
import sys

def add_victim_name_to_sms(input_file, output_file):
    """Add victim name to SMS preview and sent messages"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update build stamp
    content = content.replace(
        'Build: GEMINI3-STEP1-KEYWORDS-FIX-20260128',
        'Build: GEMINI3-VICTIM-NAME-SMS-20260128'
    )
    content = content.replace(
        'GEMINI3-STEP1-KEYWORDS-FIX-20260128',
        'GEMINI3-VICTIM-NAME-SMS-20260128'
    )
    
    # ========== UPDATE composeAlertSms() FUNCTION ==========
    
    # Find and replace the composeAlertSms function
    old_compose_function = r'''        function composeAlertSms\(payload\) \{
            // Single source of truth for SMS message composition
            
            const emergencyTriggered = payload\.emergencyTriggered \|\| false;
            const name = payload\.name \|\| 'Unknown User';
            const phone = payload\.phone \|\| 'Unknown';
            const lat = payload\.latitude;
            const lng = payload\.longitude;
            const timestamp = payload\.timestamp \|\| new Date\(\)\.toISOString\(\);
            const message = payload\.message \|\| '';
            const threatLevel = payload\.threatLevel \|\| 'UNKNOWN';
            const confidence = payload\.confidence \|\| 'N/A';
            const recommendation = payload\.recommendation \|\| 'Contact emergency services if needed';
            
            if \(!emergencyTriggered\) \{
                // Standby format
                if \(!lat \|\| !lng\) \{
                    return 'Standby: Enable location in Step 2';
                \}
                return `Standby: no emergency trigger detected yet\.\n\nContact: \$\{name\}\nPhone: \$\{phone\}\nLocation: \$\{lat\}, \$\{lng\}\nTime: \$\{timestamp\}`;
            \}
            
            // Emergency format
            const mapsLink = `https://maps\.google\.com/\?q=\$\{lat\},\$\{lng\}`;
            const messageSnippet = message\.substring\(0, 100\);
            
            return `🚨 AllSensesAI Guardian Alert\n\nRisk: \$\{threatLevel\} \(Confidence: \$\{confidence\}\)\nRecommendation: \$\{recommendation\}\n\nTimestamp: \$\{timestamp\}\nLocation: \$\{lat\}, \$\{lng\}\nMap: \$\{mapsLink\}\n\nMessage: "\$\{messageSnippet\}"\n\nAction: Call them now\. If urgent, contact local emergency services\.`;
        \}'''
    
    new_compose_function = '''        function composeAlertSms(payload) {
            // Single source of truth for SMS message composition
            
            const emergencyTriggered = payload.emergencyTriggered || false;
            const victimName = (payload.name || '').trim() || 'Unknown User';
            const phone = payload.phone || 'Unknown';
            const lat = payload.latitude;
            const lng = payload.longitude;
            const timestamp = payload.timestamp || new Date().toISOString();
            const message = payload.message || '';
            const threatLevel = payload.threatLevel || 'UNKNOWN';
            const confidence = payload.confidence || 'N/A';
            const recommendation = payload.recommendation || 'Contact emergency services if needed';
            
            if (!emergencyTriggered) {
                // Standby format
                if (!lat || !lng) {
                    return 'Standby: Enable location in Step 2';
                }
                return `Standby: no emergency trigger detected yet.\\n\\nVictim: ${victimName}\\nContact: ${phone}\\nLocation: ${lat}, ${lng}\\nTime: ${timestamp}`;
            }
            
            // Emergency format - Victim name at the top for immediate clarity
            const mapsLink = `https://maps.google.com/?q=${lat},${lng}`;
            const messageSnippet = message.substring(0, 100);
            
            return `🚨 AllSensesAI Guardian Alert\\n\\nVictim: ${victimName}\\nRisk: ${threatLevel} (Confidence: ${confidence})\\nRecommendation: ${recommendation}\\n\\nMessage: "${messageSnippet}"\\n\\nLocation: ${lat}, ${lng}\\nMap: ${mapsLink}\\nTime: ${timestamp}\\n\\nAction: Call them now. If urgent, contact local emergency services.`;
        }'''
    
    content = re.sub(old_compose_function, new_compose_function, content, flags=re.DOTALL)
    
    # ========== UPDATE Step 5 SMS Preview Panel ==========
    
    # Add victim name line item in the preview metadata section
    old_preview_meta = '''                <div class="sms-preview-meta">
                    <span class="sms-preview-label">To:</span>
                    <span class="sms-preview-value" id="sms-to">—</span>
                </div>'''
    
    new_preview_meta = '''                <div class="sms-preview-meta">
                    <span class="sms-preview-label">Victim Name:</span>
                    <span class="sms-preview-value" id="sms-victim-name">—</span>
                </div>
                <div class="sms-preview-meta">
                    <span class="sms-preview-label">To:</span>
                    <span class="sms-preview-value" id="sms-to">—</span>
                </div>'''
    
    content = content.replace(old_preview_meta, new_preview_meta)
    
    # ========== UPDATE updateSmsPreview() FUNCTION ==========
    
    # Find and update the updateSmsPreview function to populate victim name
    old_update_preview = r'''        function updateSmsPreview\(\) \{
            const name = document\.getElementById\('victimName'\)\.value\.trim\(\) \|\| 'Unknown User';
            const phone = document\.getElementById\('emergencyPhone'\)\.value\.trim\(\) \|\| 'Unknown';'''
    
    new_update_preview = '''        function updateSmsPreview() {
            const victimName = document.getElementById('victimName').value.trim() || 'Unknown User';
            const name = victimName; // Keep for backward compatibility
            const phone = document.getElementById('emergencyPhone').value.trim() || 'Unknown';
            
            // Update victim name in preview UI
            const victimNameEl = document.getElementById('sms-victim-name');
            if (victimNameEl) {
                victimNameEl.textContent = victimName;
            }'''
    
    content = re.sub(old_update_preview, new_update_preview, content)
    
    # ========== ADD PROOF LOGGING ==========
    
    # Update Step 1 completion to log victim name
    old_step1_complete = r'''                // Mark Step 1 complete
                __ALLSENSES_STATE\.configSaved = true;
                addStep1ProofToUI\('\[STEP1\] Configuration saved'\);
                console\.log\('\[STEP1\] Configuration saved'\);'''
    
    new_step1_complete = '''                // Mark Step 1 complete
                __ALLSENSES_STATE.configSaved = true;
                addStep1ProofToUI('[STEP1] Configuration saved');
                addStep1ProofToUI(`[STEP1] Victim name set: "${name}"`);
                console.log('[STEP1] Configuration saved');
                console.log(`[STEP1] Victim name set: "${name}"`);'''
    
    content = re.sub(old_step1_complete, new_step1_complete, content)
    
    # Add proof logging to updateSmsPreview
    old_compose_call = r'''            const smsMessage = composeAlertSms\(payload\);'''
    
    new_compose_call = '''            const smsMessage = composeAlertSms(payload);
            console.log(`[STEP5] SMS composed for: "${victimName}"`);'''
    
    content = re.sub(old_compose_call, new_compose_call, content)
    
    # ========== ADD WARNING FOR MISSING VICTIM NAME ==========
    
    # Add warning display in Step 5 if victim name is missing
    old_preview_panel = '''            <div id="smsPreviewPanel" class="sms-preview-panel">
                <h4>📱 SMS Preview</h4>'''
    
    new_preview_panel = '''            <div id="smsPreviewPanel" class="sms-preview-panel">
                <h4>📱 SMS Preview</h4>
                
                <!-- Warning for missing victim name -->
                <div id="victimNameWarning" class="sms-preview-error" style="display:none;">
                    ⚠️ Victim name missing — using fallback: Unknown User
                </div>'''
    
    content = content.replace(old_preview_panel, new_preview_panel)
    
    # Add logic to show/hide warning in updateSmsPreview
    old_preview_display = r'''            // Display preview
            const previewMessageEl = document\.getElementById\('smsPreviewMessage'\);
            if \(previewMessageEl\) \{
                previewMessageEl\.textContent = smsMessage;
            \}'''
    
    new_preview_display = '''            // Display preview
            const previewMessageEl = document.getElementById('smsPreviewMessage');
            if (previewMessageEl) {
                previewMessageEl.textContent = smsMessage;
            }
            
            // Show/hide victim name warning
            const warningEl = document.getElementById('victimNameWarning');
            if (warningEl) {
                if (victimName === 'Unknown User') {
                    warningEl.style.display = 'block';
                } else {
                    warningEl.style.display = 'none';
                }
            }'''
    
    content = re.sub(old_preview_display, new_preview_display, content)
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Victim name added to SMS preview and sent messages")
    print(f"  Input: {input_file}")
    print(f"  Output: {output_file}")
    print(f"  Build: GEMINI3-VICTIM-NAME-SMS-20260128")
    print(f"\nChanges:")
    print(f"  ✓ Updated composeAlertSms() to include victim name")
    print(f"  ✓ Victim name appears at top of emergency SMS")
    print(f"  ✓ Victim name in standby format")
    print(f"  ✓ Added 'Victim Name' line item in Step 5 preview")
    print(f"  ✓ Added proof logging: [STEP1] Victim name set")
    print(f"  ✓ Added proof logging: [STEP5] SMS composed for")
    print(f"  ✓ Added warning for missing victim name")
    print(f"  ✓ Fallback to 'Unknown User' if name empty")
    print(f"  ✓ Single source of truth: composeAlertSms()")
    print(f"  ✓ Deterministic: preview matches sent message")

if __name__ == '__main__':
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-step1-keywords-fix.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-victim-name-sms.html'
    
    try:
        add_victim_name_to_sms(input_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
