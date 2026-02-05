# Step 2 Live Tracking Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate credentials
- CloudFormation stack deployment permissions
- S3 bucket: `allsenses-production-frontend`
- CloudFront distribution: `E2NIUI2KOXAO0Q` (dfc8ght8abwqc.cloudfront.net)

## Deployment Steps

### Step 1: Deploy Backend Infrastructure

```powershell
# Deploy DynamoDB + Lambda Function URL
aws cloudformation deploy `
  --template-file infrastructure/step2-live-tracking.yaml `
  --stack-name AllSensesLiveTracking `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

# Get Lambda Function URL
$LAMBDA_URL = aws cloudformation describe-stacks `
  --stack-name AllSensesLiveTracking `
  --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionUrl'].OutputValue" `
  --output text

Write-Host "Lambda Function URL: $LAMBDA_URL"
```

**Expected Output:**
```
Lambda Function URL: https://abc123xyz.lambda-url.us-east-1.on.aws/
```

**Save this URL** - you'll need it for the next steps.

---

### Step 2: Update track.html with Lambda URL

```powershell
# Replace placeholder with actual Lambda URL
$trackHtml = Get-Content Gemini3_AllSensesAI/track.html -Raw
$trackHtml = $trackHtml -replace 'REPLACE_WITH_LAMBDA_FUNCTION_URL', $LAMBDA_URL
Set-Content Gemini3_AllSensesAI/track.html -Value $trackHtml

Write-Host "Updated track.html with Lambda URL"
```

---

### Step 3: Upload track.html to S3

```powershell
# Upload to S3
aws s3 cp Gemini3_AllSensesAI/track.html `
  s3://allsenses-production-frontend/track.html `
  --content-type "text/html" `
  --cache-control "max-age=300"

Write-Host "Uploaded track.html to S3"
```

---

### Step 4: Invalidate CloudFront Cache

```powershell
# Invalidate CloudFront cache for track.html
aws cloudfront create-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --paths "/track.html"

Write-Host "CloudFront cache invalidated"
```

---

### Step 5: Update Step 2 UI (Frontend)

**File:** `Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html`

Add the following JavaScript code to Step 2 location success handler:

```javascript
// STEP 2: Location Success Handler
async function handleLocationSuccess(position) {
    const lat = position.coords.latitude;
    const lng = position.coords.longitude;
    const accuracy = position.coords.accuracy;

    console.log('[STEP2][PROOF 3A] SUCCESS', lat, lng);

    // Generate tracking token
    const trackingToken = generateUUID();
    console.log('[STEP2] Live tracking token created:', trackingToken);

    // Create live tracking link
    const trackingLink = `https://dfc8ght8abwqc.cloudfront.net/track.html?t=${trackingToken}`;
    console.log('[STEP2] Live tracking link:', trackingLink);

    // Display map preview (Google Static Maps API)
    const GOOGLE_STATIC_MAPS_KEY = window.__GOOGLE_STATIC_MAPS_KEY__ || "";
    if (GOOGLE_STATIC_MAPS_KEY) {
        const previewUrl = `https://maps.googleapis.com/maps/api/staticmap?center=${lat},${lng}&zoom=16&size=600x300&scale=2&markers=color:red|${lat},${lng}&key=${GOOGLE_STATIC_MAPS_KEY}`;
        document.getElementById('mapPreview').src = previewUrl;
        document.getElementById('mapPreview').onerror = () => {
            console.log('[STEP2] Map preview failed');
            document.getElementById('mapPreview').alt = 'Map preview unavailable (API error)';
        };
        console.log('[STEP2] Location preview updated:', `${lat},${lng}`);
    } else {
        console.log('[STEP2] Map preview unavailable (no API key)');
        document.getElementById('mapPreview').alt = 'Map preview unavailable (no key). Use the live map link below.';
    }

    // Display live tracking link
    document.getElementById('trackingLink').href = trackingLink;
    document.getElementById('trackingLink').textContent = 'View Live Location';

    // Display Google Maps link for victim
    const googleMapsLink = `https://www.google.com/maps?q=${lat},${lng}`;
    document.getElementById('googleMapsLink').href = googleMapsLink;
    document.getElementById('googleMapsLink').textContent = 'Open in Google Maps';

    // Start periodic location updates
    startLocationUpdates(trackingToken, lat, lng, accuracy);
}

// Generate UUID v4
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Start periodic location updates
let updateInterval = null;

function startLocationUpdates(token, initialLat, initialLng, initialAccuracy) {
    // Send initial update
    sendLocationUpdate(token, initialLat, initialLng, initialAccuracy);

    // Clear any existing interval
    if (updateInterval) {
        clearInterval(updateInterval);
    }

    // Update every 5 seconds
    updateInterval = setInterval(() => {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                sendLocationUpdate(
                    token,
                    position.coords.latitude,
                    position.coords.longitude,
                    position.coords.accuracy
                );
            },
            (error) => {
                console.log('[STEP2] Location update failed:', error.message);
            },
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
        );
    }, 5000);
}

// Send location update to backend
async function sendLocationUpdate(token, lat, lng, accuracy) {
    const LAMBDA_URL = 'REPLACE_WITH_LAMBDA_FUNCTION_URL'; // Replace with actual URL

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
            console.log('[STEP2] Location update sent:', `${lat},${lng}`, `accuracy=${Math.round(accuracy)}m`);
        } else {
            console.log('[STEP2] Location update failed:', response.status);
        }
    } catch (error) {
        console.log('[STEP2] Location update failed:', error.message);
    }
}

// Stop updates when leaving Step 2
function stopLocationUpdates() {
    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
        console.log('[STEP2] Location updates stopped');
    }
}
```

**HTML Changes:**

Add to Step 2 UI:

```html
<!-- Map Preview (Google Static Maps) -->
<div class="map-preview-container">
    <img id="mapPreview" alt="Loading map preview..." style="width: 100%; max-width: 600px; border-radius: 8px;">
</div>

<!-- Map Links -->
<div class="map-links-container" style="margin-top: 12px; display: flex; gap: 16px; flex-wrap: wrap;">
    <a id="googleMapsLink" href="#" target="_blank" style="color: #667eea; font-weight: 600;">
        Open in Google Maps
    </a>
    <a id="trackingLink" href="#" target="_blank" style="color: #667eea; font-weight: 600;">
        View Live Location
    </a>
</div>
```

---

### Step 6: Deploy Updated Frontend

```powershell
# Upload updated HTML to S3
aws s3 cp Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html `
  s3://allsenses-production-frontend/index.html `
  --content-type "text/html" `
  --cache-control "max-age=300"

# Invalidate CloudFront cache
aws cloudfront create-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --paths "/index.html"

Write-Host "Frontend deployed and cache invalidated"
```

---

### Step 7: Verification

#### Test Backend Endpoints

```powershell
# Test PUT (update location)
$testToken = "test-$(New-Guid)"
$body = @{
    token = $testToken
    latitude = 40.7128
    longitude = -74.0060
    accuracy = 10
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
} | ConvertTo-Json

Invoke-RestMethod -Uri $LAMBDA_URL -Method PUT -Body $body -ContentType "application/json"

# Test GET (retrieve location)
Invoke-RestMethod -Uri "$LAMBDA_URL?token=$testToken" -Method GET
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

#### Test Frontend

1. Open: `https://dfc8ght8abwqc.cloudfront.net/`
2. Navigate to Step 2 (Enable Location)
3. Grant location permission
4. Verify console logs:
   ```
   [STEP2] Location preview updated: 40.7128,-74.0060
   [STEP2] Live tracking token created: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   [STEP2] Live tracking link: https://dfc8ght8abwqc.cloudfront.net/track.html?t=a1b2c3d4-...
   [STEP2] Location update sent: 40.7128,-74.0060 accuracy=10m
   ```
5. Click "View Live Location" link
6. Verify tracking page shows live updates

---

## Rollback Procedure

If issues occur, rollback to stable checkpoint:

```powershell
# Restore frontend from git tag
cd Gemini3_AllSensesAI
git checkout v2026.02.03-step2-stable

# Redeploy stable version
aws s3 cp gemini3-guardian-production-sms-video-REBUILT.html `
  s3://allsenses-production-frontend/index.html `
  --content-type "text/html"

aws cloudfront create-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --paths "/index.html"

# Delete backend stack (optional)
aws cloudformation delete-stack --stack-name AllSensesLiveTracking
```

---

## Monitoring

### CloudWatch Logs

```powershell
# View Lambda logs
aws logs tail /aws/lambda/AllSensesLocationTrackerHandler --follow
```

### DynamoDB Metrics

```powershell
# Check consumed capacity
aws cloudwatch get-metric-statistics `
  --namespace AWS/DynamoDB `
  --metric-name ConsumedReadCapacityUnits `
  --dimensions Name=TableName,Value=AllSensesLiveTracking `
  --start-time (Get-Date).AddHours(-1).ToUniversalTime() `
  --end-time (Get-Date).ToUniversalTime() `
  --period 300 `
  --statistics Sum
```

---

## Cost Estimation

**Per Emergency (10 minutes):**
- DynamoDB writes: 120 (12/min × 10 min) = $0.00015
- DynamoDB reads: 600 (20/min × 10 min × 3 viewers) = $0.00075
- Lambda invocations: 720 = $0.00014
- **Total: ~$0.001 per emergency**

**Monthly (100 emergencies):**
- **Total: ~$0.10/month**

---

## Troubleshooting

### Issue: "Token not found" error

**Cause:** Location updates not reaching backend

**Solution:**
1. Check Lambda URL in frontend code
2. Verify CORS configuration
3. Check browser console for fetch errors

### Issue: Map preview fails to load

**Cause:** Yandex Maps API rate limit or network error

**Solution:**
- Fallback message already implemented
- Does NOT block Step 2 functionality
- Consider alternative provider if persistent

### Issue: Stale location data

**Cause:** GPS signal loss or update interval too long

**Solution:**
- Reduce update interval (currently 5s)
- Implement battery-aware updates
- Show clear "stale data" warning (already implemented)

---

## Security Notes

- Lambda Function URL is public (emergency access priority)
- Token provides 122 bits of entropy (unguessable)
- 24-hour TTL limits exposure window
- CORS restricts to CloudFront domain
- No PII stored (only coordinates + timestamp)

---

## Next Steps

After successful deployment:

1. Test with real device GPS
2. Verify multi-viewer support (3+ simultaneous viewers)
3. Monitor CloudWatch metrics for 24 hours
4. Document Lambda Function URL in `.env` file
5. Update SMS template to include tracking link
