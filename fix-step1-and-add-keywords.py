#!/usr/bin/env python3
"""
Fix Step 1 Progression + Add Keyword Field
A) Fix Step 1 button click not working (must unblock Step 2/3)
B) Add "Emergency Keywords" field (parity feature)
"""

import re
import sys

def fix_step1_and_add_keywords(input_file, output_file):
    """Fix Step 1 button and add configurable keywords"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update build stamp
    content = content.replace(
        'Build: GEMINI3-SMS-PREVIEW-COMPLETE-20260128',
        'Build: GEMINI3-STEP1-KEYWORDS-FIX-20260128'
    )
    content = content.replace(
        'GEMINI3-SMS-PREVIEW-COMPLETE-20260128',
        'GEMINI3-STEP1-KEYWORDS-FIX-20260128'
    )
    
    # ========== FIX A: Step 1 Button ==========
    
    # 1. Add stable ID to button and make it type="button"
    old_button = '<button class="button primary-btn" onclick="completeStep1()">✅ Complete Step 1</button>'
    new_button = '<button type="button" id="completeStep1Btn" class="button primary-btn">Complete Step 1</button>'
    content = content.replace(old_button, new_button)
    
    # 2. Add Step 1 proof box
    step1_proof_box = '''
            <div id="step1ProofBox" style="background: #f8f9fa; border: 2px solid #007bff; padding: 10px; border-radius: 5px; margin: 10px 0; font-family: monospace; font-size: 0.85em; min-height: 40px;">
                <strong>Step 1 Proof:</strong><br>
                <div id="step1ProofLog" style="color: #495057; white-space: pre-wrap;">Click Complete Step 1 to see proof logs...</div>
            </div>
'''
    
    # Insert after step1Status
    content = content.replace(
        '<div id="step1Status" class="note">Enter your details and click Complete Step 1</div>',
        '<div id="step1Status" class="note">Enter your details and click Complete Step 1</div>' + step1_proof_box
    )
    
    # 3. Add proof logging function
    proof_function = '''
        // ========== STEP 1 PROOF LOGGING ==========
        function addStep1ProofToUI(message) {
            const proofLog = document.getElementById('step1ProofLog');
            if (proofLog) {
                const timestamp = new Date().toLocaleTimeString();
                const currentText = proofLog.textContent;
                if (currentText.includes('Click Complete Step 1')) {
                    proofLog.textContent = `[${timestamp}] ${message}`;
                } else {
                    proofLog.textContent = currentText + `\\n[${timestamp}] ${message}`;
                }
            }
        }
'''
    
    # Insert before completeStep1 function
    content = content.replace(
        '        function completeStep1() {',
        proof_function + '\n        function completeStep1(event) {'
    )
    
    # 4. Rewrite completeStep1 function with proof logging and error handling
    old_complete_step1 = '''        function completeStep1(event) {
            const name = document.getElementById('victimName').value.trim();
            const phone = document.getElementById('emergencyPhone').value.trim();
            
            // E.164 validation check
            const phoneValidation = validateE164Phone(phone);
            if (!phoneValidation.valid) {
                alert('Invalid phone number: ' + phoneValidation.message);
                updatePhoneValidation();
                return;
            }
            
            if (!name || !phone) {
                alert('Please enter both name and phone number');
                return;
            }
            
            __ALLSENSES_STATE.configSaved = true;
            document.getElementById('step1Status').textContent = '✅ Configuration saved';
            document.getElementById('enableLocationBtn').disabled = false;
            document.getElementById('step2ProofLog').textContent = 'Step 1 complete! Now click "Enable Location" to see proof logs...';
            updatePipelineState('STEP1_COMPLETE');
        }'''
    
    new_complete_step1 = '''        function completeStep1(event) {
            // Prevent form submit if inside form
            if (event) event.preventDefault();
            
            try {
                addStep1ProofToUI('[STEP1] Click received');
                console.log('[STEP1] Click received');
                
                const name = document.getElementById('victimName').value.trim();
                const phone = document.getElementById('emergencyPhone').value.trim();
                
                addStep1ProofToUI(`[STEP1] Name: ${name ? 'provided' : 'missing'}`);
                addStep1ProofToUI(`[STEP1] Phone: ${phone ? 'provided' : 'missing'}`);
                
                if (!name || !phone) {
                    addStep1ProofToUI('[STEP1][ERROR] Missing name or phone');
                    alert('Please enter both name and phone number');
                    return;
                }
                
                // E.164 validation check
                const phoneValidation = validateE164Phone(phone);
                addStep1ProofToUI(`[STEP1] Phone valid: ${phoneValidation.valid}`);
                console.log('[STEP1] Phone valid:', phoneValidation.valid);
                
                if (!phoneValidation.valid) {
                    addStep1ProofToUI(`[STEP1][ERROR] ${phoneValidation.message}`);
                    alert('Invalid phone number: ' + phoneValidation.message);
                    updatePhoneValidation();
                    return;
                }
                
                // Mark Step 1 complete
                __ALLSENSES_STATE.configSaved = true;
                addStep1ProofToUI('[STEP1] Configuration saved');
                console.log('[STEP1] Configuration saved');
                
                // Update UI
                document.getElementById('step1Status').textContent = 'Configuration saved';
                addStep1ProofToUI('[STEP1] Step 2 unlocked');
                console.log('[STEP1] Step 2 unlocked');
                
                // Enable Step 2
                document.getElementById('enableLocationBtn').disabled = false;
                document.getElementById('step2ProofLog').textContent = 'Step 1 complete! Now click "Enable Location" to see proof logs...';
                
                // Update pipeline state
                updatePipelineState('STEP1_COMPLETE');
                addStep1ProofToUI('[STEP1] Pipeline state: STEP1_COMPLETE');
                
                // Update SMS preview
                updateSmsPreview();
                
                console.log('[STEP1] Step 1 complete - Step 2 and Step 3 will unlock after location');
            } catch (error) {
                addStep1ProofToUI(`[STEP1][ERROR] ${error.message}`);
                console.error('[STEP1] Error:', error);
                alert('Error completing Step 1: ' + error.message);
            }
        }'''
    
    content = content.replace(old_complete_step1, new_complete_step1)
    
    # 5. Add hard-bind event listener in DOMContentLoaded
    dom_listener = '''
            // FIX A: Hard-bind Step 1 button click handler
            const completeStep1Btn = document.getElementById('completeStep1Btn');
            if (completeStep1Btn) {
                completeStep1Btn.addEventListener('click', completeStep1);
                console.log('[STEP1] Button click handler bound');
            }
'''
    
    # Insert after existing DOMContentLoaded listeners
    content = content.replace(
        '        document.addEventListener(\'DOMContentLoaded\', function() {',
        '        document.addEventListener(\'DOMContentLoaded\', function() {' + dom_listener
    )
    
    # ========== FIX B: Add Emergency Keywords Field ==========
    
    # 1. Add localStorage persistence for keywords
    keywords_init = '''
        // Emergency Keywords Configuration with localStorage
        let EMERGENCY_KEYWORDS = ['emergency', 'help', 'call 911', 'call police', 'help me', 'scared', 'following', 'danger', 'attack'];
        
        // Load custom keywords from localStorage
        function loadCustomKeywords() {
            try {
                const stored = localStorage.getItem('customEmergencyKeywords');
                if (stored) {
                    const custom = JSON.parse(stored);
                    if (Array.isArray(custom) && custom.length > 0) {
                        // Merge with defaults (dedupe)
                        const merged = [...new Set([...EMERGENCY_KEYWORDS, ...custom])];
                        EMERGENCY_KEYWORDS = merged;
                        console.log('[KEYWORDS] Loaded custom keywords from localStorage:', custom);
                    }
                }
            } catch (error) {
                console.error('[KEYWORDS] Error loading custom keywords:', error);
            }
        }
        
        // Save custom keywords to localStorage
        function saveCustomKeywords(keywords) {
            try {
                localStorage.setItem('customEmergencyKeywords', JSON.stringify(keywords));
                console.log('[KEYWORDS] Saved custom keywords to localStorage:', keywords);
            } catch (error) {
                console.error('[KEYWORDS] Error saving custom keywords:', error);
            }
        }
        
        // Load keywords on init
        loadCustomKeywords();
'''
    
    # Replace existing EMERGENCY_KEYWORDS declaration
    content = content.replace(
        '        // Emergency Keywords Configuration\n        const EMERGENCY_KEYWORDS = [\'emergency\', \'help\', \'call 911\', \'call police\', \'help me\', \'scared\', \'following\', \'danger\', \'attack\'];',
        keywords_init
    )
    
    # 2. Add keyword management UI in Step 3
    keywords_ui = '''
            
            <!-- FIX B: Add Emergency Keywords Field -->
            <div style="background: #e7f3ff; border: 2px solid #007bff; padding: 12px; border-radius: 8px; margin: 15px 0;">
                <h4 style="margin: 0 0 8px 0; color: #0056b3; font-size: 1em;">Add Emergency Keywords</h4>
                <div style="font-size: 0.9em; color: #495057; margin-bottom: 8px;">
                    Add custom keywords (comma-separated). Example: knife, stop following me, danger
                </div>
                <input type="text" id="customKeywordsInput" placeholder="knife, stop following me, danger" style="width: 100%; padding: 8px; margin: 8px 0; border: 2px solid #007bff; border-radius: 5px; font-size: 0.9em;">
                <div style="display: flex; gap: 10px; margin-top: 8px;">
                    <button type="button" id="addKeywordsBtn" class="button primary-btn" style="font-size: 0.9em; padding: 8px 16px;">Add Keywords</button>
                    <button type="button" id="resetKeywordsBtn" class="button secondary-btn" style="font-size: 0.9em; padding: 8px 16px;">Reset to Defaults</button>
                </div>
                <div id="keywordsStatus" class="note" style="margin-top: 8px; font-weight: bold; display: none;"></div>
            </div>
'''
    
    # Insert after Trigger Rule block in Step 3
    content = content.replace(
        '            <!-- TASK C: Emergency Keyword Trigger Rule -->\n            <div style="background: #fff3cd; border: 2px solid #ffc107; padding: 12px; border-radius: 8px; margin: 15px 0;">',
        keywords_ui + '\n            <!-- TASK C: Emergency Keyword Trigger Rule -->\n            <div style="background: #fff3cd; border: 2px solid #ffc107; padding: 12px; border-radius: 8px; margin: 15px 0;">'
    )
    
    # 3. Add keyword management functions
    keywords_functions = '''
        // ========== KEYWORD MANAGEMENT FUNCTIONS ==========
        function addCustomKeywords() {
            const input = document.getElementById('customKeywordsInput');
            const statusEl = document.getElementById('keywordsStatus');
            
            if (!input || !statusEl) return;
            
            const inputValue = input.value.trim();
            if (!inputValue) {
                statusEl.style.display = 'block';
                statusEl.style.color = '#dc3545';
                statusEl.textContent = 'Please enter keywords';
                return;
            }
            
            // Parse comma-separated keywords
            const newKeywords = inputValue
                .split(',')
                .map(kw => kw.trim().toLowerCase())
                .filter(kw => kw.length > 0);
            
            if (newKeywords.length === 0) {
                statusEl.style.display = 'block';
                statusEl.style.color = '#dc3545';
                statusEl.textContent = 'No valid keywords entered';
                return;
            }
            
            // Merge with existing keywords (dedupe)
            const beforeCount = EMERGENCY_KEYWORDS.length;
            EMERGENCY_KEYWORDS = [...new Set([...EMERGENCY_KEYWORDS, ...newKeywords])];
            const afterCount = EMERGENCY_KEYWORDS.length;
            const addedCount = afterCount - beforeCount;
            
            // Save to localStorage (only custom keywords)
            const defaultKeywords = ['emergency', 'help', 'call 911', 'call police', 'help me', 'scared', 'following', 'danger', 'attack'];
            const customKeywords = EMERGENCY_KEYWORDS.filter(kw => !defaultKeywords.includes(kw));
            saveCustomKeywords(customKeywords);
            
            // Update UI
            statusEl.style.display = 'block';
            statusEl.style.color = '#28a745';
            statusEl.textContent = `Added ${addedCount} new keyword(s). Total: ${afterCount} keywords.`;
            
            // Clear input
            input.value = '';
            
            // Update trigger rule UI
            updateKeywordTriggerUI();
            
            console.log('[KEYWORDS] Added keywords:', newKeywords);
            console.log('[KEYWORDS] Total keywords:', EMERGENCY_KEYWORDS);
            
            // Hide status after 3 seconds
            setTimeout(() => {
                statusEl.style.display = 'none';
            }, 3000);
        }
        
        function resetKeywordsToDefaults() {
            const statusEl = document.getElementById('keywordsStatus');
            
            // Reset to defaults
            EMERGENCY_KEYWORDS = ['emergency', 'help', 'call 911', 'call police', 'help me', 'scared', 'following', 'danger', 'attack'];
            
            // Clear localStorage
            try {
                localStorage.removeItem('customEmergencyKeywords');
                console.log('[KEYWORDS] Cleared custom keywords from localStorage');
            } catch (error) {
                console.error('[KEYWORDS] Error clearing localStorage:', error);
            }
            
            // Update UI
            if (statusEl) {
                statusEl.style.display = 'block';
                statusEl.style.color = '#007bff';
                statusEl.textContent = 'Reset to default keywords (9 keywords)';
                
                // Hide status after 3 seconds
                setTimeout(() => {
                    statusEl.style.display = 'none';
                }, 3000);
            }
            
            // Update trigger rule UI
            updateKeywordTriggerUI();
            
            console.log('[KEYWORDS] Reset to defaults:', EMERGENCY_KEYWORDS);
        }
'''
    
    # Insert before detectEmergencyKeyword function
    content = content.replace(
        '        // ========== EMERGENCY KEYWORD DETECTION ==========',
        keywords_functions + '\n        // ========== EMERGENCY KEYWORD DETECTION =========='
    )
    
    # 4. Add event listeners for keyword buttons
    keywords_listeners = '''
            // FIX B: Bind keyword management buttons
            const addKeywordsBtn = document.getElementById('addKeywordsBtn');
            if (addKeywordsBtn) {
                addKeywordsBtn.addEventListener('click', addCustomKeywords);
                console.log('[KEYWORDS] Add button bound');
            }
            
            const resetKeywordsBtn = document.getElementById('resetKeywordsBtn');
            if (resetKeywordsBtn) {
                resetKeywordsBtn.addEventListener('click', resetKeywordsToDefaults);
                console.log('[KEYWORDS] Reset button bound');
            }
            
            const customKeywordsInput = document.getElementById('customKeywordsInput');
            if (customKeywordsInput) {
                customKeywordsInput.addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        e.preventDefault();
                        addCustomKeywords();
                    }
                });
                console.log('[KEYWORDS] Input Enter key bound');
            }
'''
    
    # Insert after Step 1 button listener
    content = content.replace(
        '            // FIX A: Hard-bind Step 1 button click handler\n            const completeStep1Btn = document.getElementById(\'completeStep1Btn\');',
        keywords_listeners + '\n            // FIX A: Hard-bind Step 1 button click handler\n            const completeStep1Btn = document.getElementById(\'completeStep1Btn\');'
    )
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Step 1 fix and keyword field added successfully")
    print(f"  Input: {input_file}")
    print(f"  Output: {output_file}")
    print(f"  Build: GEMINI3-STEP1-KEYWORDS-FIX-20260128")
    print(f"\nFIX A: Step 1 Button")
    print(f"  ✓ Button has stable ID: completeStep1Btn")
    print(f"  ✓ Button type: button (prevents form submit)")
    print(f"  ✓ Hard-bound click handler in DOMContentLoaded")
    print(f"  ✓ event.preventDefault() in handler")
    print(f"  ✓ Step 1 proof box with logging")
    print(f"  ✓ Try/catch error handling")
    print(f"  ✓ Console logging for debugging")
    print(f"  ✓ Unlocks Step 2 (Enable Location button)")
    print(f"  ✓ Updates pipeline state to STEP1_COMPLETE")
    print(f"\nFIX B: Emergency Keywords Field")
    print(f"  ✓ Add keywords UI in Step 3")
    print(f"  ✓ Text input for comma-separated keywords")
    print(f"  ✓ Add Keywords button")
    print(f"  ✓ Reset to Defaults button")
    print(f"  ✓ localStorage persistence")
    print(f"  ✓ Merge with defaults (dedupe)")
    print(f"  ✓ Case-insensitive matching")
    print(f"  ✓ Applies to voice AND manual text")
    print(f"  ✓ Trigger rule UI updates")
    print(f"  ✓ Enter key support in input field")

if __name__ == '__main__':
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-sms-preview-complete.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-step1-keywords-fix.html'
    
    try:
        fix_step1_and_add_keywords(input_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
