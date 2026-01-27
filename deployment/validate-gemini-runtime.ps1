# Validate Gemini Runtime Deployment
# Automated testing for CloudFront + Lambda deployment

param(
    [string]$DeploymentInfoPath = "deployment/deployment-info.json"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gemini Runtime Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load deployment info
if (-not (Test-Path $DeploymentInfoPath)) {
    Write-Host "ERROR: Deployment info not found at $DeploymentInfoPath" -ForegroundColor Red
    Write-Host "Run deploy-gemini-runtime.ps1 first" -ForegroundColor Yellow
    exit 1
}

$deploymentInfo = Get-Content $DeploymentInfoPath | ConvertFrom-Json
$cloudFrontUrl = $deploymentInfo.cloudFrontUrl
$lambdaFunctionUrl = $deploymentInfo.lambdaFunctionUrl

Write-Host "CloudFront URL: $cloudFrontUrl" -ForegroundColor Cyan
Write-Host "Lambda URL: $lambdaFunctionUrl" -ForegroundColor Cyan
Write-Host ""

# Test 1: Lambda Health Check
Write-Host "[1/4] Testing Lambda health endpoint..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "$lambdaFunctionUrl/health" -Method Get
    
    if ($healthResponse.status -eq "healthy") {
        Write-Host "  OK Lambda is healthy" -ForegroundColor Green
        Write-Host "    Gemini Available: $($healthResponse.gemini_available)" -ForegroundColor Cyan
        Write-Host "    Model: $($healthResponse.model_name)" -ForegroundColor Cyan
        Write-Host "    Mode: $($healthResponse.mode)" -ForegroundColor Cyan
    } else {
        Write-Host "  ERROR: Lambda returned unhealthy status" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: Lambda health check failed" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Lambda Analysis Endpoint
Write-Host ""
Write-Host "[2/4] Testing Lambda analysis endpoint..." -ForegroundColor Yellow

$testPayload = @{
    transcript = "Help me please, I don't feel safe. There's someone following me and I'm scared."
    location = "37.7749, -122.4194 (San Francisco)"
    name = "Test User"
    contact = "+1-555-0100"
} | ConvertTo-Json

try {
    $analysisResponse = Invoke-RestMethod `
        -Uri "$lambdaFunctionUrl/analyze" `
        -Method Post `
        -Body $testPayload `
        -ContentType "application/json"
    
    Write-Host "  OK Analysis completed" -ForegroundColor Green
    Write-Host "    Risk Level: $($analysisResponse.risk_level)" -ForegroundColor Cyan
    Write-Host "    Confidence: $($analysisResponse.confidence)" -ForegroundColor Cyan
    Write-Host "    Mode: $($analysisResponse.mode)" -ForegroundColor Cyan
    Write-Host "    Response Time: $($analysisResponse.response_time)s" -ForegroundColor Cyan
    
    # Validate response structure
    $requiredFields = @('risk_level', 'confidence', 'reasoning', 'indicators', 'recommended_action')
    $missingFields = $requiredFields | Where-Object { -not $analysisResponse.PSObject.Properties.Name.Contains($_) }
    
    if ($missingFields.Count -gt 0) {
        Write-Host "  ERROR: Missing required fields: $($missingFields -join ', ')" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "  ERROR: Lambda analysis failed" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: CloudFront UI Accessibility
Write-Host ""
Write-Host "[3/4] Testing CloudFront UI..." -ForegroundColor Yellow

try {
    $uiResponse = Invoke-WebRequest -Uri $cloudFrontUrl -Method Get
    
    if ($uiResponse.StatusCode -eq 200) {
        Write-Host "  OK CloudFront UI accessible" -ForegroundColor Green
        
        # Check for key content
        $content = $uiResponse.Content
        if ($content -match "AllSensesAI - Gemini Emergency Detection") {
            Write-Host "    Title found" -ForegroundColor Cyan
        } else {
            Write-Host "    WARNING: Expected title not found" -ForegroundColor Yellow
        }
        
        if ($content -match $lambdaFunctionUrl.Replace('/', '\/')) {
            Write-Host "    Lambda URL configured" -ForegroundColor Cyan
        } else {
            Write-Host "    WARNING: Lambda URL not found in UI" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ERROR: CloudFront returned status $($uiResponse.StatusCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: CloudFront UI not accessible" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: HTTPS and CORS
Write-Host ""
Write-Host "[4/4] Validating HTTPS and CORS..." -ForegroundColor Yellow

if ($cloudFrontUrl -match "^https://") {
    Write-Host "  OK CloudFront uses HTTPS (GPS-enabled)" -ForegroundColor Green
} else {
    Write-Host "  ERROR: CloudFront not using HTTPS" -ForegroundColor Red
    exit 1
}

# Check CORS headers on Lambda
try {
    $corsResponse = Invoke-WebRequest -Uri "$lambdaFunctionUrl/health" -Method Options
    $corsHeaders = $corsResponse.Headers
    
    if ($corsHeaders.'Access-Control-Allow-Origin') {
        Write-Host "  OK CORS headers present" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: CORS headers not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: Could not verify CORS (may be OK)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "VALIDATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "Jury Demo URL:" -ForegroundColor Cyan
Write-Host "  $cloudFrontUrl" -ForegroundColor White
Write-Host ""
Write-Host "Demo Scenarios:" -ForegroundColor Yellow
Write-Host "  1. HIGH RISK: 'Help me please, I don't feel safe. Someone is following me.'" -ForegroundColor White
Write-Host "  2. MEDIUM RISK: 'I'm feeling uncomfortable in this situation.'" -ForegroundColor White
Write-Host "  3. LOW RISK: 'Everything is fine, just checking in.'" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open CloudFront URL in browser" -ForegroundColor White
Write-Host "  2. Verify Runtime Health panel shows LIVE status" -ForegroundColor White
Write-Host "  3. Test with sample transcripts" -ForegroundColor White
Write-Host "  4. Review console logs for runtime proof" -ForegroundColor White
Write-Host ""
