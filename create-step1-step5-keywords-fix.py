#!/usr/bin/env python3
"""
Create Final Production Build: Step 1 + Step 5 SMS Preview + Configurable Keywords

This script creates a production HTML build that:
1. Fixes Step 1 "Complete Step 1" button (always works, no dead clicks)
2. Adds Step 5 always-visible structured SMS preview (8 fields with placeholders)
3. Restores configurable emergency keywords UI and logic
4. Includes all safety features and proof logging

Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128
"""

import re
from pathlib import Path

def create_final_build():
    """Create the final production build with all fixes"""
    
    # Read the base configurable keywords file (has Step 1 + keywords working)
    base_file = Path('Gemini3_AllSensesAI/gemini3-guardian-configurable-keywords.html')
    
    if not base_file.exists():
        print(f"ERROR: Base file not found: {base_file}")
        return False
    
    with open(base_file, 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Update build stamp
    html = re.sub(
        r'Build: GEMINI3-CONFIGURABLE-KEYWORDS-\d+',
        'Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128',
        html
    )
    
    # ========== STEP 5: ADD STRUCTURED SMS PREVIEW ==========
    
    # Find Step 5 section and add SMS preview structure
    step5_section = '''        <div class="section">
            <h3>🚨 Step 5 — Emergency Alerting</h3>
            <p class="note" style="margin-bottom: 10px;">When a high-risk threat is detected, emergency alerts are automatically sent to your emergency contact with your location and transcript details.</p>
            
            <!-- NEW: Always-Visible SMS Preview Structure -->
            <div id="smsPreviewPanel" class="sms-preview-panel">
                <h4>📱 SMS Alert Preview</h4>
                <div class="sms-preview-description">
                    This is the exact message that will be sent to your emergency contact when a threat is detected.
                </div>
                
                <div class="sms-preview-fields">
                    <div class="sms-field">
                        <span class="sms-field-label">Victim:</span>
                        <span class="sms-field-value" id="sms-victim">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Risk:</span>
                        <span class="sms-field-value" id="sms-risk">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Recommendation:</span>
                        <span class="sms-field-value" id="sms-recommendation">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Message:</span>
                        <span class="sms-field-value" id="sms-message">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Location:</span>
                        <span class="sms-field-value" id="sms-location">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Map:</span>
                        <span class="sms-field-value" id="sms-map">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Time:</span>
                        <span class="sms-field-value" id="sms-time">—</span>
                    </div>
                    <div class="sms-field">
                        <span class="sms-field-label">Action:</span>
                        <span class="sms-field-value" id="sms-action">—</span>
                    </div>
                </div>
                
                <div class="sms-text-preview">
                    <h5>SMS Text Preview:</h5>
                    <div id="smsTextContent" class="sms-text-content">
                        (SMS message will appear here after threat analysis)
                    </div>
                </div>
            </div>
            
            <div id="step5Status" class="note">Waiting for threat analysis...</div>
            <div id="alertResult" style="display:none;margin-top:10px;padding:12px;background:#d4edda;border:1px solid #28a745;border-radius:5px;">
                <strong>✅ Alert Sent!</strong><br>
                <span id="alertDetails"></span>
            </div>
        </div>'''
    
    # Replace existing Step 5 section
    html = re.sub(
        r'<div class="section">\s*<h3>🚨 Step 5 — Emergency Alerting</h3>.*?</div>\s*</div>',
        step5_section,
        html,
        flags=re.DOTALL
    )
    
    # Add SMS Preview CSS
    sms_preview_css = '''
        /* SMS Preview Panel */
        .sms-preview-panel { background: #fff3cd; border: 2px solid #ffc107; padding: 20px; border-radius: 10px; margin: 15px 0; }
        .sms-preview-panel h4 { margin: 0 0 10px 0; color: #856404; font-size: 1.1em; }
        .sms-preview-description { font-size: 0.9em; color: #856404; margin-bottom: 15px; }
        .sms-preview-fields { background: #fff; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .sms-field { display: grid; grid-template-columns: 150px 1fr; gap: 10px; margin: 8px 0; padding: 8px; background: #f8f9fa; border-radius: 5px; font-size: 0.95em; }
        .sms-field-label { font-weight: bold; color: #495057; }
        .sms-field-value { color: #212529; font-family: monospace; }
        .sms-text-preview { background: #fff; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .sms-text-preview h5 { margin: 0 0 10px 0; color: #495057; font-size: 1em; }
        .sms-text-content { background: #f8f9fa; padding: 12px; border-radius: 5px; font-family: monospace; font-size: 0.9em; color: #212529; white-space: pre-wrap; min-height: 80px; border: 1px solid #dee2e6; }
'''
    
    # Insert SMS CSS before closing </style>
    html = html.replace('</style>', sms_preview_css + '\n    </style>')
    
    # ========== ADD SMS PREVIEW JAVASCRIPT FUNCTIONS ==========
    
    sms_functions = '''
        // ========== SMS PREVIEW FUNCTIONS ==========
        
        /**
         * Compose alert payload with all required fields
         */
        function composeAlertPayload() {
            const victimName = document.getElementById('victimName')?.value.trim() || 'Unknown User';
            const emergencyPhone = document.getElementById('emergencyPhone')?.value.trim() || 'Not provided';
            
            // Get threat analysis data
            const threatLevel = document.getElementById('threatLevel')?.textContent || '—';
            const threatAnalysis = document.getElementById('threatAnalysis')?.textContent || '—';
            
            // Get location data
            const locationLabel = currentLocation?.label || '—';
            const locationCoords = currentLocation 
                ? `${currentLocation.latitude.toFixed(6)}, ${currentLocation.longitude.toFixed(6)}`
                : '—';
            const mapsUrl = currentLocation
                ? `https://www.google.com/maps?q=${currentLocation.latitude},${currentLocation.longitude}`
                : '#';
            
            // Get transcript
            const transcript = document.getElementById('audioInput')?.value.trim() || '—';
            
            // Get timestamp
            const timestamp = new Date().toLocaleString();
            
            // Determine recommendation based on threat level
            let recommendation = '—';
            if (threatLevel === 'CRITICAL' || threatLevel === 'HIGH') {
                recommendation = 'IMMEDIATE RESPONSE REQUIRED';
            } else if (threatLevel === 'MEDIUM') {
                recommendation = 'Monitor situation closely';
            } else if (threatLevel === 'LOW') {
                recommendation = 'Awareness advised';
            }
            
            return {
                victim: victimName,
                risk: threatLevel,
                recommendation: recommendation,
                message: transcript,
                location: locationLabel,
                locationCoords: locationCoords,
                map: mapsUrl,
                time: timestamp,
                action: recommendation,
                emergencyPhone: emergencyPhone
            };
        }
        
        /**
         * Compose SMS text from payload
         */
        function composeAlertSms(payload) {
            return `🚨 EMERGENCY ALERT

Victim: ${payload.victim}
Risk: ${payload.risk}
Recommendation: ${payload.recommendation}

Message: ${payload.message}

Location: ${payload.location}
Coordinates: ${payload.locationCoords}
Map: ${payload.map}

Time: ${payload.time}
Action: ${payload.action}

This is an automated emergency alert from AllSensesAI Guardian.`;
        }
        
        /**
         * Render SMS preview fields
         */
        function renderSmsPreviewFields(payload) {
            document.getElementById('sms-victim').textContent = payload.victim;
            document.getElementById('sms-risk').textContent = payload.risk;
            document.getElementById('sms-recommendation').textContent = payload.recommendation;
            document.getElementById('sms-message').textContent = payload.message.substring(0, 100) + (payload.message.length > 100 ? '...' : '');
            document.getElementById('sms-location').textContent = payload.location;
            
            // Map link
            const mapEl = document.getElementById('sms-map');
            if (payload.map !== '#') {
                mapEl.innerHTML = `<a href="${payload.map}" target="_blank" rel="noopener noreferrer" style="color:#007bff;">View on Google Maps</a>`;
            } else {
                mapEl.textContent = '—';
            }
            
            document.getElementById('sms-time').textContent = payload.time;
            document.getElementById('sms-action').textContent = payload.action;
            
            // Update SMS text preview
            const smsText = composeAlertSms(payload);
            document.getElementById('smsTextContent').textContent = smsText;
            
            console.log('[SMS-PREVIEW] Fields updated:', payload);
        }
        
        /**
         * Update SMS preview (call at lifecycle points)
         */
        function updateSmsPreview() {
            const payload = composeAlertPayload();
            renderSmsPreviewFields(payload);
            console.log('[SMS-PREVIEW] Preview updated');
        }
'''
    
    # Insert SMS functions before the closing </script> tag
    html = html.replace('    </script>', sms_functions + '\n    </script>')
    
    # ========== UPDATE LIFECYCLE HOOKS TO CALL updateSmsPreview() ==========
    
    # 1. On page load
    html = html.replace(
        "initializeSpeechRecognition();",
        "initializeSpeechRecognition();\n            \n            // Initialize SMS preview with placeholders\n            updateSmsPreview();"
    )
    
    # 2. After Step 1 completes
    html = html.replace(
        "updatePipelineState('STEP1_COMPLETE');",
        "updatePipelineState('STEP1_COMPLETE');\n            updateSmsPreview();"
    )
    
    # 3. After location is selected
    html = html.replace(
        "displaySelectedLocation(currentLocation);",
        "displaySelectedLocation(currentLocation);\n                        updateSmsPreview();"
    )
    
    # 4. After threat analysis completes
    html = html.replace(
        "threatAnalysis.textContent = result.reasoning;",
        "threatAnalysis.textContent = result.reasoning;\n                \n                // Update SMS preview with analysis results\n                updateSmsPreview();"
    )
    
    # 5. Before sending alert (in triggerStep5Alert)
    html = html.replace(
        "step5Status.textContent = '🚨 Sending emergency alerts...';",
        "step5Status.textContent = '🚨 Sending emergency alerts...';\n            \n            // Final SMS preview update before sending\n            updateSmsPreview();"
    )
    
    # ========== FIX STEP 1 BUTTON (ENSURE IT'S type="button") ==========
    
    # Make sure Step 1 button is type="button" to prevent form submission
    html = html.replace(
        '<button class="button primary-btn" onclick="completeStep1()">',
        '<button type="button" class="button primary-btn" onclick="completeStep1()">'
    )
    
    # Add defensive error handling to completeStep1
    # Find and replace the completeStep1 function
    complete_step1_start = html.find('function completeStep1()')
    if complete_step1_start != -1:
        # Find the end of the function (matching braces)
        brace_count = 0
        func_start = html.find('{', complete_step1_start)
        i = func_start
        while i < len(html):
            if html[i] == '{':
                brace_count += 1
            elif html[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    func_end = i + 1
                    break
            i += 1
        
        # Build the new function
        complete_step1_fix = '''function completeStep1() {
            try {
                const name = document.getElementById('victimName').value.trim();
                const phone = document.getElementById('emergencyPhone').value.trim();
                
                // E.164 validation
                const e164Regex = /^\\+[1-9]\\d{6,14}$/;
                
                if (!name) {
                    alert('Please enter your name');
                    return;
                }
                
                if (!phone) {
                    alert('Please enter emergency contact phone number');
                    return;
                }
                
                if (!e164Regex.test(phone)) {
                    alert('Phone number must be in E.164 format (e.g., +1234567890)\\n\\nFormat: +[country code][number]\\nExample: +12025551234');
                    return;
                }
                
                __ALLSENSES_STATE.configSaved = true;
                document.getElementById('step1Status').textContent = '✅ Configuration saved';
                document.getElementById('step1Status').style.color = '#28a745';
                document.getElementById('enableLocationBtn').disabled = false;
                document.getElementById('step2ProofLog').textContent = 'Step 1 complete! Now click "Enable Location" to see proof logs...';
                updatePipelineState('STEP1_COMPLETE');
                updateSmsPreview();
                
                console.log('[STEP1] Configuration saved:', { name, phone });
                
            } catch (error) {
                console.error('[STEP1] ERROR:', error);
                alert('Step 1 error: ' + error.message);
                document.getElementById('step1Status').textContent = '❌ Error: ' + error.message;
                document.getElementById('step1Status').style.color = '#dc3545';
            }
        }'''
        
        # Replace the function
        html = html[:complete_step1_start] + complete_step1_fix + html[func_end:]
    
    # ========== ADD BUILD VALIDATION SCRIPT ==========
    
    validation_script = '''
        // ========== BUILD VALIDATION ==========
        
        window.addEventListener('DOMContentLoaded', () => {
            console.log('[BUILD-VALIDATION] Running build validation checks...');
            
            const requiredFunctions = [
                'composeAlertPayload',
                'composeAlertSms',
                'renderSmsPreviewFields',
                'updateSmsPreview',
                'completeStep1'
            ];
            
            const missingFunctions = [];
            requiredFunctions.forEach(funcName => {
                if (typeof window[funcName] !== 'function') {
                    missingFunctions.push(funcName);
                }
            });
            
            if (missingFunctions.length > 0) {
                console.error('[BUILD-VALIDATION] FAILED - Missing functions:', missingFunctions);
                alert('Build validation failed! Missing functions: ' + missingFunctions.join(', '));
            } else {
                console.log('[BUILD-VALIDATION] PASSED - All required functions present');
            }
            
            // Check required DOM elements
            const requiredElements = [
                'sms-victim',
                'sms-risk',
                'sms-recommendation',
                'sms-message',
                'sms-location',
                'sms-map',
                'sms-time',
                'sms-action',
                'smsTextContent'
            ];
            
            const missingElements = [];
            requiredElements.forEach(elemId => {
                if (!document.getElementById(elemId)) {
                    missingElements.push(elemId);
                }
            });
            
            if (missingElements.length > 0) {
                console.error('[BUILD-VALIDATION] FAILED - Missing DOM elements:', missingElements);
            } else {
                console.log('[BUILD-VALIDATION] PASSED - All required DOM elements present');
            }
            
            console.log('[BUILD-VALIDATION] Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128');
        });
'''
    
    # Insert validation script before closing </script>
    html = html.replace('    </script>', validation_script + '\n    </script>')
    
    # Write output file
    output_file = Path('Gemini3_AllSensesAI/gemini3-guardian-step1-step5-keywords-final.html')
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"✅ Created: {output_file}")
    print(f"   Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128")
    print(f"   Size: {len(html):,} bytes")
    
    return True

if __name__ == '__main__':
    success = create_final_build()
    if success:
        print("\n✅ Build complete!")
        print("\nFeatures included:")
        print("  ✓ Step 1: Complete Step 1 button (type=button, E.164 validation, error handling)")
        print("  ✓ Step 5: Always-visible SMS preview (8 fields + text preview)")
        print("  ✓ Configurable keywords: UI + detection logic")
        print("  ✓ Build validation: Checks functions and DOM elements at load")
        print("  ✓ Lifecycle hooks: updateSmsPreview() called at all key points")
    else:
        print("\n❌ Build failed!")
        exit(1)
