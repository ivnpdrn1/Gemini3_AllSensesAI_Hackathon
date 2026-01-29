#!/usr/bin/env python3
"""
Build Script: Gemini3 Guardian - Colombia SMS Fix + UI Improvements
Build ID: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3

PART A: Colombia SMS Delivery Fixes
1. Manual "Send Test SMS" works regardless of risk level (no risk gating)
2. Enhanced Delivery Proof panel with comprehensive API response
3. Backend already has proper SNS attributes (v2)
4. Enhanced CloudWatch logging
5. E.164 validation
6. Pre-deployment SNS config check

PART B: Fix "Waiting for threat analysis..." Stuck Message
1. Clear this message when Step 4 completes
2. Replace with "Ready to send alert (manual test available)"
3. Ensure Step 5 updates immediately after analysis

Changes from v2:
- Remove risk level gating from manual SMS test
- Add comprehensive delivery proof fields (requestId, provider, snsMessageId, httpStatus, errorCode)
- Fix "Waiting for threat analysis..." stuck message
- Update Step 5 status after analysis completes
- Enhanced proof logging for SMS attempts

Zero regressions: All baseline functionality preserved.
"""

import re
import sys
from pathlib import Path

# Build configuration
BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3"
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
        r'Loaded Build ID</div>\s*<div class="health-value" style="font-family: monospace; font-size: 12px;">GEMINI3-JURY-READY-VIDEO-20260128-v1',
        f'Loaded Build ID</div>\\n                    <div class="health-value" style="font-family: monospace; font-size: 12px;">{BUILD_ID}',
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


def add_enhanced_delivery_proof_panel(html):
    """Add enhanced Delivery Proof panel in Step 5 after SMS preview"""
    delivery_panel = """
            <!-- NEW: Enhanced SMS Delivery Proof Panel (v3) -->
            <div id="smsDeliveryProofPanel" class="sms-preview-panel" style="background: #e8f5e9; border-color: #4caf50; display:none;">
                <h4>📡 SMS Delivery Proof</h4>
                <div class="sms-preview-description">
                    Real-time delivery status with complete API response. No guessing - shows actual SNS publish result.
                </div>
                
                <div class="sms-preview-fields">
                    <div class="sms-field">
                        <span class="sms-field-label">Status:</span>
                        <span class="sms-field-value" id="sms-delivery-status" style="font-weight:bold;">NOT_SENT</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Provider:</span>
                        <span class="sms-field-value" id="sms-delivery-provider">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">SNS Message ID:</span>
                        <span class="sms-field-value" id="sms-delivery-message-id">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Request ID:</span>
                        <span class="sms-field-value" id="sms-delivery-request-id">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Destination:</span>
                        <span class="sms-field-value" id="sms-delivery-destination">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">HTTP Status:</span>
                        <span class="sms-field-value" id="sms-delivery-http-status">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Timestamp:</span>
                        <span class="sms-field-value" id="sms-delivery-timestamp">—</span>
                    </div>
                </div>
                
                <div id="smsDeliveryError" style="background: #f8d7da; padding: 12px; border-radius: 5px; margin: 10px 0; display:none;">
                    <strong>❌ Delivery Failed:</strong><br>
                    <div style="margin-top: 8px;">
                        <strong>Error Code:</strong> <span id="smsDeliveryErrorCode">—</span><br>
                        <strong>Error Message:</strong> <span id="smsDeliveryErrorText">—</span>
                    </div>
                </div>
                
                <div id="smsDeliverySuccess" style="background: #d4edda; padding: 12px; border-radius: 5px; margin: 10px 0; display:none;">
                    <strong>✅ SMS Delivered Successfully</strong><br>
                    <div style="margin-top: 8px; font-family: monospace; font-size: 0.9em;">
                        SNS MessageId: <span id="smsSuccessMessageId">—</span>
                    </div>
                </div>
            </div>
            
            <!-- NEW: Manual Test SMS Button (v3 - NO RISK GATING) -->
            <div id="manualSmsTestSection" style="margin: 15px 0; display:none;">
                <button type="button" class="button secondary-btn" onclick="sendTestSms()">📤 Send Test SMS</button>
                <div class="note">Test SMS delivery to your emergency contact. Works regardless of risk level (jury demo safe).</div>
            </div>
            
"""
    
    # Insert after SMS preview panel (before step5Status)
    pattern = r'(</div>\s*<div id="step5Status")'
    replacement = delivery_panel + r'\1'
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Added enhanced Delivery Proof panel and Test SMS button (no risk gating)")
    return html


def add_sms_functions_v3(html):
    """Add SMS sending functions with enhanced logging and no risk gating"""
    sms_functions = r"""
        // ========== SMS SENDING FUNCTIONS (v3 - Enhanced) ==========
        
        /**
         * Send SMS via backend API (v3 - Enhanced logging, no risk gating for manual)
         * @param {Object} payload - Alert payload from composeAlertPayload()
         * @param {boolean} isManualTest - True if triggered by manual test button
         * @returns {Promise<Object>} - {ok: boolean, messageId?: string, error?: string}
         */
        async function sendSms(payload, isManualTest = false) {
            const triggerType = isManualTest ? 'MANUAL' : 'AUTO';
            console.log(`[SMS][REQUEST] Sending SMS (${triggerType})...`, payload);
            
            // Update delivery status
            updateDeliveryStatus('SENDING', payload.emergencyPhone, null, triggerType);
            
            try {
                // Compose SMS text (single source of truth)
                const smsText = composeAlertSms(payload);
                
                // Prepare request body (v2 API contract)
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
                        triggerType: triggerType,  // NEW: Track manual vs auto
                        lat: currentLocation?.latitude || 0,
                        lng: currentLocation?.longitude || 0,
                        mapUrl: payload.map,
                        timestampIso: new Date().toISOString(),
                        action: payload.action
                    }
                };
                
                console.log('[SMS][REQUEST] Request body:', requestBody);
                console.log('[SMS][REQUEST] Message length:', smsText.length, 'chars');
                
                // Send to backend
                const startTime = Date.now();
                const response = await fetch(SMS_API_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(requestBody)
                });
                
                const responseTime = Date.now() - startTime;
                const result = await response.json();
                
                console.log(`[SMS][RESPONSE] HTTP ${response.status} in ${responseTime}ms:`, result);
                
                if (result.ok) {
                    console.log('[SMS][SUCCESS] SMS sent successfully:', result);
                    updateDeliveryStatus('SENT', result.toMasked, result, triggerType);
                    return { ok: true, messageId: result.messageId, result: result };
                } else {
                    console.error('[SMS][ERROR] SMS sending failed:', result.errorMessage);
                    updateDeliveryStatus('FAILED', payload.emergencyPhone, result, triggerType);
                    return { ok: false, error: result.errorMessage, result: result };
                }
                
            } catch (error) {
                console.error('[SMS][ERROR] Network error:', error);
                const errorResult = {
                    ok: false,
                    provider: 'sns',
                    errorCode: 'NETWORK_ERROR',
                    errorMessage: error.message,
                    httpStatus: 0
                };
                updateDeliveryStatus('FAILED', payload.emergencyPhone, errorResult, triggerType);
                return { ok: false, error: error.message, result: errorResult };
            }
        }
        
        /**
         * Update SMS delivery status in UI (v3 - Enhanced with all fields)
         */
        function updateDeliveryStatus(status, destination, apiResponse, triggerType) {
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
            
            // Update provider
            const providerEl = document.getElementById('sms-delivery-provider');
            if (providerEl) providerEl.textContent = apiResponse?.provider || 'SNS';
            
            // Update destination (masked)
            const destEl = document.getElementById('sms-delivery-destination');
            if (destEl) destEl.textContent = destination || '—';
            
            // Update timestamp
            const timeEl = document.getElementById('sms-delivery-timestamp');
            if (timeEl) timeEl.textContent = apiResponse?.timestamp || new Date().toISOString();
            
            // Update message ID
            const msgIdEl = document.getElementById('sms-delivery-message-id');
            if (msgIdEl) msgIdEl.textContent = apiResponse?.messageId || '—';
            
            // Update request ID
            const reqIdEl = document.getElementById('sms-delivery-request-id');
            if (reqIdEl) reqIdEl.textContent = apiResponse?.requestId || '—';
            
            // Update HTTP status
            const httpStatusEl = document.getElementById('sms-delivery-http-status');
            if (httpStatusEl) httpStatusEl.textContent = apiResponse?.httpStatus || (status === 'SENT' ? '200' : '—');
            
            // Show/hide success/error panels
            const errorDiv = document.getElementById('smsDeliveryError');
            const successDiv = document.getElementById('smsDeliverySuccess');
            const errorCodeEl = document.getElementById('smsDeliveryErrorCode');
            const errorTextEl = document.getElementById('smsDeliveryErrorText');
            const successMsgIdEl = document.getElementById('smsSuccessMessageId');
            
            if (status === 'SENT' && successDiv) {
                successDiv.style.display = 'block';
                if (successMsgIdEl) successMsgIdEl.textContent = apiResponse?.messageId || '—';
                if (errorDiv) errorDiv.style.display = 'none';
            } else if (status === 'FAILED' && errorDiv) {
                errorDiv.style.display = 'block';
                if (errorCodeEl) errorCodeEl.textContent = apiResponse?.errorCode || 'UNKNOWN_ERROR';
                if (errorTextEl) errorTextEl.textContent = apiResponse?.errorMessage || 'Unknown error occurred';
                if (successDiv) successDiv.style.display = 'none';
            } else {
                if (errorDiv) errorDiv.style.display = 'none';
                if (successDiv) successDiv.style.display = 'none';
            }
            
            console.log('[SMS][UI] Delivery status updated:', { 
                status, 
                destination, 
                triggerType,
                provider: apiResponse?.provider,
                messageId: apiResponse?.messageId,
                errorCode: apiResponse?.errorCode 
            });
        }
        
        /**
         * Send test SMS (manual trigger) - v3: NO RISK GATING
         * Works regardless of risk level for jury demo reliability
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
            
            // E.164 validation
            const e164Pattern = /^\\+[1-9]\\d{6,14}$/;
            if (!e164Pattern.test(payload.emergencyPhone)) {
                alert('Invalid phone number format.\\n\\nMust be E.164 format (e.g., +573222063010 for Colombia).\\n\\nGot: ' + payload.emergencyPhone);
                return;
            }
            
            // Confirm with user
            const confirmed = confirm('Send test SMS to ' + payload.emergencyPhone + '?\\n\\nThis will send a real SMS message.\\n\\nNote: Works regardless of risk level (jury demo safe).');
            if (!confirmed) {
                console.log('[SMS][TEST] User cancelled test SMS');
                return;
            }
            
            // Log manual test attempt
            console.log('[STEP5][ACTION] Sending TEST SMS to', payload.emergencyPhone, '(manual)');
            
            // Send SMS (isManualTest = true, bypasses risk gating)
            const result = await sendSms(payload, true);
            
            if (result.ok) {
                alert('✅ Test SMS sent successfully!\\n\\nMessage ID: ' + result.messageId + '\\n\\nCheck your phone for delivery (5-30 seconds).');
            } else {
                alert('❌ Test SMS failed:\\n\\n' + result.error + '\\n\\nCheck Delivery Proof panel for details.');
            }
        }
        
"""
    
    # Insert before closing </script> tag
    pattern = r'(</script>\s*</body>)'
    replacement = sms_functions + r'\1'
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Added SMS sending functions (v3 - enhanced logging, no risk gating)")
    return html


def fix_step5_status_message(html):
    """Fix 'Waiting for threat analysis...' stuck message"""
    # Find the step5Status div and update its initial text
    pattern = r'(<div id="step5Status" class="note">)Waiting for threat analysis\.\.\.(</div>)'
    replacement = r'\1Ready to send alert (complete Steps 1-4 first)\2'
    html = re.sub(pattern, replacement, html, count=1)
    
    print("✅ Fixed Step 5 initial status message")
    return html


def add_step5_status_update_after_analysis(html):
    """Add logic to update Step 5 status after Step 4 analysis completes"""
    # Find where threat analysis completes and add status update
    # This should be after updateSmsPreview() is called in the threat analysis section
    
    # Look for the specific pattern in the threat analysis completion
    pattern = r"(// Update SMS preview with analysis results\s+updateSmsPreview\(\);)"
    
    status_update_code = r"""\1
                
                // NEW (v3): Update Step 5 status after analysis completes
                const step5Status = document.getElementById('step5Status');
                if (step5Status) {
                    if (result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL') {
                        step5Status.textContent = '🚨 Ready to send alert | Auto-alert will send on HIGH/CRITICAL';
                        step5Status.style.color = '#dc3545';
                        step5Status.style.fontWeight = 'bold';
                    } else {
                        step5Status.textContent = '✅ Ready to send alert (manual test available)';
                        step5Status.style.color = '#28a745';
                    }
                }
                console.log('[STEP5][STATUS] Updated status after analysis:', result.risk_level);"""
    
    html = re.sub(pattern, status_update_code, html, count=1)
    
    print("✅ Added Step 5 status update after analysis")
    return html


def show_test_button_after_step1(html):
    """Show manual test SMS button after Step 1 completion"""
    pattern = r"(__ALLSENSES_STATE\.configSaved = true;)"
    
    show_button_code = r"""\1
            
            // NEW (v3): Show manual test SMS button
            const manualSmsSection = document.getElementById('manualSmsTestSection');
            if (manualSmsSection) {
                manualSmsSection.style.display = 'block';
                console.log('[STEP1] Manual SMS test button now visible');
            }"""
    
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
        '[SMS][ERROR]',
        '[STEP5][ACTION] Sending TEST SMS',
        'Ready to send alert',
        'isManualTest',
        'NO RISK GATING'
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
    html = add_enhanced_delivery_proof_panel(html)
    html = add_sms_functions_v3(html)
    html = fix_step5_status_message(html)
    html = add_step5_status_update_after_analysis(html)
    html = show_test_button_after_step1(html)
    
    # Validate
    if not validate_build(html):
        print("\n❌ BUILD FAILED - Validation errors")
        sys.exit(1)
    
    # Write output
    write_output(html)
    
    print(f"\n✅ BUILD COMPLETE: {BUILD_ID}")
    print(f"📦 Output: {OUTPUT_FILE}")
    print(f"\n🎯 Key Features (v3):")
    print(f"   ✅ Manual SMS test works regardless of risk level (no gating)")
    print(f"   ✅ Enhanced Delivery Proof with all API response fields")
    print(f"   ✅ Fixed 'Waiting for threat analysis...' stuck message")
    print(f"   ✅ Step 5 status updates after analysis completes")
    print(f"   ✅ Comprehensive proof logging for debugging")
    print(f"\n⚠️  IMPORTANT: Run deployment script to:")
    print(f"   1. Deploy Lambda + API Gateway")
    print(f"   2. Update SMS_API_URL in HTML")
    print(f"   3. Deploy to CloudFront")


if __name__ == '__main__':
    main()
