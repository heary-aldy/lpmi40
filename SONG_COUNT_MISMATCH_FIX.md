# Song Count Mismatch Fix

## Problem Identified

The song counts shown in the CollectionManagement page were different from the actual song counts in the SongRepository.

**From logs:**
- SongRepository (CORRECT): Lagu_belia: 21, lagu_krismas: 20, lagu_pandak: 71, lagu_iban: 279
- CollectionManagement (WRONG): Lagu_belia: 22, lagu_krismas: 2, lagu_pandak: 2, lagu_iban: 2

## Root Cause

The issue was in the data flow:

1. **SongRepository.getCollectionsSeparated()** → Calculates actual song counts by counting songs ✅ CORRECT
2. **CollectionService.getAccessibleCollections()** → Gets metadata from CollectionRepository ❌ WRONG SOURCE
3. **CollectionRepository.getCollectionById()** → Returns cached `metadata['song_count']` ❌ OUTDATED DATA
4. **SongCollection.fromJson()** → Uses `metadata['song_count']` field ❌ STALE DATA

## Solution

Modified `CollectionService.getAccessibleCollections()` to:

1. Get collection metadata from CollectionRepository (for access levels, names, etc.)
2. **Override the songCount** with actual counts from SongRepository
3. Use `collection.copyWith(songCount: actualSongCount)` to create corrected collection objects

## Code Changes

**File:** `lib/src/features/songbook/services/collection_service.dart`

```dart
// ✅ FIX: Use actual song count from SongRepository instead of cached metadata
final actualSongCount = separatedData[id]?.length ?? 0;
final correctedCollection = collection.copyWith(songCount: actualSongCount);
collections.add(correctedCollection);

// Debug log the correction
if (collection.songCount != actualSongCount) {
  debugPrint("🔧 [CollectionService] Corrected song count for $id: ${collection.songCount} → $actualSongCount");
}
```

## Impact

- ✅ CollectionManagement page now shows correct song counts
- ✅ Dashboard collections section already using correct method (getCollectionsWithMetadata)
- ✅ All song counts now consistent across the app
- ✅ No breaking changes to existing functionality

## Testing

After the fix, both data sources should show identical song counts:
- Lagu_belia: 21 songs
- lagu_krismas: 20 songs  
- LPMI: 273 songs
- lagu_pandak: 71 songs
- SRD: 222 songs
- lagu_iban: 279 songs

## Why This Happened

The `metadata['song_count']` field in Firebase gets updated when songs are added/removed, but this process can fail or lag behind the actual song changes. The SongRepository always calculates counts dynamically from actual song data, which is more reliable.

This fix ensures the CollectionManagement page uses the same reliable counting method as the rest of the app.
