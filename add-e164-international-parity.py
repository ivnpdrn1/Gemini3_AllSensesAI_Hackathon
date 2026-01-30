#!/Internationalr/bin/env python3
"""
Add E.164 International Calling Parity to GEMINI Guardian
Matches ERNIE's phone number behavior for International
"""

import re
import sys

def add_e164_parity(input_file, output_file):
    """Add E.164 validation and international support to GEMINI Guardian"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Update phone input placeholder
    print("[STEP 1] Updating phone input placeholder...")
    content = re.sub(
        r'<input type="tel" id="emergencyPhone" placeholder="\+1234567890"',
        r'<input type="tel" id="emergencyPhone" placeholder="+1XXXXXXXXXX, +57XXXXXXXXXX, +52XXXXXXXXXX, +58XXXXXXXXXX"',
        content
    )
    
    # 2. Add helper text and validation feedback after phone input
    print("[STEP 2] Adding helper text and validation feedback...")
    phone_input_pattern = r'(<input type="tel" id="emergencyPhone"[^>]+>)'
    helper_text = r'''\1
            <div class="note" style="margin-top: 5px; font-size: 0.9em; color: #666;">
                Internationale E.164 format: +&lt;countrycode&gt;&lt;number&gt; (examples: +1…, +57…, +52…, +58…)
            </div>
            <div id="phoneValidationFeedback" class="note" style="margin-top: 5px; font-weight: bold; display: none;"></div>
            <div class="note" style="margin-top: 8px; font-size: 0.85em; color: #555; padding: 8px; background: #f0f8ff; border-radiInternational: 4px; border-left: 3px solid #4a90e2;">
                <strong>International supported:</strong> International, International, International, International
            </div>'''
    
    content = re.sub(phone_input_pattern, helper_text, content)
    
    # 3. Add E.164 validation function in JavaScript section
    print("[STEP 3] Adding E.164 validation function...")
    
    # Find the location to insert validation function (after DOMContentLoaded)
    validation_function = r'''
        // ========== E.164 PHONE VALIDATION (INTERNATIONAL PARITY) ==========
        function validateE164Phone(phoneNumber) {
            const trimmed = phoneNumber.trim();
            
            // E.164 regex: ^\+[1-9]\d{6,14}$
            // MInternationalt start with +, followed by country code (1-9), then 6-14 more digits
            const e164Regex = /^\+[1-9]\d{6,14}$/;
            
            if (!trimmed) {
                return {
                    valid: false,
                    message: 'Phone number required',
                    color: '#dc3545'
                };
            }
            
            if (!trimmed.startsWith('+')) {
                return {
                    valid: false,
                    message: 'MInternationalt start with + (E.164 format)',
                    color: '#dc3545'
                };
            }
            
            if (!e164Regex.test(trimmed)) {
                return {
                    valid: false,
                    message: 'Invalid E.164 format. Internationale +<countrycode><number> (7-15 digits total)',
                    color: '#dc3545'
                };
            }
            
            // Detect region for Internationaler feedback
            let region = 'International';
            if (trimmed.startsWith('+1')) region = 'International';
            else if (trimmed.startsWith('+57')) region = 'International';
            else if (trimmed.startsWith('+52')) region = 'International';
            else if (trimmed.startsWith('+58')) region = 'International';
            
            return {
                valid: true,
                message: `✓ Valid E.164 (${region})`,
                color: '#28a745',
                region: region
            };
        }
        
        function updatePhoneValidation() {
            const phoneInput = document.getElementById('emergencyPhone');
            const feedback = document.getElementById('phoneValidationFeedback');
            
            if (!phoneInput || !feedback) return;
            
            const result = validateE164Phone(phoneInput.value);
            
            feedback.style.display = 'block';
            feedback.style.color = result.color;
            feedback.textContent = result.message;
            
            // Store validation state for form submission
            phoneInput.setAttribute('data-valid', result.valid ? 'true' : 'false');
            
            return result.valid;
        }
        
        // Attach validation to phone input
        window.addEventListener('DOMContentLoaded', () => {
            const phoneInput = document.getElementById('emergencyPhone');
            if (phoneInput) {
                phoneInput.addEventListener('input', updatePhoneValidation);
                phoneInput.addEventListener('blur', updatePhoneValidation);
            }
        });
'''
    
    # Insert validation function after the script tag opening
    script_pattern = r'(<script>)'
    validation_js = (
        r'\1\n'
        r'        // ========== E.164 PHONE VALIDATION (INTERNATIONAL PARITY) ==========\n'
        r'        function validateE164Phone(phoneNumber) {\n'
        r'            const trimmed = phoneNumber.trim();\n'
        r'            \n'
        r'            // E.164 regex: mInternationalt start with +, followed by country code (1-9), then 6-14 more digits\n'
        r'            const e164Regex = /^\\+[1-9]\\d{6,14}$/;\n'
        r'            \n'
        r'            if (!trimmed) {\n'
        r'                return {\n'
        r'                    valid: false,\n'
        r"                    message: 'Phone number required',\n"
        r"                    color: '#dc3545'\n"
        r'                };\n'
        r'            }\n'
        r'            \n'
        r"            if (!trimmed.startsWith('+')) {\n"
        r'                return {\n'
        r'                    valid: false,\n'
        r"                    message: 'MInternationalt start with + (E.164 format)',\n"
        r"                    color: '#dc3545'\n"
        r'                };\n'
        r'            }\n'
        r'            \n'
        r'            if (!e164Regex.test(trimmed)) {\n'
        r'                return {\n'
        r'                    valid: false,\n'
        r"                    message: 'Invalid E.164 format. Internationale +<countrycode><number> (7-15 digits total)',\n"
        r"                    color: '#dc3545'\n"
        r'                };\n'
        r'            }\n'
        r'            \n'
        r'            // Detect region for Internationaler feedback\n'
        r"            let region = 'International';\n"
        r"            if (trimmed.startsWith('+1')) region = 'International';\n"
        r"            else if (trimmed.startsWith('+57')) region = 'International';\n"
        r"            else if (trimmed.startsWith('+52')) region = 'International';\n"
        r"            else if (trimmed.startsWith('+58')) region = 'International';\n"
        r'            \n'
        r'            return {\n'
        r'                valid: true,\n'
        r'                message: `✓ Valid E.164 (${region})`,\n'
        r"                color: '#28a745',\n"
        r'                region: region\n'
        r'            };\n'
        r'        }\n'
        r'        \n'
        r'        function updatePhoneValidation() {\n'
        r"            const phoneInput = document.getElementById('emergencyPhone');\n"
        r"            const feedback = document.getElementById('phoneValidationFeedback');\n"
        r'            \n'
        r'            if (!phoneInput || !feedback) return;\n'
        r'            \n'
        r'            const result = validateE164Phone(phoneInput.value);\n'
        r'            \n'
        r"            feedback.style.display = 'block';\n"
        r'            feedback.style.color = result.color;\n'
        r'            feedback.textContent = result.message;\n'
        r'            \n'
        r'            // Store validation state for form submission\n'
        r"            phoneInput.setAttribute('data-valid', result.valid ? 'true' : 'false');\n"
        r'            \n'
        r'            return result.valid;\n'
        r'        }\n'
        r'        \n'
        r'        // Attach validation to phone input on page load\n'
        r"        document.addEventListener('DOMContentLoaded', function() {\n"
        r"            const phoneInput = document.getElementById('emergencyPhone');\n"
        r'            if (phoneInput) {\n'
        r"                phoneInput.addEventListener('input', updatePhoneValidation);\n"
        r"                phoneInput.addEventListener('blur', updatePhoneValidation);\n"
        r'            }\n'
        r'        });\n'
        r'        \n'
    )
    content = re.sub(script_pattern, validation_js, content, count=1)
    
    # 4. Add validation check to completeStep1 function
    print("[STEP 4] Adding validation check to completeStep1...")
    complete_step1_pattern = r'(function completeStep1\(\) \{[\s\S]*?const phone = document\.getElementById\(\'emergencyPhone\'\)\.value\.trim\(\);)'
    
    validation_check = r'''\1
            
            // E.164 validation check
            const phoneValidation = validateE164Phone(phone);
            if (!phoneValidation.valid) {
                alert('Invalid phone number: ' + phoneValidation.message);
                updatePhoneValidation();
                return;
            }'''
    
    content = re.sub(complete_step1_pattern, validation_check, content)
    
    # 5. Update build stamp
    print("[STEP 5] Updating build stamp...")
    content = re.sub(
        r'Build: GEMINI3-VISION-ADDITIVE-20260127',
        r'Build: GEMINI3-E164-PARITY-20260128',
        content
    )
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✅ E.164 International Parity Implementation Complete!")
    print(f"   Input:  {input_file}")
    print(f"   Output: {output_file}")
    print(f"\n📋 Changes Applied:")
    print(f"   ✓ Phone placeholder: +1XXXXXXXXXX, +57XXXXXXXXXX, +52XXXXXXXXXX, +58XXXXXXXXXX")
    print(f"   ✓ Helper text: E.164 format with examples")
    print(f"   ✓ Validation feedback: Real-time green/red messages")
    print(f"   ✓ International support note: International, International, International, International")
    print(f"   ✓ E.164 regex validation: ^\+[1-9]\d{{6,14}}$")
    print(f"   ✓ Country detection: International, International, International, International")
    print(f"   ✓ Form submission blocking: Invalid numbers cannot proceed")
    print(f"   ✓ Build stamp: GEMINI3-E164-PARITY-20260128")
    
    return True

if __name__ == '__main__':
    input_file = 'Gemini3_AllSensesAI/gemini3-guardian-vision-additive.html'
    output_file = 'Gemini3_AllSensesAI/gemini3-guardian-e164-parity.html'
    
    try:
        success = add_e164_parity(input_file, output_file)
        if success:
            print(f"\n🚀 Ready for deployment!")
            print(f"   Next: Deploy {output_file} to S3 + invalidate CloudFront")
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
