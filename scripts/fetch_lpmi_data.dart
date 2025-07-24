import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final database = FirebaseDatabase.instance;

  try {
    // Fetch LPMI collection data from the correct Firebase path
    print('Fetching LPMI data from Firebase...');
    final lpmiRef = database.ref('song_collection/LPMI/songs');
    final snapshot = await lpmiRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      print(
          'No data found at song_collection/LPMI/songs, trying root LPMI path...');
      final fallbackRef = database.ref('LPMI');
      final fallbackSnapshot = await fallbackRef.get();

      if (fallbackSnapshot.exists && fallbackSnapshot.value != null) {
        final data = fallbackSnapshot.value;
        print('LPMI data found at root level');
        await _processAndSaveData(data);
      } else {
        print('No LPMI data found at either path');
      }
    } else {
      final data = snapshot.value;
      await _processAndSaveData(data);
    }
  } catch (e) {
    print('Error fetching LPMI data: $e');
  }

  exit(0);
}

Future<void> _processAndSaveData(dynamic data) async {
  print('LPMI data fetched successfully');
  print('Data structure: ${data.runtimeType}');

  // Convert to proper array format if needed
  List<dynamic> songsArray = [];

  if (data is Map) {
    print('Number of songs in map: ${data.length}');
    // Convert map to array format
    data.forEach((key, value) {
      if (value is Map) {
        songsArray.add(value);
      }
    });
  } else if (data is List) {
    print('Number of songs in list: ${data.length}');
    songsArray = data;
  }

  // Convert to JSON and save to file
  final jsonString = JsonEncoder.withIndent('    ').convert(songsArray);
  final file = File('assets/data/lpmi.json');
  await file.writeAsString(jsonString);

  print('LPMI data saved to assets/data/lpmi.json');
  print('Final array length: ${songsArray.length}');
}
