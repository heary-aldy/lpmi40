# 🔧 Firebase Update Guide for Song 029

## **Current Status:**
✅ **Local Asset Updated**: `assets/data/lpmi.json` has the converted URL  
❌ **Firebase Database**: Still needs to be updated with converted URL  

---

## **📍 What Needs to be Updated:**

**Firebase Path**: `song_collection/LPMI/songs/029/url`

**Current URL** (in Firebase):
```
https://drive.google.com/file/d/1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs/view?usp=drivesdk
```

**New URL** (needs to be set):
```
https://drive.google.com/uc?export=download&id=1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs
```

---

## **🚀 Option 1: Run the Update Script**

```bash
cd /Users/hearyhealdysairin/Documents/Flutter/lpmi40
dart run scripts/update_song_029_firebase.dart
```

This script will:
- Connect to your Firebase database
- Update song 029's URL to the converted format
- Verify the update was successful

---

## **🎯 Option 2: Update Through the App (Recommended)**

### **Using Add/Edit Song Page:**

1. **Open your app with admin access**
2. **Go to Song Management** (admin panel)
3. **Filter by LPMI Collection**
4. **Find and edit Song #029** ("Teguhlah Alasan")
5. **In the Audio URL field**, the current URL should be:
   ```
   https://drive.google.com/file/d/1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs/view?usp=drivesdk
   ```
6. **Replace it with the converted URL**:
   ```
   https://drive.google.com/uc?export=download&id=1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs
   ```
7. **Save the song** - this will update Firebase automatically

### **Using Auto-Conversion:**
1. **Clear the audio URL field**
2. **Paste the original Google Drive link**:
   ```
   https://drive.google.com/file/d/1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs/view?usp=drive_link
   ```
3. **Wait 500ms** - the app should auto-convert it
4. **Test audio** using the test button
5. **Save** - this updates Firebase with the converted URL

---

## **🔍 Option 3: Manual Firebase Console Update**

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. **Select your LPMI40 project**
3. **Navigate to**: Realtime Database → Data
4. **Find path**: `song_collection/LPMI/songs/029/url`
5. **Update the value** to: `https://drive.google.com/uc?export=download&id=1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs`
6. **Save changes**

---

## **✅ Verification Steps:**

After updating Firebase:

1. **Restart your app** (to clear any cached data)
2. **Navigate to LPMI Collection**
3. **Find Song #029** ("Teguhlah Alasan")
4. **Check for audio indicators** (🎵 icon)
5. **Test audio playback** (if you have premium/admin access)
6. **Verify download functionality** (premium users)

---

## **🎯 Why Both Need Updating:**

| Location | Purpose | Current Status |
|----------|---------|----------------|
| **Local Asset** (`lpmi.json`) | Offline fallback, initial app load | ✅ **Updated** |
| **Firebase Database** | Live data source for online users | ❌ **Needs Update** |

**For complete functionality**: Both locations should have the converted URL format.

---

## **📱 Expected Result:**

After updating both:
- ✅ Song #029 will have audio functionality
- ✅ Google Drive link will work properly with the audio player
- ✅ Premium/admin users can play and download the audio
- ✅ Regular users will see premium upgrade prompts for audio features

---

**Recommendation**: Use **Option 2** (app's Add/Edit Song page) as it's the safest and tests the conversion logic at the same time!
