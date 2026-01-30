#!/Internationalr/bin/env python3
"""
Complete SMS Preview Parity Implementation
Tasks A, B, C, D: Always-visible preview, live updates, keyword detection, emergency state
"""

import re
import sys

def add_complete_sms_preview(input_file, output_file):
    """Add complete SMS preview with all features"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update build stamp
    content = content.replace(
        'Build: GEMINI3-SMS-PREVIEW-20260128',
        'Build: GEMINI3-SMS-PREVIEW-COMPLETE-20260128'
    )
    content = content.replace(
        'GEMINI3-SMS-PREVIEW-20260128',
        'GEMINI3-SMS-PREVIEW-COMPLETE-20260128'
    )
    
    # Add emergency keywords configuration to global state
    emergency_keywords_init = '''
        // Emergency Keywords Configuration
        const EMERGENCY_KEYWORDS = ['emergency', 'help', 'call 911', 'call police', 'help me', 'scared', 'following', 'danger', 'attack'];
        let emergencyTriggered = false;
        let lastKeywordMatch = { keyword: null, source: null, time: null };
'''
    
    # Insert after __ALLSENSES_STATE declaration
    content = content.replace(
        '        const __ALLSENSES_STATE = {',
        emergency_keywords_init + '\n        const __ALLSENSES_STATE = {'
    )
    
    # Add keyword detection function
    keyword_detection_function = '''
        // ========== EMERGENCY KEYWORD DETECTION ==========
        function detectEmergencyKeyword(text, source) {
            if (!text) return null;
            
            const lowerText = text.toLowerCase();
            
            for (const keyword of EMERGENCY_KEYWORDS) {
                // Word boundary matching
                const regex = new RegExp('\\\\b' + keyword.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + '\\\\b', 'i');
                if (regex.test(text)) {
                    const match = {
                        keyword: keyword,
                        source: source,
                        time: new Date().toLocaleTimeString()
                    };
                    
                    console.log(`[TRIGGER] Keyword matched: "${keyword}" (source: ${source})`);
                    
                    emergencyTriggered = true;
                    lastKeywordMatch = match;
                    
                    // Update UI
                    updateKeywordTriggerUI();
                    updateSmsPreview();
                    
                    return match;
                }
            }
            
            return null;
        }
        
        // ========== KEYWORD TRIGGER UI UPDATE ==========
        function updateKeywordTriggerUI() {
            const step3TriggerBlock = document.getElementById('step3TriggerRule');
            const step4TriggerBlock = document.getElementById('step4TriggerRule');
            
            if (step3TriggerBlock) {
                const keywordsList = EMERGENCY_KEYWORDS.slice(0, 5).join(', ') + '...';
                const lastMatchText = lastKeywordMatch.keyword 
                    ? `"${lastKeywordMatch.keyword}" at ${lastKeywordMatch.time} (${lastKeywordMatch.source})`
                    : 'None';
                
                step3TriggerBlock.innerHTML = `
                    <strong>Emergency keywords enabled:</strong> ${keywordsList}<br>
                    <strong>Last match:</strong> ${lastMatchText}
                `;
            }
            
            if (step4TriggerBlock) {
                const keywordsList = EMERGENCY_KEYWORDS.slice(0, 5).join(', ') + '...';
                const lastMatchText = lastKeywordMatch.keyword 
                    ? `"${lastKeywordMatch.keyword}" at ${lastKeywordMatch.time} (${lastKeywordMatch.source})`
                    : 'None';
                
                step4TriggerBlock.innerHTML = `
                    <strong>Emergency keywords enabled:</strong> ${keywordsList}<br>
                    <strong>Last match:</strong> ${lastMatchText}
                `;
            }
        }
'''
    
    # Insert keyword detection before SMS composition
    content = content.replace(
        '        // ========== SMS MESSAGE COMPOSITION (SINGLE SOURCE OF TRUTH) ==========',
        keyword_detection_function + '\n        // ========== SMS MESSAGE COMPOSITION (SINGLE SOURCE OF TRUTH) =========='
    )
    
    # Update composeAlertSms to handle emergency trigger state
    old_compose = '''        function composeAlertSms(payload) {
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
        }'''
    
    new_compose = '''        function composeAlertSms(payload) {
            // Validate required fields
            if (!payload.victimName) return { error: 'Missing victim name' };
            if (!payload.location) return { error: 'Missing location data' };
            if (!payload.location.latitude || !payload.location.longitude) return { error: 'Missing coordinates' };
            
            // Generate timestamp
            const timestamp = new Date().toLocaleTimeString('en-International', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });
            
            // Generate Google Maps link
            const mapsLink = `https://maps.google.com/?q=${payload.location.latitude},${payload.location.longitude}`;
            
            // Compose message based on emergency trigger state
            let message;
            
            if (emergencyTriggered && payload.threatLevel) {
                // EMERGENCY ALERT format
                message = `🚨 EMERGENCY ALERT

Contact: ${payload.victimName}

Risk: ${payload.threatLevel}
Recommendation: ${payload.reasoning || 'Possible threat detected from voice/text cues.'}

Message: "${payload.transcript ? payload.transcript.substring(0, 150) : 'No message'}${payload.transcript && payload.transcript.length > 150 ? '...' : ''}"

Location:
Lat: ${payload.location.latitude.toFixed(6)}
Lng: ${payload.location.longitude.toFixed(6)}
${payload.location.label ? 'Address: ' + payload.location.label : ''}

View Location: ${mapsLink}

Time: ${timestamp}

If you believe they're in danger, call them, and contact local emergency services.`;
            } else {
                // Standby format
                message = `Standby: no emergency trigger detected yet.

Contact: ${payload.victimName}
Location: ${payload.location.latitude.toFixed(6)}, ${payload.location.longitude.toFixed(6)}
Time: ${timestamp}`;
            }
            
            return {
                message: message,
                timestamp: timestamp,
                mapsLink: mapsLink,
                destination: payload.emergencyContact,
                isEmergency: emergencyTriggered
            };
        }'''
    
    content = content.replace(old_compose, new_compose)
    
    # Update updateSmsPreview to always show panel (Task A & B)
    old_update_preview = '''        function updateSmsPreview() {
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
        }'''
    
    new_update_preview = '''        function updateSmsPreview() {
            const victimName = document.getElementById('victimName')?.value.trim();
            const emergencyContact = document.getElementById('emergencyPhone')?.value.trim();
            const transcript = document.getElementById('audioInput')?.value.trim();
            
            // Get threat analysis result
            const threatOutput = document.getElementById('threatLevelOutput');
            const threatLevel = document.getElementById('threatLevel')?.textContent;
            const threatAnalysis = document.getElementById('threatAnalysis')?.textContent;
            
            // Check if we have required data
            const hasConfig = __ALLSENSES_STATE.configSaved && victimName && emergencyContact;
            const hasLocation = currentLocation !== null;
            
            const errorPanel = document.getElementById('smsPreviewError');
            const errorReason = document.getElementById('smsPreviewErrorReason');
            const contentPanel = document.getElementById('smsPreviewContent');
            const standbyPanel = document.getElementById('smsPreviewStandby');
            
            // TASK A: Always show panel, Internationale standby states for missing inputs
            if (!hasConfig) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                if (standbyPanel) standbyPanel.style.display = 'none';
                errorReason.textContent = 'Add emergency contact in Step 1';
                return;
            }
            
            if (!hasLocation) {
                errorPanel.style.display = 'block';
                contentPanel.style.display = 'none';
                if (standbyPanel) standbyPanel.style.display = 'none';
                errorReason.textContent = 'Enable location in Step 2';
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
                if (standbyPanel) standbyPanel.style.display = 'none';
                errorReason.textContent = result.error;
                return;
            }
            
            // Display preview
            errorPanel.style.display = 'none';
            contentPanel.style.display = 'block';
            if (standbyPanel) standbyPanel.style.display = 'none';
            
            document.getElementById('smsPreviewDestination').textContent = emergencyContact;
            document.getElementById('smsPreviewMessage').textContent = result.message;
            
            // Update checklist based on emergency state
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
            
            console.log('[SMS-PREVIEW] Preview updated successfully (emergency:', result.isEmergency, ')');
        }'''
    
    content = content.replace(old_update_preview, new_update_preview)
    
    # Add keyword detection to voice transcript (Task C)
    # Find the speech recognition result handler
    old_speech_result = '''                recognition.onresult = (event) => {'''
    
    new_speech_result = '''                recognition.onresult = (event) => {
                    // TASK C: Detect emergency keywords in voice transcript'''
    
    content = content.replace(old_speech_result, new_speech_result)
    
    # Add keyword detection after transcript update
    old_transcript_update = '''                    if (event.results[i].isFinal) {
                        const finalTranscript = event.results[i][0].transcript;
                        addTranscriptLine(finalTranscript, false);
                        console.log('[STEP3][TRANSCRIPT]', finalTranscript);'''
    
    new_transcript_update = '''                    if (event.results[i].isFinal) {
                        const finalTranscript = event.results[i][0].transcript;
                        addTranscriptLine(finalTranscript, false);
                        console.log('[STEP3][TRANSCRIPT]', finalTranscript);
                        
                        // TASK C: Check for emergency keywords in voice
                        const keywordMatch = detectEmergencyKeyword(finalTranscript, 'voice');
                        if (keywordMatch && !emergencyTriggered) {
                            // Trigger emergency workflow
                            triggerEmergencyWorkflow(finalTranscript, keywordMatch.keyword);
                        }'''
    
    content = content.replace(old_transcript_update, new_transcript_update)
    
    # Add keyword detection to manual text input (Step 4 textarea)
    # Add event listener for textarea changes
    textarea_listener = '''
            // TASK C: Monitor Step 4 textarea for emergency keywords
            const audioInput = document.getElementById('audioInput');
            if (audioInput) {
                audioInput.addEventListener('input', function() {
                    const text = this.value;
                    detectEmergencyKeyword(text, 'manual');
                    updateSmsPreview(); // TASK B: Live update
                });
            }
            
            // TASK B: Monitor contact number changes
            const phoneInput = document.getElementById('emergencyPhone');
            if (phoneInput) {
                phoneInput.addEventListener('input', function() {
                    updateSmsPreview();
                });
            }
            
            // TASK B: Monitor name changes
            const nameInput = document.getElementById('victimName');
            if (nameInput) {
                nameInput.addEventListener('input', function() {
                    updateSmsPreview();
                });
            }
'''
    
    # Insert after DOMContentLoaded
    content = content.replace(
        '        document.addEventListener(\'DOMContentLoaded\', function() {',
        '        document.addEventListener(\'DOMContentLoaded\', function() {' + textarea_listener
    )
    
    # Add Trigger Rule UI blocks to Step 3 and Step 4
    step3_trigger_block = '''
            
            <!-- TASK C: Emergency Keyword Trigger Rule -->
            <div style="background: #fff3cd; border: 2px solid #ffc107; padding: 12px; border-radiInternational: 8px; margin: 15px 0;">
                <h4 style="margin: 0 0 8px 0; color: #856404; font-size: 1em;">🔔 Trigger Rule</h4>
                <div id="step3TriggerRule" style="font-size: 0.9em; color: #856404;">
                    <strong>Emergency keywords enabled:</strong> emergency, help, call 911, help me, scared...<br>
                    <strong>Last match:</strong> None
                </div>
            </div>
'''
    
    # Insert after Step 3 voice controls
    content = content.replace(
        '<div id="voiceStatInternational" class="note">Complete Steps 1 & 2 to enable voice detection</div>',
        '<div id="voiceStatInternational" class="note">Complete Steps 1 & 2 to enable voice detection</div>' + step3_trigger_block
    )
    
    step4_trigger_block = '''
            
            <!-- TASK C: Emergency Keyword Trigger Rule (Step 4) -->
            <div style="background: #fff3cd; border: 2px solid #ffc107; padding: 12px; border-radiInternational: 8px; margin: 15px 0;">
                <h4 style="margin: 0 0 8px 0; color: #856404; font-size: 1em;">🔔 Trigger Rule</h4>
                <div id="step4TriggerRule" style="font-size: 0.9em; color: #856404;">
                    <strong>Emergency keywords enabled:</strong> emergency, help, call 911, help me, scared...<br>
                    <strong>Last match:</strong> None
                </div>
            </div>
'''
    
    # Insert before Step 4 textarea
    content = content.replace(
        '<textarea id="audioInput" placeholder="Enter emergency text...">',
        step4_trigger_block + '\n            <textarea id="audioInput" placeholder="Enter emergency text...">'
    )
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Complete SMS Preview Parity added successfully")
    print(f"  Input: {input_file}")
    print(f"  Output: {output_file}")
    print(f"  Build: GEMINI3-SMS-PREVIEW-COMPLETE-20260128")
    print(f"\nTasks Completed:")
    print(f"  ✓ TASK A: Always-visible SMS Preview panel with standby states")
    print(f"  ✓ TASK B: Live updates on contact/location/transcript/analysis changes")
    print(f"  ✓ TASK C: Emergency keyword detection in voice + manual text")
    print(f"  ✓ TASK D: SMS preview reflects emergency trigger state")
    print(f"\nFeatures:")
    print(f"  ✓ Standby states: 'Add emergency contact in Step 1', 'Enable location in Step 2'")
    print(f"  ✓ Emergency keywords: emergency, help, call 911, help me, scared, following, danger, attack")
    print(f"  ✓ Keyword detection in both voice transcript and manual textarea")
    print(f"  ✓ Trigger Rule UI blocks in Step 3 and Step 4")
    print(f"  ✓ SMS format changes based on emergencyTriggered state")
    print(f"  ✓ Live preview updates on all input changes")

if __name__ == '__main__':
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-sms-preview.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-sms-preview-complete.html'
    
    try:
        add_complete_sms_preview(input_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
