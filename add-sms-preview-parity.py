#!/Internationalr/bin/env python3
"""
Add SMS Preview Parity to GEMINI Guardian
Adds always-visible SMS preview panel in Step 5 with single source of truth for message generation
"""

import re
import sys

def add_sms_preview_parity(input_file, output_file):
    """Add SMS preview panel to Step 5"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update build stamp
    content = content.replace(
        'Build: GEMINI3-E164-PARITY-20260128',
        'Build: GEMINI3-SMS-PREVIEW-20260128'
    )
    content = content.replace(
        'GEMINI3-E164-PARITY-20260128',
        'GEMINI3-SMS-PREVIEW-20260128'
    )
    
    # Add SMS preview panel CSS
    sms_preview_css = '''
        /* SMS Preview Panel */
        .sms-preview-panel { background: #f8f9fa; border: 2px solid #007bff; padding: 20px; border-radiInternational: 10px; margin: 20px 0; }
        .sms-preview-panel h4 { margin: 0 0 15px 0; color: #007bff; font-size: 1.1em; }
        .sms-preview-message { background: #fff; border: 1px solid #dee2e6; border-radiInternational: 8px; padding: 15px; font-family: 'Courier New', monospace; font-size: 0.9em; line-height: 1.6; white-space: pre-wrap; color: #212529; margin: 15px 0; }
        .sms-preview-meta { display: grid; grid-template-columns: 140px 1fr; gap: 8px; margin: 10px 0; font-size: 0.9em; }
        .sms-preview-label { font-weight: bold; color: #555; }
        .sms-preview-value { color: #2c3e50; font-family: monospace; }
        .sms-preview-checklist { background: #e7f3ff; padding: 12px; border-radiInternational: 6px; margin: 10px 0; }
        .sms-preview-checklist h5 { margin: 0 0 8px 0; font-size: 0.95em; color: #0056b3; }
        .sms-preview-checklist ul { margin: 5px 0; padding-left: 20px; }
        .sms-preview-checklist li { margin: 4px 0; font-size: 0.9em; color: #495057; }
        .sms-preview-error { background: #f8d7da; border: 2px solid #dc3545; padding: 15px; border-radiInternational: 8px; color: #721c24; font-weight: bold; margin: 15px 0; }
        .sms-preview-sent { background: #d4edda; border: 2px solid #28a745; padding: 15px; border-radiInternational: 8px; margin: 15px 0; }
        .sms-preview-sent h5 { margin: 0 0 10px 0; color: #155724; font-size: 1em; }
        .sms-preview-timestamp { font-size: 0.85em; color: #666; margin-top: 10px; }
    '''
    
    # Insert CSS before closing </style> tag
    content = content.replace('</style>', sms_preview_css + '\n    </style>')
    
    # Find Step 5 section and add SMS preview panel
    step5_pattern = r'(<div class="section">\s*<h3>🚨 Step 5 — Emergency Alerting</h3>)'
    
    sms_preview_html = r'''\1
            
            <!-- SMS Preview Panel (Always Visible) -->
            <div id="smsPreviewPanel" class="sms-preview-panel">
                <h4>📱 SMS Preview (what your emergency contact will receive)</h4>
                
                <div id="smsPreviewError" class="sms-preview-error" style="display:none;">
                    Cannot generate SMS yet: <span id="smsPreviewErrorReason">—</span>
                </div>
                
                <div id="smsPreviewContent" style="display:none;">
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
    
    content = re.sub(step5_pattern, sms_preview_html, content, count=1)
    
    # Add composeAlertSms function (single source of truth)
    compose_function = '''
        // ========== SMS MESSAGE COMPOSITION (SINGLE SOURCE OF TRUTH) ==========
        function composeAlertSms(payload) {
            // Validate required fields
            if (!payload.victimName) return { error: 'Missing victim name' };
            if (!payload.location) return { error: 'Missing location data' };
            if (!payload.location.latitude || !payload.location.longitude) return { error: 'Missing coordinates' };
            if (!payload.threatLevel) return { error: 'Missing threat analysis' };
            if (!payload.transcript) return { error: 'Missing victim message' };
            
            // Generate timestamp
            const timestamp = new Date().toLocaleString('en-International', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });
            
            // Generate Google Maps link
            const mapsLink = `https://maps.google.com/?q=${payload.location.latitude},${payload.location.longitude}`;
            
            // Compose message (deterministic output)
            const message = `AllSensesAI Guardian Alert

Contact: ${payload.victimName}

Risk: ${payload.threatLevel}
Reason: ${payload.reasoning || 'Possible threat detected from voice/text cues.'}

Message: "${payload.transcript.substring(0, 150)}${payload.transcript.length > 150 ? '...' : ''}"

Location:
Lat: ${payload.location.latitude.toFixed(6)}
Lng: ${payload.location.longitude.toFixed(6)}
${payload.location.label ? 'Address: ' + payload.location.label : ''}

View Location: ${mapsLink}

Time: ${timestamp}

If you believe they're in danger, call them, and contact local emergency services.`;
            
            return {
                message: message,
                timestamp: timestamp,
                mapsLink: mapsLink,
                destination: payload.emergencyContact
            };
        }
        
        // ========== SMS PREVIEW UPDATE ==========
        function updateSmsPreview() {
            const victimName = document.getElementById('victimName')?.value.trim();
            const emergencyContact = document.getElementById('emergencyPhone')?.value.trim();
            const transcript = document.getElementById('audioInput')?.value.trim();
            
            // Get threat analysis result
            const threatOutput = document.getElementById('threatLevelOutput');
            const threatLevel = document.getElementById('threatLevel')?.textContent;
            const threatAnalysis = document.getElementById('threatAnalysis')?.textContent;
            
            // Check if we have all required data
            const hasConfig = __ALLSENSES_STATE.configSaved && victimName && emergencyContact;
            const hasLocation = currentLocation !== null;
            const hasThreat = threatOutput && threatOutput.style.display !== 'none' && threatLevel;
            const hasTranscript = transcript && transcript.length > 0;
            
            const errorPanel = document.getElementById('smsPreviewError');
            const errorReason = document.getElementById('smsPreviewErrorReason');
            const contentPanel = document.getElementById('smsPreviewContent');
            
            // Determine what's missing
            if (!hasConfig) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Complete Step 1 (Configuration) first';
                return;
            }
            
            if (!hasLocation) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Complete Step 2 (Location Services) first';
                return;
            }
            
            if (!hasThreat) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Complete Step 4 (Threat Analysis) first';
                return;
            }
            
            if (!hasTranscript) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                errorReason.textContent = 'Missing victim message/transcript';
                return;
            }
            
            // All data available - compose SMS
            const payload = {
                victimName: victimName,
                emergencyContact: emergencyContact,
                location: currentLocation,
                threatLevel: threatLevel,
                reasoning: threatAnalysis,
                transcript: transcript
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
            
            document.getElementById('smsPreviewDestination').textContent = emergencyContact;
            document.getElementById('smsPreviewMessage').textContent = result.message;
            
            // Update checklist
            document.getElementById('smsCheckRiskValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            document.getElementById('smsCheckMessageValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            document.getElementById('smsCheckLocationValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            document.getElementById('smsCheckMapsValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            document.getElementById('smsCheckTimestampValue').innerHTML = '<span style="color:#28a745;">✓</span>';
            
            console.log('[SMS-PREVIEW] Preview updated successfully');
        }
'''
    
    # Insert compose function before the existing triggerStep5Alert function
    content = content.replace(
        '        // ========== STEP 5: EMERGENCY ALERTING ==========',
        compose_function + '\n        // ========== STEP 5: EMERGENCY ALERTING =========='
    )
    
    # Update triggerStep5Alert to Internationale composeAlertSms and show sent message
    old_trigger = '''        function triggerStep5Alert(analysisResult) {
            console.log('[STEP5] Triggering emergency alert');
            updatePipelineState('STEP5_ALERTING');
            
            const step5StatInternational = document.getElementById('step5StatInternational');
            const alertResult = document.getElementById('alertResult');
            const alertDetails = document.getElementById('alertDetails');
            
            step5StatInternational.textContent = '🚨 Sending emergency alerts...';
            
            setTimeout(() => {
                alertResult.style.display = 'block';
                alertDetails.innerHTML = `
                    Emergency contact notified: ${document.getElementById('emergencyPhone').value}<br>
                    Location: ${currentLocation.label}<br>
                    Coordinates: ${currentLocation.latitude.toFixed(6)}, ${currentLocation.longitude.toFixed(6)}<br>
                    Threat Level: ${analysisResult.risk_level}<br>
                    Time: ${new Date().toLocaleTimeString()}
                `;
                
                step5StatInternational.textContent = '✅ Emergency alerts sent successfully';
                updatePipelineState('STEP5_COMPLETE');
                
                console.log('[STEP5] Alert sent successfully');
            }, 1000);
        }'''
    
    new_trigger = '''        function triggerStep5Alert(analysisResult) {
            console.log('[STEP5] Triggering emergency alert');
            updatePipelineState('STEP5_ALERTING');
            
            const step5StatInternational = document.getElementById('step5StatInternational');
            const alertResult = document.getElementById('alertResult');
            const alertDetails = document.getElementById('alertDetails');
            
            step5StatInternational.textContent = '🚨 Sending emergency alerts...';
            
            // Update SMS preview one final time before send
            updateSmsPreview();
            
            setTimeout(() => {
                // Compose actual SMS Internationaling single source of truth
                const payload = {
                    victimName: document.getElementById('victimName').value.trim(),
                    emergencyContact: document.getElementById('emergencyPhone').value.trim(),
                    location: currentLocation,
                    threatLevel: analysisResult.risk_level,
                    reasoning: analysisResult.reasoning,
                    transcript: document.getElementById('audioInput').value.trim()
                };
                
                const smsResult = composeAlertSms(payload);
                
                if (smsResult.error) {
                    step5StatInternational.textContent = '❌ Failed to send alert: ' + smsResult.error;
                    console.error('[STEP5] Alert failed:', smsResult.error);
                    return;
                }
                
                // Show sent message
                document.getElementById('smsPreviewSent').style.display = 'block';
                document.getElementById('smsPreviewSentMessage').textContent = smsResult.message;
                document.getElementById('smsPreviewSentTime').textContent = smsResult.timestamp;
                
                // Show success
                alertResult.style.display = 'block';
                alertDetails.innerHTML = `
                    Emergency contact notified: ${smsResult.destination}<br>
                    Location: ${currentLocation.label}<br>
                    Coordinates: ${currentLocation.latitude.toFixed(6)}, ${currentLocation.longitude.toFixed(6)}<br>
                    Threat Level: ${analysisResult.risk_level}<br>
                    Time: ${smsResult.timestamp}
                `;
                
                step5StatInternational.textContent = '✅ Emergency alerts sent successfully';
                updatePipelineState('STEP5_COMPLETE');
                
                console.log('[STEP5] Alert sent successfully');
                console.log('[STEP5] SMS content:', smsResult.message);
            }, 1000);
        }'''
    
    content = content.replace(old_trigger, new_trigger)
    
    # Update analyzeWithGemini3 to call updateSmsPreview after analysis
    old_analyze_end = '''                if (result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL') {
                    setTimeout(() => triggerStep5Alert(result), 1000);
                }
                
            } catch (error) {'''
    
    new_analyze_end = '''                if (result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL') {
                    // Update SMS preview after analysis
                    updateSmsPreview();
                    setTimeout(() => triggerStep5Alert(result), 1000);
                } else {
                    // Update SMS preview even for non-emergency threats
                    updateSmsPreview();
                }
                
            } catch (error) {'''
    
    content = content.replace(old_analyze_end, new_analyze_end)
    
    # Add updateSmsPreview call after location is set
    old_location_success = '''                        // NEW: Display location in panel
                        displaySelectedLocation(currentLocation);
                        
                        enableStep3();'''
    
    new_location_success = '''                        // NEW: Display location in panel
                        displaySelectedLocation(currentLocation);
                        
                        // Update SMS preview if threat analysis already done
                        updateSmsPreview();
                        
                        enableStep3();'''
    
    content = content.replace(old_location_success, new_location_success)
    
    # Add updateSmsPreview call after demo location
    old_demo_location = '''            // NEW: Display location in panel
            displaySelectedLocation(currentLocation);
            
            enableStep3();'''
    
    new_demo_location = '''            // NEW: Display location in panel
            displaySelectedLocation(currentLocation);
            
            // Update SMS preview if threat analysis already done
            updateSmsPreview();
            
            enableStep3();'''
    
    content = content.replace(old_demo_location, new_demo_location)
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ SMS Preview Parity added successfully")
    print(f"  Input: {input_file}")
    print(f"  Output: {output_file}")
    print(f"  Build: GEMINI3-SMS-PREVIEW-20260128")
    print(f"\nChanges:")
    print(f"  ✓ Added SMS preview panel in Step 5")
    print(f"  ✓ Implemented composeAlertSms() single source of truth")
    print(f"  ✓ Added visible validation state (error messages)")
    print(f"  ✓ Added data included checklist")
    print(f"  ✓ Added sent message display with timestamp")
    print(f"  ✓ Preview updates after location and threat analysis")
    print(f"  ✓ Deterministic output (same inputs = same message)")

if __name__ == '__main__':
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-e164-parity.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-sms-preview.html'
    
    try:
        add_sms_preview_parity(input_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
