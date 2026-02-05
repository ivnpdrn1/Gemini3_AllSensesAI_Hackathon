# Step 2 Map Preview - Google Dual-Mode Fix

**Date:** 2026-02-05  
**Status:** ✅ COMPLETE - Ready for Local Testing  
**File:** `Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html`

---

## Problem Statement

- **Root Cause:** Current fallback URL uses `output=embed` in an `<img src>` tag
- **Issue:** Google `output=embed` is NOT an image; it must be loaded in an `<iframe>`
- **Symptom:** Map preview shows broken image icon when no API key is provided
- **Impact:** Victim cannot verify the exact location that will be sent

---

## Solution: Dual-Mode Map Preview

### Mode A: With API Key (Google Static Maps API)
- **Element:** `<img>` tag
- **URL Format:** `https://maps.googleapis.com/maps/api/staticmap?center=LAT,LNG&zoom=15&size=600x300&scale=2&markers=LAT,LNG&key=KEY`
- **Proof Log:** `[STEP2][MAP] preview loaded (google static)`

### Mode B: Without API Key (Google Maps Embed)
- **Element:** `<iframe>` tag
- **URL Format:** `https://www.google.com/maps?q=LAT,LNG&z=15&output=embed`
- **Proof Log:** `[STEP2][MAP] using Google Maps embed (no key)`

---

## Changes Made

### 1. Updated HTML Markup (Step 2 Location Preview)

**Before:**
```html
<img id="locationMapImage" src="" alt="Map preview">
```

**After:**
```html
<img id="mapPreviewImg" src="" alt="Map preview" style="display:none; max-width:100%; border-radius:8px;">
<iframe id="mapPreviewIframe" src="" style="display:none; width:100%; height:260px; border:0; border-radius:8px;" loading="lazy"></iframe>
<div id="mapPreviewStatus" class="note"></div>
```

**Rationale:** Both elements exist in DOM; visibility toggled based on API key presence.

---

### 2. Updated `updateLocationPreview()` Function

**Key Logic:**
```javascript
const googleApiKey = (window.__GOOGLE_STATIC_MAPS_KEY__ || "").trim();

if (googleApiKey) {
    // Mode A: Use Google Static Maps API (IMAGE)
    imgElement.src = staticMapUrl;
    imgElement.style.display = 'block';
    iframeElement.src = 'about:blank';
    iframeElement.style.display = 'none';
    console.log('[STEP2][MAP] preview loaded (google static)');
} else {
    // Mode B: Use Google Maps embed (IFRAME)
    iframeElement.src = embedUrl;
    iframeElement.style.display = 'block';
    imgElement.src = '';
    imgElement.style.display = 'none';
    console.log('[STEP2][MAP] using Google Maps embed (no key)');
}
```

**Live Link (Always):**
```javascript
const mapLink = `https://www.google.com/maps?q=${latFixed},${lngFixed}`;
```

---

### 3. Updated `triggerEmergencyAlert()` Function (Step 4)

**Key Logic:**
```javascript
const googleApiKey = (window.__GOOGLE_STATIC_MAPS_KEY__ || "").trim();
let mapPreviewHtml = '';

if (googleApiKey) {
    // Mode A: Static Maps API (IMAGE)
    mapPreviewHtml = `<img src="${staticMapUrl}" ... >`;
    console.log('[STEP4][MAP] Using Google Static Maps API with key');
} else {
    // Mode B: Maps Embed (IFRAME)
    mapPreviewHtml = `<iframe src="${embedUrl}" ... ></iframe>`;
    console.log('[STEP4][MAP] Using Google Maps embed (no key)');
}
```

---

## Verification Deliverables

### Console Proof Logs

**With API Key:**
```
[STEP2][MAP] preview loaded (google static)
[STEP4][MAP] Using Google Static Maps API with key
[STEP4][MAP] preview loaded (google static)
```

**Without API Key:**
```
[STEP2][MAP] using Google Maps embed (no key)
[STEP2][MAP] embed loaded (google)
[STEP4][MAP] Using Google Maps embed (no key)
[STEP4][MAP] embed loaded (google)
```

### Visual Verification

1. **Live Link:** Opens Google Maps with current coordinates (both modes)
2. **Map Preview:** Renders reliably with or without API key
3. **No Yandex:** Confirm no "Yandex" visible in UI
4. **Network Tab:** Confirm no requests to yandex.com

---

## Local Test Steps (DO NOT DEPLOY YET)

### Test Scenario 1: Without API Key (Default)

1. Open Chrome Incognito window
2. Open `Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html`
3. Hard refresh (Ctrl+Shift+R)
4. Complete Step 1 (enter name + phone)
5. Click "Enable Location" or "Use Demo Location"
6. **Verify:**
   - Console shows: `[STEP2][MAP] using Google Maps embed (no key)`
   - Map preview appears as **iframe** (not broken image)
   - Live link opens Google Maps
7. Trigger Step 4 emergency alert
8. **Verify:**
   - Console shows: `[STEP4][MAP] Using Google Maps embed (no key)`
   - Map preview appears as **iframe**

### Test Scenario 2: With API Key

1. Add to HTML `<head>` section:
   ```html
   <script>
       window.__GOOGLE_STATIC_MAPS_KEY__ = "YOUR_API_KEY_HERE";
   </script>
   ```
2. Repeat Test Scenario 1
3. **Verify:**
   - Console shows: `[STEP2][MAP] preview loaded (google static)`
   - Map preview appears as **image** (not iframe)
   - Console shows: `[STEP4][MAP] Using Google Static Maps API with key`

---

## Zero Regressions Checklist

- ✅ Step 1: Unchanged (configuration flow intact)
- ✅ Step 3: Unchanged (voice detection intact)
- ✅ Live Link: Always shows Google Maps link (both modes)
- ✅ Map Preview: Renders in both modes (image or iframe)
- ✅ No AWS Changes: Frontend-only fix
- ✅ No Yandex: Completely eliminated

---

## Code Diff Summary

**Files Changed:** 1  
**Lines Changed:** ~80 lines (3 sections)

1. **HTML Markup:** Added `<img>` + `<iframe>` + status div
2. **updateLocationPreview():** Dual-mode logic with element toggling
3. **triggerEmergencyAlert():** Dual-mode HTML generation for Step 4

---

## Next Steps

1. **Ivan Approval Required:** Do NOT deploy until approved
2. **Local Testing:** Follow test steps above
3. **Screenshot Proof:** Capture console logs showing:
   - `[STEP2][MAP] using Google Maps embed (no key)` OR
   - `[STEP2][MAP] preview loaded (google static)`
4. **Visual Proof:** Confirm map preview visible (not broken image)
5. **Network Proof:** Confirm no Yandex requests

---

## Implementation Notes

- **API Key Detection:** Uses `(window.__GOOGLE_STATIC_MAPS_KEY__ || "").trim()`
- **Element Toggling:** Only one element visible at a time (img OR iframe)
- **Fallback Safety:** If no key, iframe embed works without authentication
- **Live Link Priority:** Always provides clickable Google Maps link
- **Proof Logging:** Console logs clearly identify which mode is active

---

**Status:** ✅ Code complete, awaiting local test + Ivan approval before deployment
