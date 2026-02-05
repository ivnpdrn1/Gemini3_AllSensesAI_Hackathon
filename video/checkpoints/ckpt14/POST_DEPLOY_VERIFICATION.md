# Post-Deploy Verification Checklist
## Video Variant Hotfix - Checkpoint 14

**Date:** 2026-02-01  
**Build:** GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1  
**CloudFront URL:** https://dfc8ght8abwqc.cloudfront.net/video/index.html

---

## ✅ TASK 5 — Post-Deploy Verification

### 1. Network Tab Verification (CRITICAL)

Open browser DevTools → Network tab → Load `/video/index.html`

**Expected Results:**

| Resource | Status | Content-Type | Notes |
|----------|--------|--------------|-------|
| `/video/index.html` | 200 | `text/html` | Main HTML file |
| `/video/VideoCaptureModule.js` | 200 | `application/javascript` | NOT 403 |
| `/video/VideoStorageService.js` | 200 | `application/javascript` | NOT 403 |
| `/video/SignedURLGenerator.js` | 200 | `application/javascript` | NOT 403 |
| `/video/IntegrationOrchestrator.js` | 200 | `application/javascript` | NOT 403 |

**❌ FAILURE CRITERIA:**
- Any JS file returns 403 (Forbidden)
- Any JS file has Content-Type: `text/html` (means CloudFront returned error page)
- Any JS file is missing from network log

**If any JS still returns 403:**
1. Stop immediately
2. Report which path failed
3. Check S3 bucket to verify file exists at correct path
4. Check CloudFront behavior rules for `/video/*` path pattern
5. Verify S3 bucket policy allows CloudFront OAI to read `/video/*`

---

### 2. Console Verification (CRITICAL)

Open browser DevTools → Console tab → Load `/video/index.html`

**Expected Results:**

✅ **NO** "Uncaught SyntaxError: Unexpected token 'function'"  
✅ **NO** "Uncaught ReferenceError: completeStep1 is not defined"  
✅ **NO** 403 errors for any JS modules  
✅ Step 1 button works normally (onclick handler defined)  
✅ Runtime health check shows all modules loaded

**❌ FAILURE CRITERIA:**
- SyntaxError appears (means JS file returned HTML/403)
- ReferenceError for `completeStep1` (means script execution aborted)
- Any 403 errors in console
- Step 1 button does not respond to clicks

---

### 3. Functional Verification

**Step 1 Test:**
1. Enter name and phone number
2. Click "✅ Complete Step 1" button
3. Verify button responds and step completes

**Expected:** Button works, no console errors

**Step 2 Test:**
1. Click "📍 Enable Location" button
2. Verify location permission prompt appears

**Expected:** Location flow works normally

**Step 3 Test:**
1. Click "🎤 Start Voice Detection" button
2. Verify microphone permission prompt appears

**Expected:** Voice detection flow works normally

---

### 4. Baseline Production Verification

**CRITICAL:** Verify baseline production URL is unchanged

**Test URL:** https://dfc8ght8abwqc.cloudfront.net/

**Expected Results:**
- Baseline production HTML loads normally
- NO video modules loaded (they should only load on `/video/` path)
- All existing functionality works
- No console errors

**❌ FAILURE CRITERIA:**
- Baseline production is broken
- Video modules load on root path (should be isolated to `/video/`)
- Any regression in baseline functionality

---

## 🔧 Troubleshooting

### If JS files return 403:

**Check S3 bucket:**
```powershell
aws s3 ls s3://YOUR-BUCKET-NAME/video/ --recursive
```

**Expected output:**
```
video/index.html
video/VideoCaptureModule.js
video/VideoStorageService.js
video/SignedURLGenerator.js
video/IntegrationOrchestrator.js
```

**Check Content-Type:**
```powershell
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/VideoCaptureModule.js
```

**Expected:** `"ContentType": "application/javascript"`

**If Content-Type is wrong:**
```powershell
# Re-upload with correct Content-Type
aws s3 cp Gemini3_AllSensesAI/video/release/rc1/VideoCaptureModule.js s3://YOUR-BUCKET-NAME/video/VideoCaptureModule.js --content-type "application/javascript" --cache-control "max-age=0, no-cache, no-store, must-revalidate"
```

---

### If CloudFront returns 403:

**Check CloudFront behavior:**
1. Go to AWS Console → CloudFront → Your Distribution
2. Check "Behaviors" tab
3. Verify there's a behavior for `/video/*` path pattern
4. Verify origin is set to S3 bucket
5. Verify OAI (Origin Access Identity) has read permissions

**Check S3 bucket policy:**
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity YOUR-OAI-ID"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/video/*"
}
```

---

### If SyntaxError persists:

**This means CloudFront is still serving cached 403 HTML as JavaScript.**

**Solution:**
1. Create CloudFront invalidation for `/video/*`
2. Wait 1-5 minutes for invalidation to complete
3. Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
4. Clear browser cache if needed

**Manual invalidation (if CLI fails):**
1. Go to AWS Console → CloudFront → Your Distribution
2. Click "Invalidations" tab
3. Click "Create Invalidation"
4. Enter paths:
   - `/video/index.html`
   - `/video/VideoCaptureModule.js`
   - `/video/VideoStorageService.js`
   - `/video/SignedURLGenerator.js`
   - `/video/IntegrationOrchestrator.js`
   - OR use wildcard: `/video/*`
5. Click "Create Invalidation"

---

## ✅ Success Criteria Summary

- [ ] All 4 JS modules load with 200 status
- [ ] All 4 JS modules have Content-Type: `application/javascript`
- [ ] No SyntaxError in console
- [ ] No ReferenceError for `completeStep1`
- [ ] Step 1 button works normally
- [ ] Baseline production URL unchanged and functional
- [ ] No regressions in existing functionality

---

## 📝 Verification Report Template

```
Date: _______________
Tester: _______________
CloudFront URL: https://dfc8ght8abwqc.cloudfront.net/video/index.html

Network Tab Results:
- VideoCaptureModule.js: [ ] 200 [ ] 403 [ ] Other: _____
- VideoStorageService.js: [ ] 200 [ ] 403 [ ] Other: _____
- SignedURLGenerator.js: [ ] 200 [ ] 403 [ ] Other: _____
- IntegrationOrchestrator.js: [ ] 200 [ ] 403 [ ] Other: _____

Console Results:
- SyntaxError: [ ] None [ ] Present
- ReferenceError: [ ] None [ ] Present
- Step 1 button: [ ] Works [ ] Broken

Baseline Production:
- Root URL: [ ] Works [ ] Broken
- No video modules: [ ] Confirmed [ ] Video modules loaded

Overall Status: [ ] PASS [ ] FAIL

Notes:
_________________________________________________________________
_________________________________________________________________
```

---

## 🚨 Rollback Procedure

If verification fails:

```powershell
.\rollback-production-sms-video.ps1 -BucketName YOUR-BUCKET-NAME -DistributionId YOUR-DISTRIBUTION-ID
```

This will remove the `/video/` path and restore baseline production state.
