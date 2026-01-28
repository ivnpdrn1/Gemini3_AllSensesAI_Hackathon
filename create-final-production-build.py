#!/usr/bin/env python3
"""
Create Final Production Build - Comprehensive Merge
Combines all fixes into one production-ready build:
1. Step 1 button fix (from step1-keywords-fix)
2. Step 5 always-visible structured fields (from sms-preview-complete)
3. Victim name in SMS (from victim-name-enhanced)
4. All existing features from configurable-keywords

Uses CORRECT deployment targets:
- S3 Bucket: gemini-demo-20260127092219
- CloudFront ID: E1YPPQKVA0OGX
- CloudFront Domain: d3pbubsw4or36l.cloudfront.net
"""

import re
import sys

def create_final_build():
    """Create the final production build with all fixes merged"""
    
    # Read the current production file (configurable-keywords)
    print("Reading current production file...")
    with open('Gemini3_AllSensesAI/gemini3-guardian-configurable-keywords.html', 'r', encoding='utf-8') as f:
        html = f.read()
    
    print("Applying fixes...")
    
    # Fix 1: Update build stamp
    html = re.sub(
        r'Build: GEMINI3-CONFIGURABLE-KEYWORDS-\d+',
        'Build: GEMINI3-FINAL-PRODUCTION-20260128',
        html
    )
    
    # Fix 2: Ensure Step 1 button is properly bound (already present in configurable-keywords)
    # This is already correct in the source file
    
    # Fix 3: Add victim name to SMS composition
    # Find composeAlertSms function and add victim name normalization
    compose_pattern = r'(function composeAlertSms\(payload\) \{[\s\S]*?)(// Validate required fields)'
    
    def add_victim_normalization(match):
        return match.group(1) + '''// Normalize victim name with fallback
            const victimName = (payload.victimName || '').trim() || 'Unknown User';
            payload.victimName = victimName;
            
            ''' + match.group(2)
    
    html = re.sub(compose_pattern, add_victim_normalization, html)
    
    # Fix 4: Change "Contact:" to "Victim:" in SMS messages
    html = html.replace(
        'Contact: ${payload.victimName}',
        'Victim: ${payload.victimName}'
    )
    
    # Fix 5: Add Step 5 SMS Preview Panel with always-visible structured fields
    # Find Step 5 section and add comprehensive SMS preview
    step5_pattern = r'(<h3>🚨 Step 5 — Emergency Alerting</h3>)'
    
    step5_preview_panel = r'''\1
            
            <!-- SMS Preview Panel (Always Visible) -->
            <div id="smsPreviewPanel" class="sms-preview-panel">
                <h4>📱 SMS Preview (what your emergency contact will receive)</h4>
                
                <div id="smsPreviewError" class="sms-preview-error" style="display:none;">
                    Cannot generate SMS yet: <span id="smsPreviewErrorReason">—</span>
                </div>
                
                <div id="smsPreviewContent" style="display:none;">
                    <div class="sms-preview-meta">
                        <span class="sms-preview-label">Victim Name:</span>
                        <span class="sms-preview-value" id="smsPreviewVictimName">—</span>
                    </div>
                    <div class="sms-preview-meta">
                        <span class="sms-preview-label">Destination:</span>
                        <span class="sms-preview-value" id="smsPreviewDestination">—</span>
                    </div>
                    
                    <div class="sms-preview-message" id="smsPreviewMessage">
                        (SMS preview will appear here after threat analysis)
                    </div>
                    
                    <div class="sms-preview-checklist">
                        <h5>✓ Data Included:</h5>
                        <ul>
                            <li id="smsCheckIdentity">Product identity: <span style="color:#28a745;">✓</span></li>
                            <li id="smsCheckVictimName">Victim name: <span id="smsCheckVictimNameValue">—</span></li>
                            <li id="smsCheckRisk">Risk summary: <span id="smsCheckRiskValue">—</span></li>
                            <li id="smsCheckMessage">Victim message: <span id="smsCheckMessageValue">—</span></li>
                            <li id="smsCheckLocation">Location coordinates: <span id="smsCheckLocationValue">—</span></li>
                            <li id="smsCheckMaps">Google Maps link: <span id="smsCheckMapsValue">—</span></li>
                            <li id="smsCheckTimestamp">Timestamp: <span id="smsCheckTimestampValue">—</span></li>
                            <li id="smsCheckAction">Next action instruction: <span style="color:#28a745;">✓</span></li>
                        </ul>
                    </div>
                </div>
                
                <div id="smsPreviewSent" class="sms-preview-sent" style="display:none;">
                    <h5>✅ Sent Message:</h5>
                    <div class="sms-preview-message" id="smsPreviewSentMessage">—</div>
                    <div class="sms-preview-timestamp">Sent at: <span id="smsPreviewSentTime">—</span></div>
                </div>
            </div>
'''
    
    html = re.sub(step5_pattern, step5_preview_panel, html)
    
    # Fix 6: Add SMS preview CSS if not present
    if '.sms-preview-panel' not in html:
        sms_css = '''
        /* SMS Preview Panel */
        .sms-preview-panel { background: #f8f9fa; border: 2px solid #007bff; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .sms-preview-panel h4 { margin: 0 0 15px 0; color: #007bff; font-size: 1.1em; }
        .sms-preview-message { background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; font-family: 'Courier New', monospace; font-size: 0.9em; line-height: 1.6; white-space: pre-wrap; color: #212529; margin: 15px 0; }
        .sms-preview-meta { display: grid; grid-template-columns: 140px 1fr; gap: 8px; margin: 10px 0; font-size: 0.9em; }
        .sms-preview-label { font-weight: bold; color: #555; }
        .sms-preview-value { color: #2c3e50; font-family: monospace; }
        .sms-preview-checklist { background: #e7f3ff; padding: 12px; border-radius: 6px; margin: 10px 0; }
        .sms-preview-checklist h5 { margin: 0 0 8px 0; font-size: 0.95em; color: #0056b3; }
        .sms-preview-checklist ul { margin: 5px 0; padding-left: 20px; }
        .sms-preview-checklist li { margin: 4px 0; font-size: 0.9em; color: #495057; }
        .sms-preview-error { background: #f8d7da; border: 2px solid #dc3545; padding: 15px; border-radius: 8px; color: #721c24; font-weight: bold; margin: 15px 0; }
        .sms-preview-sent { background: #d4edda; border: 2px solid #28a745; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .sms-preview-sent h5 { margin: 0 0 10px 0; color: #155724; font-size: 1em; }
        .sms-preview-timestamp { font-size: 0.85em; color: #666; margin-top: 10px; }
'''
        # Insert before </style>
        html = html.replace('</style>', sms_css + '\n    </style>')
    
    # Fix 7: Add updateSmsPreview function
    # Find a good place to insert it (after composeAlertSms)
    update_sms_preview_func = '''
        // ========== SMS PREVIEW UPDATE ==========
        function updateSmsPreview() {
            const victimName = document.getElementById('victimName')?.value.trim();
            const emergencyContact = document.getElementById('emergencyPhone')?.value.trim();
            const transcript = document.getElementById('audioInput')?.value.trim();
            
            // Get threat analysis result
            const threatLevel = document.getElementById('threatLevel')?.textContent;
            const threatAnalysis = document.getElementById('threatAnalysis')?.textContent;
            
            // Check if we have required data
            const hasConfig = __ALLSENSES_STATE.configSaved && victimName && emergencyContact;
            const hasLocation = currentLocation !== null;
            
            const errorPanel = document.getElementById('smsPreviewError');
            const errorReason = document.getElementById('smsPreviewErrorReason');
            const contentPanel = document.getElementById('smsPreviewContent');
            
            if (!hasConfig) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Complete Step 1 first';
                return;
            }
            
            if (!hasLocation) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Complete Step 2 (Enable Location)';
                return;
            }
            
            // Compose SMS with available data
            const payload = {
                victimName: victimName,
                emergencyContact: emergencyContact,
                location: currentLocation,
                threatLevel: threatLevel || null,
                reasoning: threatAnalysis || null,
                transcript: transcript || ''
            };
            
            const result = composeAlertSms(payload);
            
            if (result.error) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = result.error;
                return;
            }
            
            // Display preview
            errorPanel.style.display = 'none';
            contentPanel.style.display = 'block';
            
            // Display victim name
            const displayVictimName = victimName || 'Unknown User';
            document.getElementById('smsPreviewVictimName').textContent = displayVictimName;
            document.getElementById('smsCheckVictimNameValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            
            if (!victimName) {
                document.getElementById('smsCheckVictimNameValue').innerHTML = '<span style="color:#ffc107;">⚠ Using fallback: Unknown User</span>';
            }
            
            document.getElementById('smsPreviewDestination').textContent = emergencyContact;
            document.getElementById('smsPreviewMessage').textContent = result.message;
            
            // Update checklist
            if (result.isEmergency) {
                document.getElementById('smsCheckRiskValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckMessageValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckLocationValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckMapsValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckTimestampValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            } else {
                document.getElementById('smsCheckRiskValue').innerHTML = '<span style="color:#ffc107;">Standby</span>';
                document.getElementById('smsCheckMessageValue').innerHTML = '<span style="color:#ffc107;">Standby</span>';
                document.getElementById('smsCheckLocationValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckMapsValue').innerHTML = '<span style="color:#28a745;">✓</span>';
                document.getElementById('smsCheckTimestampValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            }
            
            console.log('[STEP5] SMS composed for:', displayVictimName);
            console.log('[SMS-PREVIEW] Preview updated successfully (emergency:', result.isEmergency, ')');
        }
'''
    
    # Insert after composeAlertSms function
    html = re.sub(
        r'(function composeAlertSms\(payload\)[\s\S]*?\n        \})',
        r'\1\n' + update_sms_preview_func,
        html,
        count=1
    )
    
    # Fix 8: Add calls to updateSmsPreview in appropriate places
    # After Step 1 completion
    html = re.sub(
        r'(console\.log\(\'\[STEP1\] Step 1 complete)',
        r'updateSmsPreview();\n                \1',
        html
    )
    
    # After location is set
    html = re.sub(
        r'(displaySelectedLocation\(currentLocation\);)',
        r'\1\n                        updateSmsPreview();',
        html
    )
    
    # After threat analysis
    html = re.sub(
        r'(if \(result\.risk_level === \'HIGH\' \|\| result\.risk_level === \'CRITICAL\'\) \{)',
        r'updateSmsPreview();\n                    \1',
        html
    )
    
    print("Writing final production build...")
    with open('Gemini3_AllSensesAI/gemini3-guardian-final-production.html', 'w', encoding='utf-8') as f:
        f.write(html)
    
    print("✅ Final production build created!")
    print("\nFile: Gemini3_AllSensesAI/gemini3-guardian-final-production.html")
    print("Build: GEMINI3-FINAL-PRODUCTION-20260128")
    print("\nFixes applied:")
    print("  ✓ Step 1 button fix (already present)")
    print("  ✓ Step 5 always-visible structured fields")
    print("  ✓ Victim name in SMS preview and sent message")
    print("  ✓ All existing features preserved")
    print("\nDeployment targets:")
    print("  S3 Bucket: gemini-demo-20260127092219")
    print("  CloudFront ID: E1YPPQKVA0OGX")
    print("  CloudFront Domain: d3pbubsw4or36l.cloudfront.net")

if __name__ == '__main__':
    try:
        create_final_build()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
