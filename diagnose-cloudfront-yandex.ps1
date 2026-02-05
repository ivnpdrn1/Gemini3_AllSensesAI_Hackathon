# Diagnose CloudFront Yandex Issue
# Check what's in S3 vs what CloudFront is serving

Write-Host "=== CloudFront Yandex Diagnosis ===" -ForegroundColor Cyan
Write-Host ""

# Check S3 bucket content
Write-Host "[STEP 1] Checking S3 bucket..." -ForegroundColor Yellow
$bucketName = "allsenses-gemini3-frontend"

try {
    $s3Object = aws s3api head-object --bucket $bucketName --key "index.html" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[INFO] S3 object exists" -ForegroundColor Green
        Write-Host $s3Object
    } else {
        Write-Host "[ERROR] S3 object not found or access denied" -ForegroundColor Red
        Write-Host $s3Object
    }
} catch {
    Write-Host "[ERROR] Failed to check S3: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[STEP 2] Downloading current S3 version..." -ForegroundColor Yellow
try {
    aws s3 cp s3://$bucketName/index.html temp-s3-current.html --quiet
    if ($LASTEXITCODE -eq 0) {
        $yandexCount = (Select-String -Path "temp-s3-current.html" -Pattern "yandex" -AllMatches -CaseSensitive:$false).Count
        Write-Host "[INFO] S3 version has $yandexCount 'yandex' references" -ForegroundColor $(if ($yandexCount -eq 0) { "Green" } else { "Red" })
        
        $buildStamp = Select-String -Path "temp-s3-current.html" -Pattern "Build:" | Select-Object -First 1
        Write-Host "[INFO] S3 buildStamp: $buildStamp" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Failed to download from S3" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] S3 download failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[STEP 3] Checking local file..." -ForegroundColor Yellow
$localFile = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html"
$localYandexCount = (Select-String -Path $localFile -Pattern "yandex" -AllMatches -CaseSensitive:$false).Count
Write-Host "[INFO] Local file has $localYandexCount 'yandex' references" -ForegroundColor $(if ($localYandexCount -eq 0) { "Green" } else { "Red" })

$localBuildStamp = Select-String -Path $localFile -Pattern "Build:" | Select-Object -First 1
Write-Host "[INFO] Local buildStamp: $localBuildStamp" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== DIAGNOSIS SUMMARY ===" -ForegroundColor Cyan
Write-Host "CloudFront: Serving OLD version with Yandex"
Write-Host "S3: $(if ($yandexCount -eq 0) { 'CLEAN (no Yandex)' } else { 'OLD (has Yandex)' })"
Write-Host "Local: $(if ($localYandexCount -eq 0) { 'CLEAN (no Yandex)' } else { 'OLD (has Yandex)' })"
Write-Host ""
Write-Host "NEXT STEPS:"
if ($localYandexCount -eq 0) {
    Write-Host "1. Deploy local file to S3" -ForegroundColor Yellow
    Write-Host "2. Invalidate CloudFront cache" -ForegroundColor Yellow
} else {
    Write-Host "1. Fix local file first (remove Yandex)" -ForegroundColor Red
    Write-Host "2. Then deploy to S3" -ForegroundColor Yellow
    Write-Host "3. Then invalidate CloudFront" -ForegroundColor Yellow
}
