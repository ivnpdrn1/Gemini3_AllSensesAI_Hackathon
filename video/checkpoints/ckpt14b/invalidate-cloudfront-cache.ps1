# CloudFront Cache Invalidation Script
# Run this if browser is still showing old cached version

$distributionId = "E2NIUI2KOXAO0Q"
$paths = @(
    "/video/index.html",
    "/video/VideoCaptureModule.js",
    "/video/VideoStorageService.js",
    "/video/SignedURLGenerator.js",
    "/video/IntegrationOrchestrator.js"
)

Write-Host "=== CloudFront Cache Invalidation ===" -ForegroundColor Cyan
Write-Host "Distribution: $distributionId" -ForegroundColor Yellow
Write-Host "Paths to invalidate:" -ForegroundColor Yellow
$paths | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
Write-Host ""

Write-Host "Creating invalidation..." -ForegroundColor Yellow

$pathsJson = ($paths | ConvertTo-Json -Compress)
$callerReference = "video-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$invalidationConfig = @"
{
    "Paths": {
        "Quantity": $($paths.Count),
        "Items": $pathsJson
    },
    "CallerReference": "$callerReference"
}
"@

Write-Host "Invalidation config:" -ForegroundColor Gray
Write-Host $invalidationConfig -ForegroundColor Gray
Write-Host ""

try {
    $result = aws cloudfront create-invalidation `
        --distribution-id $distributionId `
        --invalidation-batch $invalidationConfig `
        2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Invalidation created successfully!" -ForegroundColor Green
        Write-Host $result
        Write-Host ""
        Write-Host "⏳ Invalidation typically takes 1-3 minutes to complete" -ForegroundColor Yellow
        Write-Host "   After that, hard refresh your browser (Ctrl+Shift+R)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Invalidation failed!" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} catch {
    Write-Host "❌ Error creating invalidation: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Wait 1-3 minutes for invalidation to complete" -ForegroundColor White
Write-Host "2. Open incognito browser" -ForegroundColor White
Write-Host "3. Navigate to: https://dfc8ght8abwqc.cloudfront.net/video/index.html" -ForegroundColor White
Write-Host "4. Hard refresh (Ctrl+Shift+R)" -ForegroundColor White
Write-Host "5. Test Step 1 button" -ForegroundColor White
