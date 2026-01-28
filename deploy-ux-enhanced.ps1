$ErrorActionPreference = "Stop"

$BUCKET = "gemini-demo-20260127092219"
$DIST_ID = "E1YPPQKVA0OGX"
$REGION = "us-east-1"

Write-Host "=== GEMINI3 UX ENHANCED DEPLOYMENT ===" -ForegroundColor Cyan
Write-Host ""

# Upload enhanced version
Write-Host "[STEP 1] Uploading UX-enhanced Gemini3 Guardian..." -ForegroundColor Green
aws s3 cp Gemini3_AllSensesAI/gemini3-guardian-ux-enhanced.html "s3://$BUCKET/index.html" --content-type "text/html" --cache-control "no-store"
Write-Host "  ✓ Enhanced build uploaded" -ForegroundColor Green

# Invalidate CloudFront cache
Write-Host ""
Write-Host "[STEP 2] Invalidating CloudFront cache..." -ForegroundColor Green
$INV_RESULT = aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*" | ConvertFrom-Json
Write-Host "  ✓ Cache invalidated: $($INV_RESULT.Invalidation.Id)" -ForegroundColor Green

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Jury URL:" -ForegroundColor Green
Write-Host "  https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "New Features:" -ForegroundColor Yellow
Write-Host "  ✓ Step 2: Selected Location Panel (lat/lng/source/timestamp/label)" -ForegroundColor White
Write-Host "  ✓ Step 3: Microphone Status Badge (Idle/Listening/Stopped/Error)" -ForegroundColor White
Write-Host "  ✓ Step 3: Live Transcript Box with timestamps" -ForegroundColor White
Write-Host "  ✓ Step 3: Voice Controls (Start/Stop/Clear)" -ForegroundColor White
Write-Host "  ✓ Step 3: Proof logging for mic events" -ForegroundColor White
Write-Host ""
