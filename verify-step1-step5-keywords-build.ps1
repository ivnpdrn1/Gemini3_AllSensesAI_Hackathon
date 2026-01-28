# Verify Step 1 + Step 5 + Keywords Build
# Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Verification" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$BUILD_FILE = "Gemini3_AllSensesAI/gemini3-guardian-step1-step5-keywords-final.html"

# Check file exists
if (-not (Test-Path $BUILD_FILE)) {
    Write-Host "❌ Build file not found: $BUILD_FILE" -ForegroundColor Red
    Write-Host "Run: python Gemini3_AllSensesAI/create-step1-step5-keywords-fix.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Build file found" -ForegroundColor Green
$fileSize = (Get-Item $BUILD_FILE).Length
Write-Host "  Size: $($fileSize / 1KB) KB" -ForegroundColor Gray
Write-Host ""

# Read file content
$content = Get-Content $BUILD_FILE -Raw

# Verification checks
$checks = @(
    @{
        Name = "Build stamp"
        Pattern = "GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128"
        Required = $true
    },
    @{
        Name = "Step 1 button type=button"
        Pattern = '<button type="button" class="button primary-btn" onclick="completeStep1\(\)">'
        Required = $true
    },
    @{
        Name = "SMS preview panel"
        Pattern = '<div id="smsPreviewPanel" class="sms-preview-panel">'
        Required = $true
    },
    @{
        Name = "SMS field: Victim"
        Pattern = '<span class="sms-field-value" id="sms-victim">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Risk"
        Pattern = '<span class="sms-field-value" id="sms-risk">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Recommendation"
        Pattern = '<span class="sms-field-value" id="sms-recommendation">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Message"
        Pattern = '<span class="sms-field-value" id="sms-message">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Location"
        Pattern = '<span class="sms-field-value" id="sms-location">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Map"
        Pattern = '<span class="sms-field-value" id="sms-map">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Time"
        Pattern = '<span class="sms-field-value" id="sms-time">—</span>'
        Required = $true
    },
    @{
        Name = "SMS field: Action"
        Pattern = '<span class="sms-field-value" id="sms-action">—</span>'
        Required = $true
    },
    @{
        Name = "SMS text preview"
        Pattern = '<div id="smsTextContent" class="sms-text-content">'
        Required = $true
    },
    @{
        Name = "Function: composeAlertPayload"
        Pattern = "function composeAlertPayload\(\)"
        Required = $true
    },
    @{
        Name = "Function: composeAlertSms"
        Pattern = "function composeAlertSms\(payload\)"
        Required = $true
    },
    @{
        Name = "Function: renderSmsPreviewFields"
        Pattern = "function renderSmsPreviewFields\(payload\)"
        Required = $true
    },
    @{
        Name = "Function: updateSmsPreview"
        Pattern = "function updateSmsPreview\(\)"
        Required = $true
    },
    @{
        Name = "Function: completeStep1"
        Pattern = "function completeStep1\(\)"
        Required = $true
    },
    @{
        Name = "E.164 validation regex"
        Pattern = "const e164Regex"
        Required = $true
    },
    @{
        Name = "Keywords config panel"
        Pattern = '<div class="keywords-config">'
        Required = $true
    },
    @{
        Name = "Keywords list"
        Pattern = '<div class="keywords-list" id="keywordsList">'
        Required = $true
    },
    @{
        Name = "Keyword input"
        Pattern = '<input type="text" id="keywordInput"'
        Required = $true
    },
    @{
        Name = "Add keyword button"
        Pattern = '<button id="addKeywordBtn" class="keyword-add-btn" onclick="addKeyword\(\)">'
        Required = $true
    },
    @{
        Name = "Class: EmergencyKeywordsConfig"
        Pattern = "class EmergencyKeywordsConfig"
        Required = $true
    },
    @{
        Name = "Class: KeywordDetectionEngine"
        Pattern = "class KeywordDetectionEngine"
        Required = $true
    },
    @{
        Name = "Class: EmergencyStateManager"
        Pattern = "class EmergencyStateManager"
        Required = $true
    },
    @{
        Name = "Build validation script"
        Pattern = "\[BUILD-VALIDATION\] Running build validation checks"
        Required = $true
    },
    @{
        Name = "updateSmsPreview on page load"
        Pattern = "// Initialize SMS preview with placeholders"
        Required = $true
    },
    @{
        Name = "updateSmsPreview after Step 1"
        Pattern = "updatePipelineState('STEP1_COMPLETE')"
        Required = $true
    }
)

$passed = 0
$failed = 0

Write-Host "Running verification checks..." -ForegroundColor Yellow
Write-Host ""

foreach ($check in $checks) {
    $found = $content -match [regex]::Escape($check.Pattern)
    
    if ($found) {
        Write-Host "✓ $($check.Name)" -ForegroundColor Green
        $passed++
    } else {
        if ($check.Required) {
            Write-Host "❌ $($check.Name)" -ForegroundColor Red
            $failed++
        } else {
            Write-Host "⚠ $($check.Name) (optional)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0) {
    Write-Host "✅ Build verification PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy: .\Gemini3_AllSensesAI\deployment\deploy-step1-step5-keywords-fix.ps1" -ForegroundColor White
    Write-Host "  2. Test in browser with verification steps from STEP1_STEP5_KEYWORDS_FIX_COMPLETE.md" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ Build verification FAILED" -ForegroundColor Red
    Write-Host "Rebuild: python Gemini3_AllSensesAI/create-step1-step5-keywords-fix.py" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
