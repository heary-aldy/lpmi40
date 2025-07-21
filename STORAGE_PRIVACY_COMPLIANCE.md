# LPMI.40 - Privacy-Friendly Storage Implementation

## Storage Permissions Justification

### Why MANAGE_EXTERNAL_STORAGE is NOT Required

Our Christian hymnal app (LPMI.40) has **removed** the `MANAGE_EXTERNAL_STORAGE` permission and implemented privacy-friendly storage practices:

### ✅ **What We Use Instead:**

1. **App-Specific Directories** (No permissions required on Android 11+)
   - Audio files: `/storage/emulated/0/Android/data/com.haweeinc.lpmi40/files/Audio/`
   - Profile images: App's internal storage via `PhotoPickerService` (Android Photo Picker)
   - Announcement images: App's internal storage via `PhotoPickerService` (Android Photo Picker)

2. **Scoped Storage Permissions** (Minimal and targeted)
   - `READ_MEDIA_AUDIO` (Android 13+ only for media access)
   - `WRITE_EXTERNAL_STORAGE` (Android 10 and below only, maxSdkVersion="29")

3. **Privacy-Friendly Alternatives Used:**
   - **Audio Downloads**: Uses `getExternalStorageDirectory()` for app-specific directories
   - **Profile Images**: Uses `PhotoPickerService` with Android Photo Picker (no permissions required)
   - **Announcement Images**: Uses `PhotoPickerService` with Android Photo Picker (no permissions required)
   - **File Management**: Uses `path_provider` for app sandbox directories

### 🛡️ **Privacy Benefits:**

- **No broad file access**: App cannot access other apps' files or user documents
- **Automatic cleanup**: Files removed when app is uninstalled
- **User privacy**: No access to user's personal files or media
- **Google Play Policy Compliant**: Uses recommended storage practices

### 📱 **Functionality Maintained:**

- ✅ Premium users can download hymn audio for offline use
- ✅ Users can set profile pictures
- ✅ App data is properly stored and managed
- ✅ All features work without broad storage access

### 🔧 **Technical Implementation:**

```dart
// Privacy-friendly audio storage
final externalDir = await getExternalStorageDirectory(); // App-specific
final audioDir = Directory(path.join(externalDir.path, 'Audio', 'LPMI40'));

// Profile and announcement images via PhotoPickerService (no permissions required)
final photoPickerService = PhotoPickerService();
final result = await photoPickerService.pickImage(imageQuality: 50);
if (result.isSuccess && result.path != null) {
  // Use result.path for the selected image
}
```

**Result**: Full functionality with maximum user privacy protection.
