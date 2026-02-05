# Step 2 Live Tracking Local Testing Guide

## Overview

This guide provides step-by-step instructions for testing the live tracking feature locally before deploying to production.

## Prerequisites

- Python 3.12+ installed
- Node.js 18+ installed (for local HTTP server)
- AWS CLI configured
- Backend infrastructure deployed (DynamoDB + Lambda)

---

## Test 1: Backend API Testing

### Step 1.1: Get Lambda Function URL

```powershell
$LAMBDA_URL = aws cloudformation describe-stacks `
  --stack-name AllSensesLiveTracking `
  --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionUrl'].OutputValue" `
  --output text

Write-Host "Lambda URL: $LAMBDA_URL"
```

### Step 1.2: Test PUT Endpoint (Update Location)

```powershell
# Generate test token
$testToken = "test-$(New-Guid)"
Write-Host "Test Token: $testToken"

# Create test payload
$body = @{
    token = $testToken
    latitude = 40.7128
    longitude = -74.0060
    accuracy = 10
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
} | ConvertTo-Json

# Send PUT request
$response = Invoke-RestMethod -Uri $LAMBDA_URL -Method PUT -Body $body -ContentType "application/json"
Write-Host "PUT Response: $($response | ConvertTo-Json)"
```

**Expected Output:**
```json
{
  "success": true
}
```

### Step 1.3: Test GET Endpoint (Retrieve Location)

```powershell
# Send GET request
$response = Invoke-RestMethod -Uri "$LAMBDA_URL?token=$testToken" -Method GET
Write-Host "GET Response: $($response | ConvertTo-Json -Depth 10)"
```

**Expected Output:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 10,
  "timestamp": 1738540800000,
  "age_seconds": 2
}
```

### Step 1.4: Test CORS Preflight

```powershell
# Send OPTIONS request
$headers = @{
    "Origin" = "https://dfc8ght8abwqc.cloudfront.net"
    "Access-Control-Request-Method" = "PUT"
    "Access-Control-Request-Headers" = "Content-Type"
}

Invoke-WebRequest -Uri $LAMBDA_URL -Method OPTIONS -Headers $headers
```

**Expected Headers:**
```
Access-Control-Allow-Origin: https://dfc8ght8abwqc.cloudfront.net
Access-Control-Allow-Methods: GET, PUT, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

---

## Test 2: Frontend Local Testing

### Step 2.1: Update track.html with Lambda URL

```powershell
# Replace placeholder
$trackHtml = Get-Content Gemini3_AllSensesAI/track.html -Raw
$trackHtml = $trackHtml -replace 'REPLACE_WITH_LAMBDA_FUNCTION_URL', $LAMBDA_URL
Set-Content Gemini3_AllSensesAI/track-local.html -Value $trackHtml

Write-Host "Created track-local.html with Lambda URL"
```

### Step 2.2: Serve track.html Locally

```powershell
# Start local HTTP server
cd Gemini3_AllSensesAI
python -m http.server 8080
```

### Step 2.3: Seed Test Data

```powershell
# Create test token
$testToken = "local-test-$(New-Guid)"
Write-Host "Test Token: $testToken"

# Send initial location
$body = @{
    token = $testToken
    latitude = 40.7128
    longitude = -74.0060
    accuracy = 15
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
} | ConvertTo-Json

Invoke-RestMethod -Uri $LAMBDA_URL -Method PUT -Body $body -ContentType "application/json"

# Open tracking page
Start-Process "http://localhost:8080/track-local.html?t=$testToken"
```

### Step 2.4: Simulate Location Updates

```powershell
# Simulate movement (update every 3 seconds)
$lat = 40.7128
$lng = -74.0060

for ($i = 0; $i -lt 10; $i++) {
    # Simulate movement (0.0001 degrees ≈ 11 meters)
    $lat += 0.0001
    $lng += 0.0001
    
    $body = @{
        token = $testToken
        latitude = $lat
        longitude = $lng
        accuracy = 10 + (Get-Random -Minimum -5 -Maximum 5)
        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $LAMBDA_URL -Method PUT -Body $body -ContentType "application/json"
    Write-Host "Updated location: $lat, $lng"
    
    Start-Sleep -Seconds 3
}
```

**Expected Behavior:**
- Tracking page updates every 3 seconds
- Map marker moves smoothly
- "Last update" timestamp refreshes
- Status shows "Live tracking active"

---

## Test 3: Step 2 UI Integration Testing

### Step 3.1: Create Test HTML with Tracking Logic

```powershell
# Create minimal test page
@"
<!DOCTYPE html>
<html>
<head>
    <title>Step 2 Tracking Test</title>
</head>
<body>
    <h1>Step 2 Location Tracking Test</h1>
    <button onclick="testLocationTracking()">Test Location Tracking</button>
    <div id="output"></div>

    <script>
        const LAMBDA_URL = '$LAMBDA_URL';

        function generateUUID() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                const r = Math.random() * 16 | 0;
                const v = c === 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }

        async function sendLocationUpdate(token, lat, lng, accuracy) {
            try {
                const response = await fetch(LAMBDA_URL, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        token: token,
                        latitude: lat,
                        longitude: lng,
                        accuracy: accuracy,
                        timestamp: Date.now()
                    })
                });

                if (response.ok) {
                    console.log('[STEP2] Location update sent:', lat, lng, 'accuracy=' + Math.round(accuracy) + 'm');
                    return true;
                } else {
                    console.log('[STEP2] Location update failed:', response.status);
                    return false;
                }
            } catch (error) {
                console.log('[STEP2] Location update failed:', error.message);
                return false;
            }
        }

        async function testLocationTracking() {
            const output = document.getElementById('output');
            output.innerHTML = '<p>Testing...</p>';

            // Generate token
            const token = generateUUID();
            console.log('[STEP2] Live tracking token created:', token);
            output.innerHTML += '<p>Token: ' + token + '</p>';

            // Create tracking link
            const trackingLink = 'http://localhost:8080/track-local.html?t=' + token;
            console.log('[STEP2] Live tracking link:', trackingLink);
            output.innerHTML += '<p><a href="' + trackingLink + '" target="_blank">View Live Location</a></p>';

            // Simulate location
            const lat = 40.7128;
            const lng = -74.0060;
            const accuracy = 10;

            console.log('[STEP2] Location preview updated:', lat + ',' + lng);
            output.innerHTML += '<p>Location: ' + lat + ', ' + lng + '</p>';

            // Send initial update
            const success = await sendLocationUpdate(token, lat, lng, accuracy);
            output.innerHTML += '<p>Update sent: ' + (success ? 'SUCCESS' : 'FAILED') + '</p>';

            // Simulate periodic updates
            let updateCount = 0;
            const interval = setInterval(async () => {
                updateCount++;
                const newLat = lat + (updateCount * 0.0001);
                const newLng = lng + (updateCount * 0.0001);
                
                await sendLocationUpdate(token, newLat, newLng, accuracy);
                output.innerHTML += '<p>Update ' + updateCount + ': ' + newLat.toFixed(6) + ', ' + newLng.toFixed(6) + '</p>';

                if (updateCount >= 5) {
                    clearInterval(interval);
                    output.innerHTML += '<p><strong>Test complete!</strong></p>';
                }
            }, 3000);
        }
    </script>
</body>
</html>
"@ | Set-Content Gemini3_AllSensesAI/test-step2-tracking.html

Write-Host "Created test-step2-tracking.html"
```

### Step 3.2: Run Test

```powershell
# Open test page
Start-Process "http://localhost:8080/test-step2-tracking.html"
```

**Expected Console Output:**
```
[STEP2] Live tracking token created: a1b2c3d4-e5f6-7890-abcd-ef1234567890
[STEP2] Live tracking link: http://localhost:8080/track-local.html?t=a1b2c3d4-...
[STEP2] Location preview updated: 40.7128,-74.0060
[STEP2] Location update sent: 40.7128 -74.0060 accuracy=10m
[STEP2] Location update sent: 40.7129 -74.0061 accuracy=10m
[STEP2] Location update sent: 40.7130 -74.0062 accuracy=10m
```

---

## Test 4: Map Preview Testing

### Step 4.1: Test Google Static Maps API

```powershell
# Generate test URL (requires API key)
$lat = 40.7128
$lng = -74.0060
$apiKey = "YOUR_GOOGLE_STATIC_MAPS_API_KEY"  # Replace with actual key
$previewUrl = "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=600x300&scale=2&markers=color:red|$lat,$lng&key=$apiKey"

Write-Host "Preview URL: $previewUrl"

# Test in browser
Start-Process $previewUrl
```

**Expected Result:**
- Image loads successfully
- Shows map centered on coordinates
- Red marker at exact location

**Note:** If no API key is configured, the fallback message will be shown instead.

### Step 4.2: Test Fallback Behavior

```powershell
# Create test page with fallback
@"
<!DOCTYPE html>
<html>
<head>
    <title>Map Preview Fallback Test</title>
</head>
<body>
    <h1>Map Preview Fallback Test</h1>
    
    <h2>With API Key (should load if key is valid)</h2>
    <img id="validPreview" src="https://maps.googleapis.com/maps/api/staticmap?center=40.7128,-74.0060&zoom=16&size=600x300&scale=2&markers=color:red|40.7128,-74.0060&key=YOUR_KEY_HERE" 
         alt="Loading..." 
         onerror="this.alt='Map preview unavailable (API error)'; console.log('[STEP2] Map preview failed');">
    
    <h2>Without API Key (should show fallback)</h2>
    <p>Map preview unavailable (no key). Use the live map link below.</p>
    
    <h2>Invalid URL (should show fallback)</h2>
    <img id="invalidPreview" src="https://invalid-domain-that-does-not-exist.com/map.png" 
         alt="Loading..." 
         onerror="this.alt='Map preview unavailable (API error)'; console.log('[STEP2] Map preview failed');">
</body>
</html>
"@ | Set-Content Gemini3_AllSensesAI/test-map-preview.html

Start-Process "http://localhost:8080/test-map-preview.html"
```

**Expected Behavior:**
- First image loads if API key is valid
- Second section shows fallback message (no key configured)
- Third image shows "Map preview unavailable (API error)"
- Console logs `[STEP2] Map preview failed` for failed images

---

## Test 5: End-to-End Integration Test

### Step 5.1: Full Workflow Test

```powershell
# Run complete workflow test
@"
1. Open test page: http://localhost:8080/test-step2-tracking.html
2. Click 'Test Location Tracking' button
3. Verify console logs show:
   - Token created
   - Tracking link generated
   - Location preview updated
   - Location updates sent (5 times)
4. Click 'View Live Location' link
5. Verify tracking page shows:
   - Live map with marker
   - Coordinates updating every 3 seconds
   - 'Live tracking active' status
   - Accuracy radius circle
6. Wait 60 seconds without updates
7. Verify tracking page shows:
   - 'Location data is stale' warning
   - Yellow status dot
8. Resume updates
9. Verify tracking page returns to 'Live tracking active'
"@ | Write-Host
```

---

## Test 6: Error Handling Tests

### Step 6.1: Test Invalid Token

```powershell
# Try to retrieve non-existent token
$invalidToken = "invalid-token-12345"
try {
    Invoke-RestMethod -Uri "$LAMBDA_URL?token=$invalidToken" -Method GET
} catch {
    Write-Host "Expected error: $($_.Exception.Message)"
}
```

**Expected Output:**
```
404 Not Found: Token not found
```

### Step 6.2: Test Invalid Coordinates

```powershell
# Try to send invalid coordinates
$body = @{
    token = "test-token"
    latitude = 999  # Invalid
    longitude = -74.0060
    accuracy = 10
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $LAMBDA_URL -Method PUT -Body $body -ContentType "application/json"
} catch {
    Write-Host "Expected error: $($_.Exception.Message)"
}
```

**Expected Output:**
```
400 Bad Request: Invalid coordinates
```

---

## Test 7: Performance Testing

### Step 7.1: Concurrent Updates Test

```powershell
# Simulate 10 concurrent location updates
$tokens = 1..10 | ForEach-Object { "perf-test-$(New-Guid)" }

$jobs = $tokens | ForEach-Object {
    $token = $_
    Start-Job -ScriptBlock {
        param($url, $token)
        
        for ($i = 0; $i -lt 20; $i++) {
            $body = @{
                token = $token
                latitude = 40.7128 + ($i * 0.0001)
                longitude = -74.0060 + ($i * 0.0001)
                accuracy = 10
                timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $url -Method PUT -Body $body -ContentType "application/json"
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $LAMBDA_URL, $token
}

# Wait for all jobs to complete
$jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

Write-Host "Performance test complete: 200 updates sent"
```

**Expected Result:**
- All 200 updates succeed
- No throttling errors
- Average response time < 100ms

---

## Verification Checklist

- [ ] Backend PUT endpoint accepts location updates
- [ ] Backend GET endpoint retrieves latest location
- [ ] CORS headers present on all responses
- [ ] track.html loads and displays map
- [ ] track.html polls backend every 3 seconds
- [ ] Map marker updates smoothly
- [ ] Stale data warning appears after 60s
- [ ] Map preview image loads from Google Static Maps (if key configured)
- [ ] Map preview fallback works when no key or on error
- [ ] Google Maps link opens correctly
- [ ] Step 2 UI generates UUID token
- [ ] Step 2 UI creates tracking link
- [ ] Step 2 UI sends periodic updates
- [ ] Console proof logs present
- [ ] Invalid token returns 404
- [ ] Invalid coordinates return 400
- [ ] Concurrent updates succeed

---

## Cleanup

```powershell
# Stop local HTTP server (Ctrl+C)

# Remove test files
Remove-Item Gemini3_AllSensesAI/track-local.html -ErrorAction SilentlyContinue
Remove-Item Gemini3_AllSensesAI/test-step2-tracking.html -ErrorAction SilentlyContinue
Remove-Item Gemini3_AllSensesAI/test-map-preview.html -ErrorAction SilentlyContinue

Write-Host "Cleanup complete"
```

---

## Next Steps

After successful local testing:

1. Review all proof logs
2. Verify no regressions in Step 1 or Step 3
3. Document Lambda Function URL in `.env`
4. Request Ivan's approval for production deployment
5. Follow deployment guide: `STEP2_LIVE_TRACKING_DEPLOYMENT.md`
