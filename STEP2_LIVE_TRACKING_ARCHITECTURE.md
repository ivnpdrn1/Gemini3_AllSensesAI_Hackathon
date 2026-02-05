# Step 2 Live Tracking Architecture

## Overview

Step 2 now delivers TWO location verification mechanisms:

### A) Map Preview Image (Snapshot)
- **Purpose:** Victim sees visual confirmation of location before sending
- **Implementation:** Static map image from Google Maps Static API
- **Provider:** Google Maps Static API (Google Hackathon alignment)
- **API Key:** Configurable via `window.__GOOGLE_STATIC_MAPS_KEY__` (not hardcoded)
- **Fallback:** Clear message if preview fails or key missing, does NOT block Step 2
- **URL Format:** `https://maps.googleapis.com/maps/api/staticmap?center=<lat>,<lng>&zoom=16&size=600x300&scale=2&markers=color:red|<lat>,<lng>&key=<KEY>`

### B) Live Tracking Link (Continuous Updates)
- **Purpose:** Emergency contact sees victim's location as they move
- **Implementation:** Custom tracking page with backend polling
- **URL Format:** `https://dfc8ght8abwqc.cloudfront.net/track.html?t=<UUID>`
- **Update Frequency:** Every 5-10 seconds while GPS active
- **Data Retention:** 24 hours (emergency window), then auto-expire

## System Components

### 1. Frontend (Step 2 UI)
**File:** `gemini3-guardian-production-sms-video-REBUILT.html`

**New Responsibilities:**
- Generate tracking token (UUID v4)
- Display map preview image
- Display live tracking link
- Periodically update backend with latest position
- Handle preview failures gracefully

**New Proof Logs:**
```javascript
[STEP2] Location preview updated: 40.7128,-74.0060
[STEP2] Live tracking token created: a1b2c3d4-e5f6-7890-abcd-ef1234567890
[STEP2] Live tracking link: https://dfc8ght8abwqc.cloudfront.net/track.html?t=a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### 2. Live Tracking Viewer
**File:** `track.html`

**Responsibilities:**
- Extract token from URL query parameter
- Poll backend every 3 seconds for latest location
- Render live map (Yandex Maps or Leaflet)
- Display "last updated" timestamp
- Show accuracy radius if available
- Handle stale data (>60s = warning)

### 3. Backend Infrastructure

#### DynamoDB Table
**Table Name:** `AllSensesLiveTracking`

**Schema:**
- **Partition Key:** `token` (String) - UUID
- **Attributes:**
  - `latitude` (Number)
  - `longitude` (Number)
  - `accuracy` (Number) - meters
  - `timestamp` (Number) - Unix epoch milliseconds
  - `ttl` (Number) - Unix epoch seconds (24h expiration)

**Indexes:** None required (simple key-value lookup)

**Capacity:** On-demand (burst-friendly for emergency scenarios)

#### Lambda Function URL
**Function Name:** `AllSensesLocationTrackerHandler`

**Runtime:** Python 3.12

**Endpoints:**
- **PUT /update:** Update location for token
  - Body: `{"token": "...", "latitude": 40.7128, "longitude": -74.0060, "accuracy": 10, "timestamp": 1738540800000}`
  - Response: `{"success": true}`
  
- **GET /latest:** Retrieve latest location
  - Query: `?token=a1b2c3d4-...`
  - Response: `{"latitude": 40.7128, "longitude": -74.0060, "accuracy": 10, "timestamp": 1738540800000, "age_seconds": 5}`

**CORS Configuration:**
- Allow Origin: `https://dfc8ght8abwqc.cloudfront.net`
- Allow Methods: GET, PUT, OPTIONS
- Allow Headers: Content-Type

**IAM Permissions:**
- DynamoDB: PutItem, GetItem on `AllSensesLiveTracking` table

## Data Flow

### Location Update Flow (Client → Backend)
1. Step 2 obtains GPS position
2. Client calls Lambda PUT endpoint with token + coordinates
3. Lambda writes to DynamoDB with 24h TTL
4. Client repeats every 5-10 seconds while GPS active

### Location Retrieval Flow (Viewer → Backend)
1. Emergency contact opens tracking link
2. track.html extracts token from URL
3. JavaScript polls Lambda GET endpoint every 3 seconds
4. Lambda reads from DynamoDB
5. track.html renders location on map + timestamp

## Security Considerations

### Token Security
- UUID v4 provides 122 bits of entropy (unguessable)
- No authentication required (emergency access priority)
- 24-hour TTL limits exposure window
- Token only shared with emergency contacts via SMS

### Data Privacy
- No PII stored (only coordinates + timestamp)
- Automatic expiration after 24 hours
- No logging of token access patterns
- CORS restricts to CloudFront domain

### Abuse Prevention
- DynamoDB on-demand capacity (no fixed limits)
- Lambda concurrency limits prevent runaway costs
- TTL ensures automatic cleanup
- No public listing of active tokens

## Failure Modes & Fallbacks

### Map Preview Failure
- **Cause:** Network error, API rate limit, invalid coordinates
- **Behavior:** Show fallback message "Map preview unavailable"
- **Impact:** None - Step 2 continues normally
- **Proof Log:** `[STEP2] Map preview failed: <error>`

### Live Tracking Backend Failure
- **Cause:** Lambda timeout, DynamoDB throttling, network error
- **Behavior:** track.html shows "Unable to load location"
- **Impact:** Emergency contact sees last known position (if any)
- **Fallback:** SMS still contains static lat/lng coordinates

### GPS Signal Loss
- **Cause:** Indoor location, urban canyon, device limitations
- **Behavior:** Updates stop, track.html shows stale data warning
- **Impact:** Last known position remains visible
- **User Feedback:** "Location last updated 2 minutes ago"

## Cost Estimation

### DynamoDB
- **Writes:** ~120 per emergency (10 min × 12 updates/min)
- **Reads:** ~600 per viewer (10 min × 20 polls/min × 3 viewers)
- **Cost:** ~$0.01 per emergency (on-demand pricing)

### Lambda
- **Invocations:** ~720 per emergency (120 writes + 600 reads)
- **Duration:** ~50ms average
- **Cost:** ~$0.001 per emergency (free tier covers most usage)

### Total Cost
- **Per Emergency:** ~$0.011
- **Monthly (100 emergencies):** ~$1.10
- **Negligible compared to SMS costs**

## Deployment Checklist

- [ ] Deploy DynamoDB table with TTL enabled
- [ ] Deploy Lambda function with Function URL
- [ ] Configure CORS on Lambda Function URL
- [ ] Grant Lambda IAM permissions for DynamoDB
- [ ] Upload track.html to S3 bucket
- [ ] Invalidate CloudFront cache for track.html
- [ ] Update Step 2 UI with tracking logic
- [ ] Test end-to-end: update → poll → render
- [ ] Verify TTL expiration (24h test)
- [ ] Document Lambda Function URL in .env

## Monitoring & Observability

### CloudWatch Metrics
- Lambda invocation count (PUT vs GET)
- Lambda error rate
- Lambda duration (p50, p99)
- DynamoDB consumed capacity

### Proof Logs (Browser Console)
- `[STEP2] Location preview updated: <lat,lng>`
- `[STEP2] Live tracking token created: <token>`
- `[STEP2] Live tracking link: <URL>`
- `[STEP2] Location update sent: <lat,lng> accuracy=<m>`
- `[STEP2] Location update failed: <error>`

### Viewer Logs (track.html Console)
- `[TRACK] Polling for token: <token>`
- `[TRACK] Location received: <lat,lng> age=<seconds>s`
- `[TRACK] Stale data warning: last update <minutes>m ago`
- `[TRACK] Backend error: <error>`

## Future Enhancements (Out of Scope)

- Battery-aware update frequency (reduce when low)
- Geofencing alerts (victim leaves safe zone)
- Historical breadcrumb trail (last 10 positions)
- Multi-viewer support (show # of active viewers)
- End-to-end encryption (viewer requires passphrase)
