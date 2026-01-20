import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../wardrobe/models/clothing_item.dart';
import '../models/outfit_suggestion.dart';

class SuggestionEngine {
  /// Firestore-based generator (Hive removed).
  ///
  /// Reads wardrobe from:
  /// users/{uid}/wardrobe_items
  static Future<OutfitSuggestion> generate({
    required double temperature,
    required bool isRaining,
    required String context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return OutfitSuggestion(
        selectedItems: const <ClothingItem>[],
        missingCategories: const <String>['Tops', 'Bottoms', 'Shoes'],
        reason: 'Please sign in to generate outfit suggestions.',
      );
    }

    final items = await _loadWardrobeItems(user.uid);

    final requiredWarmth = _requiredWarmthFromTemp(temperature);

    final selectedItems = <ClothingItem>[];
    final missingCategories = <String>[];

    // Base required categories
    final requiredCategories = <String>['Tops', 'Bottoms', 'Shoes'];

    if (context == 'Office') {
      requiredCategories.add('Outerwear');
    }

    // Pick 1 item per required category
    for (final category in requiredCategories) {
      final matches = items.where((i) {
        if (i.category != category) return false;

        // Match warmth (also tolerate old values like "Heavy" vs "Warm")
        final itemWarmth = _normalizeWarmth(i.warmthLevel);
        final needWarmth = _normalizeWarmth(requiredWarmth);
        return itemWarmth == needWarmth;
      }).toList();

      if (matches.isNotEmpty) {
        selectedItems.add(matches.first);
      } else {
        missingCategories.add(category);
      }
    }

    // If raining and Outerwear not already required, try to add it.
    if (isRaining && !requiredCategories.contains('Outerwear')) {
      final rainOuter = items.where((i) => i.category == 'Outerwear').toList();
      if (rainOuter.isNotEmpty) {
        selectedItems.add(rainOuter.first);
      } else {
        missingCategories.add('Outerwear');
      }
    }

    return OutfitSuggestion(
      selectedItems: selectedItems,
      missingCategories: missingCategories,
      reason: 'Based on ${temperature.toInt()}°C weather and $context context',
    );
  }

  static Future<List<ClothingItem>> _loadWardrobeItems(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wardrobe_items')
        .get();

    return snap.docs.map((d) => ClothingItem.fromDoc(d)).toList();
  }

  static String _requiredWarmthFromTemp(double temperature) {
    // Keep your original thresholds
    if (temperature >= 30) return 'Light';
    if (temperature >= 24) return 'Medium';
    return 'Heavy';
  }

  static String _normalizeWarmth(String warmth) {
    final w = warmth.trim().toLowerCase();
    if (w == 'heavy') return 'warm';   // tolerate old label
    if (w == 'warm') return 'warm';
    if (w == 'medium') return 'medium';
    return 'light';
  }
}
