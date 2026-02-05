# Console Proof Reference - Step 2 Map Preview Fix

**Purpose:** Quick reference for expected console logs during testing

---

## 🎯 Mode A: Without API Key (Default)

### Step 2: Enable Location / Use Demo Location

**Expected Console Logs:**
```
[STEP2][MAP] using Google Maps embed (no key)
[STEP2][MAP] embed loaded (google)
[STEP2] Location preview updated: Demo Location 47.606200, -122.332100
```

**Visual Verification:**
- Map preview shows **iframe** (not broken image)
- Live link opens Google Maps
- Coordinates displayed correctly

---

### Step 4: Trigger Emergency Alert

**Expected Console Logs:**
```
[STEP4][MAP] Using Google Maps embed (no key)
[STEP4][MAP] embed loaded (google)
```

**Visual Verification:**
- Emergency alert shows **iframe** map preview
- Live link opens Google Maps
- All emergency data displayed correctly

---

## 🎯 Mode B: With API Key

### Step 2: Enable Location / Use Demo Location

**Expected Console Logs:**
```
[STEP2][MAP] preview loaded (google static)
[STEP2][MAP] preview loaded (google static)
[STEP2] Location preview updated: Demo Location 47.606200, -122.332100
```

**Visual Verification:**
- Map preview shows **image** (not iframe)
- Live link opens Google Maps
- Coordinates displayed correctly

---

### Step 4: Trigger Emergency Alert

**Expected Console Logs:**
```
[STEP4][MAP] Using Google Static Maps API with key
[STEP4][MAP] preview loaded (google static)
```

**Visual Verification:**
- Emergency alert shows **image** map preview
- Live link opens Google Maps
- All emergency data displayed correctly

---

## 🚫 What You Should NOT See

### Yandex References
```
❌ yandex.com
❌ yandex.ru
❌ api-maps.yandex
```

### Broken Image Errors
```
❌ [STEP2][MAP] preview failed
❌ Failed to load resource: net::ERR_FAILED
❌ 404 Not Found
```

### Old Console Logs
```
❌ [STEP2][MAP] Using Google Static Maps API with key (when no key provided)
❌ [STEP2][MAP] Using Google Maps embed (no key) (when key provided)
```

---

## 🔍 Network Tab Verification

### Filter: "yandex"
**Expected:** Zero results

### Filter: "google"
**Expected (Mode A - No Key):**
```
✅ https://www.google.com/maps?q=47.606200,-122.332100&z=15&output=embed
```

**Expected (Mode B - With Key):**
```
✅ https://maps.googleapis.com/maps/api/staticmap?center=47.606200,-122.332100&zoom=15&size=600x300&scale=2&markers=47.606200,-122.332100&key=YOUR_KEY
```

---

## 📸 Screenshot Checklist

### Screenshot 1: Console Logs (Step 2)
- [ ] Shows `[STEP2][MAP] using Google Maps embed (no key)` OR
- [ ] Shows `[STEP2][MAP] preview loaded (google static)`
- [ ] Shows `[STEP2][MAP] embed loaded (google)` OR
- [ ] Shows `[STEP2][MAP] preview loaded (google static)`

### Screenshot 2: Map Preview (Step 2)
- [ ] Map preview visible (not broken image)
- [ ] Live link visible and clickable
- [ ] Coordinates displayed correctly

### Screenshot 3: Console Logs (Step 4)
- [ ] Shows `[STEP4][MAP] Using Google Maps embed (no key)` OR
- [ ] Shows `[STEP4][MAP] Using Google Static Maps API with key`
- [ ] Shows `[STEP4][MAP] embed loaded (google)` OR
- [ ] Shows `[STEP4][MAP] preview loaded (google static)`

### Screenshot 4: Emergency Alert (Step 4)
- [ ] Map preview visible in alert
- [ ] Live link visible and clickable
- [ ] All emergency data displayed

### Screenshot 5: Network Tab
- [ ] Filter: "yandex" → Zero results
- [ ] Filter: "google" → Shows Google Maps requests

---

## 🎯 Quick Test Commands

### Open DevTools Console
```
F12 (Windows/Linux)
Cmd+Option+I (Mac)
```

### Filter Console Logs
```
Filter: [STEP2][MAP]
Filter: [STEP4][MAP]
```

### Clear Console
```
Ctrl+L (Windows/Linux)
Cmd+K (Mac)
```

### Hard Refresh
```
Ctrl+Shift+R (Windows/Linux)
Cmd+Shift+R (Mac)
```

---

## ✅ Success Criteria

**All of the following must be true:**

1. ✅ Console shows correct mode detection (with/without key)
2. ✅ Map preview visible (not broken image)
3. ✅ Live link opens Google Maps
4. ✅ No Yandex references in console or network
5. ✅ Step 1, 3 unchanged (zero regressions)

---

**Status:** Ready for testing - Use this reference to verify console logs
