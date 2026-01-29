#!/usr/bin/env python3
"""
Build Script: Gemini3 Guardian Jury-Ready VIDEO + SMS Build
Adds REAL SMS sending capability to the baseline video build

Build ID: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2

Changes from v1:
- Simplified API contract: {to, message, buildId, meta} instead of flat structure
- Updated response handling: toMasked, errorMessage fields
- Improved international SMS support (Colombia +57)

Changes from baseline:
1. Add SMS_API_URL constant (placeholder, updated by deployment script)
2. Add Delivery Proof panel in Step 5
3. Add manual "Send Test SMS" button
4. Add sendSms() function using fetch()
5. Hook into emergency trigger workflow
6. Add proof logging: [SMS][REQUEST], [SMS][SUCCESS], [SMS][ERROR]
7. Update Build ID

Zero regressions: All baseline functionality preserved.
"""

import re
import sys
from pathlib import Path

# Build configuration
BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2"
BASELINE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video.html"
OUTPUT_FILE = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video-sms.html"

# SMS API URL placeholder (will be replaced by deployment script)
SMS_API_URL_PLACEHOLDER = "https://YOUR_API_GATEWAY_URL_HERE/prod/send-sms"


def read_baseline():
    """Read baseline HTML file"""
    baseline_path = Path(BASELINE_FILE)
    if not baseline_path.exists():
        print(f"❌ ERROR: Baseline file not found: {BASELINE_FILE}")
        sys.exit(1)
    
    with open(baseline_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"✅ Read baseline: {BASELINE_FILE} ({len(content)} bytes)")
    return content


def update_build_id(html):
    """Update Build ID in 2 locations"""
    # Location 1: Top stamp
    html = re.sub(
        r'Build: GEMINI3-JURY-READY-VIDEO-20260128-v1',
        f'Build: {BUILD_ID}',
        html
    )
    
    # Location 2: Runtime Health Check
    html = re.sub(
        r'Loaded Build ID.*?GEMINI3-JURY-READY-VIDEO-20260128-v1',
        f'Loaded Build ID</div>\n                    <div class="health-value" style="font-family: monospace; font-size: 12px;">{BUILD_ID}',
        html
    )
    
    print(f"✅ Updated Build ID to: {BUILD_ID}")
    return html


def add_sms_api_constant(html):
    """Add SMS_API_URL constant after DOMContentLoaded"""
    # Find the DOMContentLoaded event listener
    pattern = r"(window\.addEventListener\('DOMContentLoaded', \(\) => \{)"
    
    sms_constant = f"""
        // ========== SMS API CONFIGURATION ==========
        const SMS_API_URL = '{SMS_API_URL_PLACEHOLDER}';
        console.log('[SMS-CONFIG] API URL:', SMS_API_URL);
        
"""
    
    replacement = r"\1" + sms_constant
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Added SMS_API_URL constant")
    return html


def add_delivery_proof_panel(html):
    """Add Delivery Proof panel in Step 5 after SMS preview"""
    delivery_panel = """
            <!-- NEW: SMS Delivery Proof Panel -->
            <div id="smsDeliveryProofPanel" class="sms-preview-panel" style="background: #e8f5e9; border-color: #4caf50; display:none;">
                <h4>📡 SMS Delivery Proof</h4>
                <div class="sms-preview-description">
                    Real-time delivery status for emergency SMS alerts.
                </div>
                
                <div class="sms-preview-fields">
                    <div class="sms-field">
                        <span class="sms-field-label">Status:</span>
                        <span class="sms-field-value" id="sms-delivery-status">NOT_SENT</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Destination:</span>
                        <span class="sms-field-value" id="sms-delivery-destination">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Timestamp:</span>
                        <span class="sms-field-value" id="sms-delivery-timestamp">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Message ID:</span>
                        <span class="sms-field-value" id="sms-delivery-message-id">—</span>
                    </div>
                </div>
                
                <div id="smsDeliveryError" style="background: #f8d7da; padding: 12px; border-radius: 5px; margin: 10px 0; display:none;">
                    <strong>❌ Delivery Failed:</strong><br>
                    <span id="smsDeliveryErrorText"></span>
                </div>
            </div>
            
            <!-- NEW: Manual Test SMS Button -->
            <div id="manualSmsTestSection" style="margin: 15px 0; display:none;">
                <button type="button" class="button secondary-btn" onclick="sendTestSms()">📤 Send Test SMS</button>
                <div class="note">Test SMS delivery to your emergency contact (Step 1 must be complete)</div>
            </div>
            
"""
    
    # Insert after SMS preview panel
    pattern = r'(</div>\s*<div id="step5Status")'
    replacement = delivery_panel + r'\1'
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Added Delivery Proof panel and Test SMS button")
    return html


def add_sms_functions(html):
    """Add SMS sending functions before closing script tag"""
    sms_functions = """
        // ========== SMS SENDING FUNCTIONS ==========
        
        /**
         * Send SMS via backend API
         * @param {Object} payload - Alert payload from composeAlertPayload()
         * @returns {Promise<Object>} - {ok: boolean, messageId?: string, error?: string}
         */
        async function sendSms(payload) {
            console.log('[SMS][REQUEST] Sending SMS to backend...', payload);
            
            // Update delivery status
            updateDeliveryStatus('SENDING', payload.emergencyPhone);
            
            try {
                // Compose SMS text (single source of truth)
                const smsText = composeAlertSms(payload);
                
                // Prepare request body (simplified contract for v2)
                const requestBody = {
                    to: payload.emergencyPhone,  // E.164 format
                    message: smsText,  // Single source of truth
                    buildId: BUILD_ID,
                    meta: {
                        victimName: payload.victim,
                        risk: payload.risk,
                        confidence: document.getElementById('threatConfidence')?.textContent || '—',
                        recommendation: payload.recommendation,
                        triggerMessage: payload.message,
                        lat: currentLocation?.latitude || 0,
                        lng: currentLocation?.longitude || 0,
                        mapUrl: payload.map,
                        timestampIso: new Date().toISOString(),
                        action: payload.action
                    }
                };
                
                console.log('[SMS][REQUEST] Request body:', requestBody);
                
                // Send to backend
                const response = await fetch(SMS_API_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(requestBody)
                });
                
                const result = await response.json();
                
                if (result.ok) {
                    console.log('[SMS][SUCCESS] SMS sent successfully:', result);
                    updateDeliveryStatus('SENT', result.toMasked, result.timestamp, result.messageId);
                    return { ok: true, messageId: result.messageId };
                } else {
                    console.error('[SMS][ERROR] SMS sending failed:', result.errorMessage);
                    updateDeliveryStatus('FAILED', payload.emergencyPhone, null, null, result.errorMessage);
                    return { ok: false, error: result.errorMessage };
                }
                
            } catch (error) {
                console.error('[SMS][ERROR] Network error:', error);
                updateDeliveryStatus('FAILED', payload.emergencyPhone, null, null, error.message);
                return { ok: false, error: error.message };
            }
        }
        
        /**
         * Update SMS delivery status in UI
         */
        function updateDeliveryStatus(status, destination, timestamp, messageId, errorText) {
            // Show delivery proof panel
            const panel = document.getElementById('smsDeliveryProofPanel');
            if (panel) panel.style.display = 'block';
            
            // Update status
            const statusEl = document.getElementById('sms-delivery-status');
            if (statusEl) {
                statusEl.textContent = status;
                statusEl.style.fontWeight = 'bold';
                
                // Color coding
                if (status === 'SENT') {
                    statusEl.style.color = '#28a745';
                } else if (status === 'SENDING') {
                    statusEl.style.color = '#ffc107';
                } else if (status === 'FAILED') {
                    statusEl.style.color = '#dc3545';
                } else {
                    statusEl.style.color = '#6c757d';
                }
            }
            
            // Update destination (masked)
            const destEl = document.getElementById('sms-delivery-destination');
            if (destEl) destEl.textContent = destination || '—';
            
            // Update timestamp
            const timeEl = document.getElementById('sms-delivery-timestamp');
            if (timeEl) timeEl.textContent = timestamp || '—';
            
            // Update message ID
            const msgIdEl = document.getElementById('sms-delivery-message-id');
            if (msgIdEl) msgIdEl.textContent = messageId || '—';
            
            // Show/hide error
            const errorDiv = document.getElementById('smsDeliveryError');
            const errorTextEl = document.getElementById('smsDeliveryErrorText');
            if (errorDiv && errorTextEl) {
                if (errorText) {
                    errorDiv.style.display = 'block';
                    errorTextEl.textContent = errorText;
                } else {
                    errorDiv.style.display = 'none';
                }
            }
            
            console.log('[SMS][UI] Delivery status updated:', { status, destination, timestamp, messageId, errorText });
        }
        
        /**
         * Send test SMS (manual trigger)
         */
        async function sendTestSms() {
            console.log('[SMS][TEST] Manual test SMS triggered');
            
            // Check if Step 1 is complete
            if (!__ALLSENSES_STATE.configSaved) {
                alert('Please complete Step 1 (Configuration) first');
                return;
            }
            
            // Compose payload
            const payload = composeAlertPayload();
            
            // Validate phone number
            if (!payload.emergencyPhone || payload.emergencyPhone === 'Not provided') {
                alert('Please enter a valid emergency contact phone number in Step 1');
                return;
            }
            
            // Confirm with user
            const confirmed = confirm(`Send test SMS to ${payload.emergencyPhone}?\\n\\nThis will send a real SMS message.`);
            if (!confirmed) {
                console.log('[SMS][TEST] User cancelled test SMS');
                return;
            }
            
            // Send SMS
            const result = await sendSms(payload);
            
            if (result.ok) {
                alert(`✅ Test SMS sent successfully!\\n\\nMessage ID: ${result.messageId}`);
            } else {
                alert(`❌ Test SMS failed:\\n\\n${result.error}`);
            }
        }
        
"""
    
    # Insert before closing </script> tag
    pattern = r'(</script>\s*</body>)'
    replacement = sms_functions + r'\1'
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Added SMS sending functions")
    return html


def hook_emergency_trigger(html):
    """Hook SMS sending into emergency trigger workflow"""
    # Find the triggerGemini3Analysis function and add SMS sending after threat analysis
    # We'll add it after the updateSmsPreview() call
    
    pattern = r"(updateSmsPreview\(\);)"
    
    sms_trigger_code = r"""\1
                
                // NEW: Trigger SMS sending if HIGH or CRITICAL risk
                if (threatLevel === 'HIGH' || threatLevel === 'CRITICAL') {
                    console.log('[SMS][AUTO-TRIGGER] High/Critical risk detected, sending SMS...');
                    const smsPayload = composeAlertPayload();
                    sendSms(smsPayload).then(result => {
                        if (result.ok) {
                            console.log('[SMS][AUTO-TRIGGER] SMS sent successfully');
                        } else {
                            console.error('[SMS][AUTO-TRIGGER] SMS sending failed:', result.error);
                        }
                    });
                }"""
    
    html = re.sub(pattern, sms_trigger_code, html, count=1)
    
    print("✅ Hooked SMS sending into emergency trigger")
    return html


def show_test_button_after_step1(html):
    """Show manual test SMS button after Step 1 completion"""
    pattern = r"(__ALLSENSES_STATE\.configSaved = true;)"
    
    show_button_code = r"""\1
            
            // NEW: Show manual test SMS button
            const manualSmsSection = document.getElementById('manualSmsTestSection');
            if (manualSmsSection) manualSmsSection.style.display = 'block';"""
    
    html = re.sub(pattern, show_button_code, html, count=1)
    
    print("✅ Added logic to show test SMS button after Step 1")
    return html


def add_build_constant(html):
    """Add BUILD_ID constant for SMS payload"""
    pattern = r"(const SMS_API_URL = )"
    
    build_constant = r"const BUILD_ID = '" + BUILD_ID + r"';\n        \1"
    
    html = re.sub(pattern, build_constant, html, count=1)
    
    print("✅ Added BUILD_ID constant")
    return html


def validate_build(html):
    """Validate that all required elements are present"""
    print("\n🔍 Validating build...")
    
    required_elements = [
        BUILD_ID,
        'SMS_API_URL',
        'smsDeliveryProofPanel',
        'manualSmsTestSection',
        'async function sendSms',
        'function updateDeliveryStatus',
        'function sendTestSms',
        '[SMS][REQUEST]',
        '[SMS][SUCCESS]',
        '[SMS][ERROR]'
    ]
    
    missing = []
    for element in required_elements:
        if element not in html:
            missing.append(element)
    
    if missing:
        print(f"❌ VALIDATION FAILED - Missing elements:")
        for item in missing:
            print(f"   - {item}")
        return False
    
    print("✅ All required elements present")
    return True


def write_output(html):
    """Write output HTML file"""
    output_path = Path(OUTPUT_FILE)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)
    
    file_size = output_path.stat().st_size
    print(f"✅ Wrote output: {OUTPUT_FILE} ({file_size:,} bytes)")


def main():
    """Main build process"""
    print(f"🚀 Building: {BUILD_ID}")
    print(f"📄 Baseline: {BASELINE_FILE}")
    print(f"📄 Output: {OUTPUT_FILE}")
    print()
    
    # Read baseline
    html = read_baseline()
    
    # Apply transformations
    html = update_build_id(html)
    html = add_sms_api_constant(html)
    html = add_build_constant(html)
    html = add_delivery_proof_panel(html)
    html = add_sms_functions(html)
    html = hook_emergency_trigger(html)
    html = show_test_button_after_step1(html)
    
    # Validate
    if not validate_build(html):
        print("\n❌ BUILD FAILED - Validation errors")
        sys.exit(1)
    
    # Write output
    write_output(html)
    
    print(f"\n✅ BUILD COMPLETE: {BUILD_ID}")
    print(f"📦 Output: {OUTPUT_FILE}")
    print(f"\n⚠️  IMPORTANT: Run deployment script to:")
    print(f"   1. Deploy Lambda + API Gateway")
    print(f"   2. Update SMS_API_URL in HTML")
    print(f"   3. Deploy to CloudFront")


if __name__ == '__main__':
    main()
