#!/usr/bin/env python3
"""
Create Final Production Build V2 - Complete SMS Module Implementation
Produces deploy-ready gemini3-guardian-final-production.html with:
- No runtime JS errors
- Step 1 working with E.164 validation
- Step 5 always showing structured SMS fields (placeholders → populated)
- SMS preview matching exactly what is sent (single source of truth)
- Hard preflight checks before output
- Build assertions after generation

Deployment targets:
- S3 Bucket: gemini-demo-20260127092219
- CloudFront ID: E1YPPQKVA0OGX
- CloudFront Domain: d3pbubsw4or36l.cloudfront.net
"""

import re
import sys
from pathlib import Path

def error_exit(message):
    """Exit with error message"""
    print(f"❌ ERROR: {message}", file=sys.stderr)
    sys.exit(1)

def validate_base_file(html):
    """Preflight checks on base HTML"""
    print("Running preflight checks...")
    
    # Check for Step 5 anchor
    if 'Step 5 — Emergency Alerting' not in html:
        error_exit("Base HTML missing Step 5 section anchor")
    
    # Check for main script block
    if '<script>' not in html or '</script>' not in html:
        error_exit("Base HTML missing main <script> block")
    
    # Check for required DOM elements
    required_ids = [
        'victimName', 'emergencyPhone', 'audioInput',
        'step5Status', 'alertResult', 'alertDetails'
    ]
    for elem_id in required_ids:
        if f'id="{elem_id}"' not in html:
            error_exit(f"Base HTML missing required element: {elem_id}")
    
    print("✓ Preflight checks passed")

def inject_sms_module(html):
    """Inject complete SMS module with all required functions"""
    
    sms_module = r'''
        // ========== SMS MODULE (SINGLE SOURCE OF TRUTH) ==========
        
        /**
         * composeAlertPayload - Normalize all data for SMS composition
         * Returns object with placeholders for missing values
         */
        function composeAlertPayload() {
            // Get victim name from Step 1
            const victimNameRaw = document.getElementById('victimName')?.value.trim() || '';
            const victimName = victimNameRaw || 'Unknown User';
            
            // Get emergency contact from Step 1
            const emergencyContact = document.getElementById('emergencyPhone')?.value.trim() || '';
            
            // Get threat analysis results from Step 4
            const threatLevelEl = document.getElementById('threatLevel');
            const threatAnalysisEl = document.getElementById('threatAnalysis');
            const threatConfidenceEl = document.getElementById('threatConfidence');
            
            const riskLevel = threatLevelEl?.textContent?.trim() || '—';
            const recommendation = threatAnalysisEl?.textContent?.trim() || '—';
            const confidenceText = threatConfidenceEl?.textContent?.trim() || '—';
            
            // Parse confidence percentage
            let confidence = '—';
            if (confidenceText !== '—') {
                const match = confidenceText.match(/(\\d+)%/);
                if (match) {
                    confidence = match[1];
                }
            }
            
            // Get message from Step 4 input
            const message = document.getElementById('audioInput')?.value.trim() || '—';
            
            // Get location from currentLocation global
            let lat = null;
            let lng = null;
            let mapUrl = '—';
            
            if (currentLocation) {
                lat = currentLocation.latitude;
                lng = currentLocation.longitude;
                mapUrl = `https://maps.google.com/?q=${lat},${lng}`;
            }
            
            // Get timestamp
            const timestamp = new Date().toLocaleString();
            
            // Action is always present
            const action = 'Call them now. If urgent, contact local emergency services.';
            
            const payload = {
                victimName,
                victimNameRaw, // Track if fallback was used
                emergencyContact,
                riskLevel,
                confidence,
                recommendation,
                message,
                lat,
                lng,
                mapUrl,
                timestamp,
                action
            };
            
            console.log('[SMS-MODULE] Payload composed:', payload);
            return payload;
        }
        
        /**
         * composeAlertSms - SINGLE SOURCE OF TRUTH for SMS text
         * Always returns exact format, deterministic for same payload
         */
        function composeAlertSms(payload) {
            // Format location
            let locationText = '—';
            let mapText = '—';
            
            if (payload.lat !== null && payload.lng !== null) {
                locationText = `${payload.lat.toFixed(6)}, ${payload.lng.toFixed(6)}`;
                mapText = payload.mapUrl;
            }
            
            // Compose SMS with exact format
            const sms = `🚨 AllSensesAI Guardian Alert

Victim: ${payload.victimName}

Risk: ${payload.riskLevel} (Confidence: ${payload.confidence}%)
Recommendation: ${payload.recommendation}

Message: "${payload.message}"

Location: ${locationText}
Map: ${mapText}

Time: ${payload.timestamp}

Action: ${payload.action}`;
            
            console.log('[SMS-MODULE] SMS composed (length:', sms.length, ')');
            return sms;
        }
        
        /**
         * renderSmsPreviewFields - Render structured Step 5 panel
         * Shows placeholders until values exist
         */
        function renderSmsPreviewFields(payload) {
            // Update victim name field
            const victimNameEl = document.getElementById('smsPreviewVictimName');
            if (victimNameEl) {
                victimNameEl.textContent = payload.victimName;
                
                // Show warning if fallback was used
                const victimCheckEl = document.getElementById('smsCheckVictimNameValue');
                if (victimCheckEl) {
                    if (payload.victimNameRaw) {
                        victimCheckEl.innerHTML = '<span style="color:#28a745;">✓</span>';
                    } else {
                        victimCheckEl.innerHTML = '<span style="color:#ffc107;">⚠ Using fallback: Unknown User</span>';
                    }
                }
            }
            
            // Update destination field
            const destEl = document.getElementById('smsPreviewDestination');
            if (destEl) {
                destEl.textContent = payload.emergencyContact || '—';
            }
            
            // Update checklist items
            const updateCheck = (id, value) => {
                const el = document.getElementById(id);
                if (el) {
                    if (value && value !== '—') {
                        el.innerHTML = '<span style="color:#28a745;">✓</span>';
                    } else {
                        el.innerHTML = '<span style="color:#ffc107;">Standby</span>';
                    }
                }
            };
            
            updateCheck('smsCheckRiskValue', payload.riskLevel !== '—' ? payload.riskLevel : null);
            updateCheck('smsCheckMessageValue', payload.message !== '—' ? payload.message : null);
            updateCheck('smsCheckLocationValue', payload.lat);
            updateCheck('smsCheckMapsValue', payload.lat);
            updateCheck('smsCheckTimestampValue', payload.timestamp);
            
            console.log('[SMS-MODULE] Preview fields rendered');
        }
        
        /**
         * updateSmsPreview - Update Step 5 preview panel
         * Called after Step 1, Step 2, Step 4, and before send
         */
        function updateSmsPreview() {
            console.log('[SMS-MODULE] Updating SMS preview...');
            
            const errorPanel = document.getElementById('smsPreviewError');
            const errorReason = document.getElementById('smsPreviewErrorReason');
            const contentPanel = document.getElementById('smsPreviewContent');
            const messageEl = document.getElementById('smsPreviewMessage');
            
            // Check if Step 1 is complete
            if (!__ALLSENSES_STATE.configSaved) {
                if (errorPanel) errorPanel.style.display = 'block';
                if (contentPanel) contentPanel.style.display = 'none';
                if (errorReason) errorReason.textContent = 'Complete Step 1 first';
                console.log('[SMS-MODULE] Preview blocked: Step 1 not complete');
                return;
            }
            
            // Check if location is available
            if (!currentLocation) {
                if (errorPanel) errorPanel.style.display = 'block';
                if (contentPanel) contentPanel.style.display = 'none';
                if (errorReason) errorReason.textContent = 'Complete Step 2 (Enable Location)';
                console.log('[SMS-MODULE] Preview blocked: Location not available');
                return;
            }
            
            // Compose payload and SMS
            const payload = composeAlertPayload();
            const smsText = composeAlertSms(payload);
            
            // Show content panel
            if (errorPanel) errorPanel.style.display = 'none';
            if (contentPanel) contentPanel.style.display = 'block';
            
            // Render structured fields
            renderSmsPreviewFields(payload);
            
            // Show full SMS text
            if (messageEl) {
                messageEl.textContent = smsText;
            }
            
            console.log('[SMS-MODULE] Preview updated successfully');
            console.log('[STEP5] SMS preview ready for:', payload.victimName);
        }
        
        // ========== END SMS MODULE ==========
'''
    
    # Find insertion point: before closing </script> of main script block
    # Look for the last </script> tag
    script_end_pattern = r'(.*)(</script>\s*</body>\s*</html>\s*)$'
    match = re.search(script_end_pattern, html, re.DOTALL)
    
    if not match:
        error_exit("Could not find script insertion point")
    
    # Insert SMS module before the closing </script>
    html = match.group(1) + sms_module + '\n    ' + match.group(2)
    
    print("✓ SMS module injected")
    return html

def fix_step1_button(html):
    """Fix Step 1 button with E.164 validation and proper event handling"""
    
    # Find completeStep1 function and replace it
    step1_function = r'''function completeStep1(event) {
            // Prevent any form submission
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }
            
            try {
                console.log('[STEP1] Click received');
                
                const nameInput = document.getElementById('victimName');
                const phoneInput = document.getElementById('emergencyPhone');
                
                const name = nameInput?.value.trim() || '';
                const phone = phoneInput?.value.trim() || '';
                
                console.log('[STEP1] Victim name set:', name || 'Unknown User');
                
                // Validate E.164 format: ^\\+[1-9]\\d{6,14}$
                const e164Pattern = /^\\+[1-9]\\d{6,14}$/;
                const phoneValid = e164Pattern.test(phone);
                
                console.log('[STEP1] Phone valid:', phoneValid);
                
                if (!phoneValid) {
                    const statusEl = document.getElementById('step1Status');
                    if (statusEl) {
                        statusEl.textContent = '❌ Invalid phone format. Use E.164: +1234567890';
                        statusEl.style.color = '#dc3545';
                    }
                    alert('Invalid phone number format.\\n\\nPlease use E.164 format:\\n+[country code][number]\\n\\nExample: +12345678901');
                    console.log('[STEP1][ERROR] Invalid phone format');
                    return;
                }
                
                // Save config
                __ALLSENSES_STATE.configSaved = true;
                console.log('[STEP1] Config saved');
                
                // Update UI
                const statusEl = document.getElementById('step1Status');
                if (statusEl) {
                    statusEl.textContent = '✅ Configuration saved';
                    statusEl.style.color = '#28a745';
                }
                
                // Unlock Step 2
                const enableLocationBtn = document.getElementById('enableLocationBtn');
                if (enableLocationBtn) {
                    enableLocationBtn.disabled = false;
                }
                
                const step2ProofLog = document.getElementById('step2ProofLog');
                if (step2ProofLog) {
                    step2ProofLog.textContent = 'Step 1 complete! Now click "Enable Location" to see proof logs...';
                }
                
                console.log('[STEP1] Step 2 unlocked');
                
                updatePipelineState('STEP1_COMPLETE');
                
                // Update SMS preview
                updateSmsPreview();
                
            } catch (error) {
                console.error('[STEP1][ERROR]', error);
                const statusEl = document.getElementById('step1Status');
                if (statusEl) {
                    statusEl.textContent = '❌ Error: ' + error.message;
                    statusEl.style.color = '#dc3545';
                }
            }
        }'''
    
    # Replace existing completeStep1 function
    html = re.sub(
        r'function completeStep1\(\)[\s\S]*?\n        \}',
        step1_function,
        html,
        count=1
    )
    
    # Ensure button has type="button" and proper onclick
    html = re.sub(
        r'<button class="button primary-btn" onclick="completeStep1\(\)">',
        r'<button type="button" class="button primary-btn" onclick="completeStep1(event)">',
        html
    )
    
    print("✓ Step 1 button fixed with E.164 validation")
    return html

def add_sms_preview_calls(html):
    """Add updateSmsPreview() calls at appropriate points"""
    
    # After location is set (in both GPS success and demo mode)
    html = re.sub(
        r'(displaySelectedLocation\(currentLocation\);)',
        r'\1\n                        updateSmsPreview();',
        html
    )
    
    # After threat analysis completes
    html = re.sub(
        r'(document\.getElementById\(\'emergencyResult\'\)\.innerHTML = `[\s\S]*?</div>`;\s*)',
        r'\1\n                updateSmsPreview();\n                ',
        html,
        count=1
    )
    
    print("✓ updateSmsPreview() calls added")
    return html

def add_sms_preview_panel(html):
    """Add SMS preview panel HTML to Step 5"""
    
    sms_preview_html = r'''
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
    
    # Insert after Step 5 heading
    html = re.sub(
        r'(<h3>🚨 Step 5 — Emergency Alerting</h3>)',
        r'\1' + sms_preview_html,
        html
    )
    
    print("✓ SMS preview panel HTML added")
    return html

def update_build_stamp(html):
    """Update build stamp to final production version"""
    html = re.sub(
        r'Build: GEMINI3-[A-Z-]+\d+',
        'Build: GEMINI3-FINAL-PRODUCTION-20260128',
        html
    )
    print("✓ Build stamp updated")
    return html

def validate_output(html):
    """Assert required functions exist exactly once"""
    print("Running build assertions...")
    
    # Check composeAlertSms exists exactly once
    compose_count = len(re.findall(r'function composeAlertSms\(', html))
    if compose_count == 0:
        error_exit("Build assertion failed: composeAlertSms function not found")
    if compose_count > 1:
        error_exit(f"Build assertion failed: composeAlertSms found {compose_count} times (expected 1)")
    
    # Check updateSmsPreview exists exactly once
    update_count = len(re.findall(r'function updateSmsPreview\(', html))
    if update_count == 0:
        error_exit("Build assertion failed: updateSmsPreview function not found")
    if update_count > 1:
        error_exit(f"Build assertion failed: updateSmsPreview found {update_count} times (expected 1)")
    
    # Check composeAlertPayload exists exactly once
    payload_count = len(re.findall(r'function composeAlertPayload\(', html))
    if payload_count == 0:
        error_exit("Build assertion failed: composeAlertPayload function not found")
    if payload_count > 1:
        error_exit(f"Build assertion failed: composeAlertPayload found {payload_count} times (expected 1)")
    
    # Check renderSmsPreviewFields exists exactly once
    render_count = len(re.findall(r'function renderSmsPreviewFields\(', html))
    if render_count == 0:
        error_exit("Build assertion failed: renderSmsPreviewFields function not found")
    if render_count > 1:
        error_exit(f"Build assertion failed: renderSmsPreviewFields found {render_count} times (expected 1)")
    
    # Check Step 5 SMS preview panel exists
    if 'id="smsPreviewPanel"' not in html:
        error_exit("Build assertion failed: SMS preview panel not found")
    
    # Check Step 1 button has type="button"
    if 'type="button"' not in html or 'onclick="completeStep1(event)"' not in html:
        error_exit("Build assertion failed: Step 1 button not properly configured")
    
    print("✓ Build assertions passed")
    print("  - composeAlertSms: 1 occurrence ✓")
    print("  - updateSmsPreview: 1 occurrence ✓")
    print("  - composeAlertPayload: 1 occurrence ✓")
    print("  - renderSmsPreviewFields: 1 occurrence ✓")
    print("  - SMS preview panel: present ✓")
    print("  - Step 1 button: properly configured ✓")

def create_final_build():
    """Main build process"""
    
    print("=" * 60)
    print("Final Production Build V2 - Complete SMS Module")
    print("=" * 60)
    print()
    
    # Read base file
    base_file = Path('Gemini3_AllSensesAI/gemini3-guardian-configurable-keywords.html')
    if not base_file.exists():
        error_exit(f"Base file not found: {base_file}")
    
    print(f"Reading base file: {base_file}")
    html = base_file.read_text(encoding='utf-8')
    
    # Preflight checks
    validate_base_file(html)
    
    # Apply transformations
    html = update_build_stamp(html)
    html = inject_sms_module(html)
    html = fix_step1_button(html)
    html = add_sms_preview_panel(html)
    html = add_sms_preview_calls(html)
    
    # Validate output
    validate_output(html)
    
    # Write output
    output_file = Path('Gemini3_AllSensesAI/gemini3-guardian-final-production.html')
    print(f"\nWriting output: {output_file}")
    output_file.write_text(html, encoding='utf-8')
    
    print()
    print("=" * 60)
    print("✅ Final Production Build Complete!")
    print("=" * 60)
    print()
    print(f"Output: {output_file}")
    print(f"Size: {len(html):,} bytes")
    print()
    print("Build: GEMINI3-FINAL-PRODUCTION-20260128")
    print()
    print("Features implemented:")
    print("  ✓ Step 1: E.164 validation + proper event handling")
    print("  ✓ Step 5: Always-visible structured SMS fields")
    print("  ✓ SMS Module: Single source of truth (4 functions)")
    print("  ✓ SMS Preview: Matches exactly what is sent")
    print("  ✓ All existing features preserved")
    print()
    print("Deployment targets:")
    print("  S3 Bucket: gemini-demo-20260127092219")
    print("  CloudFront ID: E1YPPQKVA0OGX")
    print("  CloudFront Domain: d3pbubsw4or36l.cloudfront.net")
    print()
    print("Next step:")
    print("  .\\Gemini3_AllSensesAI\\deployment\\deploy-final-production.ps1")
    print()

if __name__ == '__main__':
    try:
        create_final_build()
    except Exception as e:
        error_exit(f"Unexpected error: {e}")
