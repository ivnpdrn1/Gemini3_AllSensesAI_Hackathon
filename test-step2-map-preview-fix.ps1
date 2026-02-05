# Step 2 Map Preview Fix - Local Test Script
# DO NOT DEPLOY - Local testing only

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2 Map Preview Fix - Local Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test File: gemini3-guardian-production-sms-video-REBUILT.html" -ForegroundColor Yellow
Write-Host ""

Write-Host "MANUAL TEST STEPS:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Open Chrome Incognito window" -ForegroundColor White
Write-Host "2. Open: Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html" -ForegroundColor White
Write-Host "3. Hard refresh (Ctrl+Shift+R)" -ForegroundColor White
Write-Host "4. Open DevTools Console (F12)" -ForegroundColor White
Write-Host ""

Write-Host "TEST SCENARIO 1: Without API Key (Default)" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "5. Complete Step 1 (enter name + phone)" -ForegroundColor White
Write-Host "6. Click 'Use Demo Location' button" -ForegroundColor White
Write-Host ""
Write-Host "VERIFY:" -ForegroundColor Yellow
Write-Host "  - Console shows: [STEP2][MAP] using Google Maps embed (no key)" -ForegroundColor White
Write-Host "  - Console shows: [STEP2][MAP] embed loaded (google)" -ForegroundColor White
Write-Host "  - Map preview appears as IFRAME (not broken image)" -ForegroundColor White
Write-Host "  - Live link opens Google Maps in new tab" -ForegroundColor White
Write-Host "  - Coordinates displayed correctly" -ForegroundColor White
Write-Host ""
Write-Host "7. Trigger Step 4 emergency alert" -ForegroundColor White
Write-Host ""
Write-Host "VERIFY:" -ForegroundColor Yellow
Write-Host "  - Console shows: [STEP4][MAP] Using Google Maps embed (no key)" -ForegroundColor White
Write-Host "  - Console shows: [STEP4][MAP] embed loaded (google)" -ForegroundColor White
Write-Host "  - Map preview appears as IFRAME in emergency alert" -ForegroundColor White
Write-Host ""

Write-Host "TEST SCENARIO 2: With API Key (Optional)" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "8. Add to HTML <head> section:" -ForegroundColor White
Write-Host "   <script>" -ForegroundColor Gray
Write-Host "       window.__GOOGLE_STATIC_MAPS_KEY__ = 'YOUR_API_KEY_HERE';" -ForegroundColor Gray
Write-Host "   </script>" -ForegroundColor Gray
Write-Host ""
Write-Host "9. Repeat steps 5-7" -ForegroundColor White
Write-Host ""
Write-Host "VERIFY:" -ForegroundColor Yellow
Write-Host "  - Console shows: [STEP2][MAP] preview loaded (google static)" -ForegroundColor White
Write-Host "  - Map preview appears as IMAGE (not iframe)" -ForegroundColor White
Write-Host "  - Console shows: [STEP4][MAP] Using Google Static Maps API with key" -ForegroundColor White
Write-Host "  - Console shows: [STEP4][MAP] preview loaded (google static)" -ForegroundColor White
Write-Host ""

Write-Host "ZERO REGRESSIONS CHECKLIST:" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "  [ ] Step 1 configuration works" -ForegroundColor White
Write-Host "  [ ] Step 2 location services work" -ForegroundColor White
Write-Host "  [ ] Step 3 voice detection works" -ForegroundColor White
Write-Host "  [ ] Step 4 emergency alert works" -ForegroundColor White
Write-Host "  [ ] Live link opens Google Maps" -ForegroundColor White
Write-Host "  [ ] Map preview visible (not broken)" -ForegroundColor White
Write-Host "  [ ] No Yandex visible in UI" -ForegroundColor White
Write-Host "  [ ] No Yandex requests in Network tab" -ForegroundColor White
Write-Host ""

Write-Host "NETWORK TAB VERIFICATION:" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "1. Open DevTools Network tab" -ForegroundColor White
Write-Host "2. Filter: 'yandex'" -ForegroundColor White
Write-Host "3. Complete Step 1 -> Step 2 -> Step 4" -ForegroundColor White
Write-Host "4. VERIFY: Zero requests to yandex.com" -ForegroundColor White
Write-Host ""

Write-Host "SCREENSHOT PROOF REQUIRED:" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Yellow
Write-Host "1. Console logs showing dual-mode detection" -ForegroundColor White
Write-Host "2. Map preview visible (iframe or image)" -ForegroundColor White
Write-Host "3. Network tab showing no Yandex requests" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DO NOT DEPLOY UNTIL IVAN APPROVES" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
