# Uploaded S3 Keys - Checkpoint 14

## Video Variant Deployment

### HTML File
```
s3://YOUR-BUCKET-NAME/video/index.html
```
- **Content-Type:** `text/html`
- **Cache-Control:** `max-age=0, no-cache, no-store, must-revalidate`
- **Source:** `Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html`

### JavaScript Modules

#### 1. VideoCaptureModule.js
```
s3://YOUR-BUCKET-NAME/video/VideoCaptureModule.js
```
- **Content-Type:** `application/javascript`
- **Cache-Control:** `max-age=0, no-cache, no-store, must-revalidate`
- **Source:** `Gemini3_AllSensesAI/video/release/rc1/VideoCaptureModule.js`
- **Size:** ~8.4 KB

#### 2. VideoStorageService.js
```
s3://YOUR-BUCKET-NAME/video/VideoStorageService.js
```
- **Content-Type:** `application/javascript`
- **Cache-Control:** `max-age=0, no-cache, no-store, must-revalidate`
- **Source:** `Gemini3_AllSensesAI/video/release/rc1/VideoStorageService.js`
- **Size:** ~10 KB

#### 3. SignedURLGenerator.js
```
s3://YOUR-BUCKET-NAME/video/SignedURLGenerator.js
```
- **Content-Type:** `application/javascript`
- **Cache-Control:** `max-age=0, no-cache, no-store, must-revalidate`
- **Source:** `Gemini3_AllSensesAI/video/release/rc1/SignedURLGenerator.js`
- **Size:** ~11.6 KB

#### 4. IntegrationOrchestrator.js
```
s3://YOUR-BUCKET-NAME/video/IntegrationOrchestrator.js
```
- **Content-Type:** `application/javascript`
- **Cache-Control:** `max-age=0, no-cache, no-store, must-revalidate`
- **Source:** `Gemini3_AllSensesAI/video/release/rc1/IntegrationOrchestrator.js`
- **Size:** ~7.8 KB

---

## CloudFront URLs

### Video Variant (NEW)
```
https://dfc8ght8abwqc.cloudfront.net/video/index.html
https://dfc8ght8abwqc.cloudfront.net/video/VideoCaptureModule.js
https://dfc8ght8abwqc.cloudfront.net/video/VideoStorageService.js
https://dfc8ght8abwqc.cloudfront.net/video/SignedURLGenerator.js
https://dfc8ght8abwqc.cloudfront.net/video/IntegrationOrchestrator.js
```

### Baseline Production (UNCHANGED)
```
https://dfc8ght8abwqc.cloudfront.net/
```

---

## Invalidation Paths

If manual invalidation is needed:

```
/video/index.html
/video/VideoCaptureModule.js
/video/VideoStorageService.js
/video/SignedURLGenerator.js
/video/IntegrationOrchestrator.js
```

**OR use wildcard:**
```
/video/*
```

---

## Verification Commands

### List all video files in S3:
```powershell
aws s3 ls s3://YOUR-BUCKET-NAME/video/ --recursive
```

### Check Content-Type for each file:
```powershell
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/index.html
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/VideoCaptureModule.js
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/VideoStorageService.js
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/SignedURLGenerator.js
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/IntegrationOrchestrator.js
```

### Test URLs with curl:
```bash
curl -I https://dfc8ght8abwqc.cloudfront.net/video/index.html
curl -I https://dfc8ght8abwqc.cloudfront.net/video/VideoCaptureModule.js
curl -I https://dfc8ght8abwqc.cloudfront.net/video/VideoStorageService.js
curl -I https://dfc8ght8abwqc.cloudfront.net/video/SignedURLGenerator.js
curl -I https://dfc8ght8abwqc.cloudfront.net/video/IntegrationOrchestrator.js
```

**Expected:** All return `200 OK` with correct Content-Type

---

## Deployment Command

```powershell
.\deploy-production-sms-video.ps1 `
    -BucketName YOUR-BUCKET-NAME `
    -DistributionId YOUR-DISTRIBUTION-ID `
    -Region us-east-1
```

**With skip invalidation (if AWS CLI v1):**
```powershell
.\deploy-production-sms-video.ps1 `
    -BucketName YOUR-BUCKET-NAME `
    -DistributionId YOUR-DISTRIBUTION-ID `
    -Region us-east-1 `
    -SkipInvalidation
```

---

## File Manifest

| Local Path | S3 Key | CloudFront URL |
|------------|--------|----------------|
| `Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html` | `video/index.html` | `/video/index.html` |
| `Gemini3_AllSensesAI/video/release/rc1/VideoCaptureModule.js` | `video/VideoCaptureModule.js` | `/video/VideoCaptureModule.js` |
| `Gemini3_AllSensesAI/video/release/rc1/VideoStorageService.js` | `video/VideoStorageService.js` | `/video/VideoStorageService.js` |
| `Gemini3_AllSensesAI/video/release/rc1/SignedURLGenerator.js` | `video/SignedURLGenerator.js` | `/video/SignedURLGenerator.js` |
| `Gemini3_AllSensesAI/video/release/rc1/IntegrationOrchestrator.js` | `video/IntegrationOrchestrator.js` | `/video/IntegrationOrchestrator.js` |

---

**Total Files:** 5 (1 HTML + 4 JS modules)  
**Total Size:** ~38 KB (uncompressed)  
**Deployment Path:** `/video/` (isolated from baseline production)
