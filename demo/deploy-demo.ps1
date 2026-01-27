# Gemini Emergency Demo Deployment Script
# Deploys the demo to local development server

param(
    [switch]$Production = $false
)

Write-Host "=== Gemini Emergency Demo Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path "../.env")) {
    Write-Host "[ERROR] .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with your Gemini API key:" -ForegroundColor Yellow
    Write-Host "  cd Gemini3_AllSensesAI" -ForegroundColor Yellow
    Write-Host "  cp .env.example .env" -ForegroundColor Yellow
    Write-Host "  # Edit .env and add your GOOGLE_GEMINI_API_KEY" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] .env file found" -ForegroundColor Green

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found. Please install Python 3.8+" -ForegroundColor Red
    exit 1
}

# Check if virtual environment exists
if (-not (Test-Path "../.venv")) {
    Write-Host "[INFO] Creating virtual environment..." -ForegroundColor Yellow
    python -m venv ../.venv
    Write-Host "[OK] Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "[INFO] Activating virtual environment..." -ForegroundColor Yellow
& "../.venv/Scripts/Activate.ps1"

# Install dependencies
Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt --quiet
Write-Host "[OK] Dependencies installed" -ForegroundColor Green

# Start backend
Write-Host ""
Write-Host "=== Starting Backend ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend will run on: http://localhost:5000" -ForegroundColor Green
Write-Host "Frontend demo at: file://$(Get-Location)/gemini-emergency-demo.html" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Set environment
$env:FLASK_DEBUG = if ($Production) { "False" } else { "True" }
$env:PORT = "5000"

# Run backend
python backend.py
