import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CityStore {
  // Default if user not logged in or no setting saved yet
  static const String defaultCity = 'Kuala Lumpur';

  // Firestore location:
  // users/{uid}/settings/preferences  -> { city: "Melaka" }
  static const String _settingsSubcol = 'settings';
  static const String _settingsDoc = 'preferences';
  static const String _keyCity = 'city';

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // Local in-memory cache so getCity() can stay synchronous
  static String _cachedCity = defaultCity;

  /// Keeps old signature so existing code compiles.
  /// Returns cached value (default if not fetched yet).
  static String getCity() => _cachedCity;

  /// Call this once after login, or when the app starts,
  /// to load saved city from Firestore into the cache.
  static Future<String> fetchCity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _cachedCity = defaultCity;
      return _cachedCity;
    }

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection(_settingsSubcol)
        .doc(_settingsDoc)
        .get();

    final data = doc.data();
    final city = (data?[_keyCity] as String?)?.trim();

    _cachedCity = (city == null || city.isEmpty) ? defaultCity : city;
    return _cachedCity;
  }

  /// Recommended for UI: real-time updates from Firestore.
  static Stream<String> cityStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(_cachedCity);

    return _db
        .collection('users')
        .doc(uid)
        .collection(_settingsSubcol)
        .doc(_settingsDoc)
        .snapshots()
        .map((snap) {
      final city = (snap.data()?[_keyCity] as String?)?.trim();
      _cachedCity = (city == null || city.isEmpty) ? defaultCity : city;
      return _cachedCity;
    });
  }

  /// Firestore write (Hive removed)
  static Future<void> setCity(String city) async {
    final uid = _auth.currentUser?.uid;
    final cleaned = city.trim();

    _cachedCity = cleaned.isEmpty ? defaultCity : cleaned;

    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection(_settingsSubcol)
        .doc(_settingsDoc)
        .set({_keyCity: _cachedCity}, SetOptions(merge: true));
  }
}
