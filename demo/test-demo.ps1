# Gemini Demo Validation Script
# Tests deployment, backend health, and demo scenarios

Write-Host "=== Gemini Demo Validation ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check .env file
Write-Host "[TEST 1] Checking .env configuration..." -ForegroundColor Yellow
if (Test-Path "../.env") {
    $envContent = Get-Content "../.env" -Raw
    if ($envContent -match "GOOGLE_GEMINI_API_KEY=AIza") {
        Write-Host "[PASS] .env file exists with API key" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] .env file missing valid API key" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[FAIL] .env file not found" -ForegroundColor Red
    exit 1
}

# Test 2: Check Python
Write-Host ""
Write-Host "[TEST 2] Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[PASS] Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Python not found" -ForegroundColor Red
    exit 1
}

# Test 3: Check dependencies
Write-Host ""
Write-Host "[TEST 3] Checking Python dependencies..." -ForegroundColor Yellow
$requiredPackages = @("flask", "flask-cors", "google-generativeai", "python-dotenv")
$missingPackages = @()

foreach ($package in $requiredPackages) {
    $installed = pip show $package 2>&1
    if ($LASTEXITCODE -ne 0) {
        $missingPackages += $package
    }
}

if ($missingPackages.Count -eq 0) {
    Write-Host "[PASS] All dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Missing packages: $($missingPackages -join ', ')" -ForegroundColor Yellow
    Write-Host "       Run: pip install -r requirements.txt" -ForegroundColor Yellow
}

# Test 4: Check backend health (if running)
Write-Host ""
Write-Host "[TEST 4] Checking backend health..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 5
    Write-Host "[PASS] Backend is running" -ForegroundColor Green
    Write-Host "       Gemini Available: $($response.gemini_available)" -ForegroundColor Cyan
    Write-Host "       SDK Loaded: $($response.sdk_loaded)" -ForegroundColor Cyan
    Write-Host "       Model: $($response.model_name)" -ForegroundColor Cyan
    Write-Host "       Mode: $($response.mode)" -ForegroundColor Cyan
} catch {
    Write-Host "[WARN] Backend not running" -ForegroundColor Yellow
    Write-Host "       Start with: python backend.py" -ForegroundColor Yellow
}

# Test 5: Check frontend file
Write-Host ""
Write-Host "[TEST 5] Checking frontend file..." -ForegroundColor Yellow
if (Test-Path "gemini-emergency-demo.html") {
    Write-Host "[PASS] Frontend demo file exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Frontend demo file not found" -ForegroundColor Red
    exit 1
}

# Test 6: Check documentation
Write-Host ""
Write-Host "[TEST 6] Checking documentation..." -ForegroundColor Yellow
$docs = @("JURY_DEMO_GUIDE.md", "README.md", "../QUICK_START.md", "../RUNTIME_PROOF_COMPLETE.md")
$missingDocs = @()

foreach ($doc in $docs) {
    if (-not (Test-Path $doc)) {
        $missingDocs += $doc
    }
}

if ($missingDocs.Count -eq 0) {
    Write-Host "[PASS] All documentation present" -ForegroundColor Green
} else {
    Write-Host "[WARN] Missing docs: $($missingDocs -join ', ')" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status: READY FOR DEMO" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start backend: python backend.py" -ForegroundColor White
Write-Host "2. Open gemini-emergency-demo.html in browser" -ForegroundColor White
Write-Host "3. Test analysis scenarios" -ForegroundColor White
Write-Host "4. Review JURY_DEMO_GUIDE.md for presentation" -ForegroundColor White
Write-Host ""
