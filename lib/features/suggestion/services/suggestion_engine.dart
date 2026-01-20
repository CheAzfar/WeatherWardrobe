import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../wardrobe/models/clothing_item.dart';
import '../models/outfit_suggestion.dart';

class SuggestionEngine {
  static Future<OutfitSuggestion> generate({
    required double temperature,
    required bool isRaining,
    required String context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    // If user not signed in
    if (user == null) {
      return const OutfitSuggestion(
        recommendedByCategory: {},
        missingNeeds: [
          MissingNeed(category: 'Tops', warmthLevel: 'Medium'),
          MissingNeed(category: 'Bottoms', warmthLevel: 'Medium'),
          MissingNeed(category: 'Shoes', warmthLevel: 'Medium'),
        ],
        selectedItems: [],
        missingCategories: ['Tops', 'Bottoms', 'Shoes'],
        reason: 'Please sign in to generate outfit suggestions.',
      );
    }

    final items = await _loadWardrobeItems(user.uid);

    // Warmth target
    final baseWarmth = _baseWarmthFromTemp(temperature);      // 0..2
    final delta = _contextWarmthDelta(context);               // -1..+1
    final desiredWarmth = _clampWarmth(baseWarmth + delta);   // 0..2
    final desiredLabel = _warmthLabel(desiredWarmth);

    // Required categories
    final required = <String>['Tops', 'Bottoms', 'Shoes'];
    final wantsOuterwear =
        isRaining || _contextNeedsOuterwear(context) || desiredWarmth >= 2;
    if (wantsOuterwear) required.add('Outerwear');

    // Build candidates map
    final Map<String, List<ClothingItem>> recommendedByCategory = {};
    final List<MissingNeed> missingNeeds = [];
    final List<String> missingCategories = [];
    final List<ClothingItem> selectedOnePerCategory = [];

    for (final cat in required) {
      final ranked = _rankForCategory(
        items: items,
        category: cat,
        desiredWarmth: desiredWarmth,
        isRaining: isRaining,
        context: context,
      );

      recommendedByCategory[cat] = ranked;

      if (ranked.isEmpty) {
        missingNeeds.add(MissingNeed(category: cat, warmthLevel: desiredLabel));
        missingCategories.add(cat);
      } else {
        // default pick = best first item
        selectedOnePerCategory.add(ranked.first);
      }
    }

    final ctxShort = context.trim().isEmpty ? 'selected' : context;
    final rainText =
        isRaining ? 'Rain expected—outerwear is recommended.' : 'No rain expected.';

    return OutfitSuggestion(
      recommendedByCategory: recommendedByCategory,
      missingNeeds: missingNeeds,
      selectedItems: selectedOnePerCategory,
      missingCategories: missingCategories,
      reason:
          'Based on ${temperature.toInt()}°C (${_tempBandText(temperature)}), context: $ctxShort. '
          'Target warmth: $desiredLabel. $rainText',
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

  // Warmth scale: 0 Light, 1 Medium, 2 Heavy
  static int _baseWarmthFromTemp(double t) {
    if (t >= 30) return 0;
    if (t >= 24) return 1;
    return 2;
  }

  static int _contextWarmthDelta(String context) {
    final c = context.toLowerCase();
    if (c.contains('air-conditioned') || c.contains('air conditioned') || c.contains('office')) return 1;
    if (c.contains('client')) return 1;
    if (c.contains('outdoor')) return -1;
    if (c.contains('casual')) return -1;
    return 0;
  }

  static bool _contextNeedsOuterwear(String context) {
    final c = context.toLowerCase();
    return c.contains('air-conditioned') ||
        c.contains('air conditioned') ||
        c.contains('office') ||
        c.contains('client');
  }

  static int _clampWarmth(int w) => w < 0 ? 0 : (w > 2 ? 2 : w);

  static String _warmthLabel(int w) => w == 2 ? 'Heavy' : (w == 1 ? 'Medium' : 'Light');

  static int _parseWarmthScale(String warmth) {
    final w = warmth.trim().toLowerCase();
    if (w == 'heavy') return 2;
    if (w == 'warm') return 2; // backward compatibility
    if (w == 'medium') return 1;
    return 0;
  }

  static String _tempBandText(double t) {
    if (t >= 30) return 'hot';
    if (t >= 24) return 'warm';
    return 'cool';
  }

  static List<ClothingItem> _rankForCategory({
    required List<ClothingItem> items,
    required String category,
    required int desiredWarmth,
    required bool isRaining,
    required String context,
  }) {
    final candidates = items.where((i) => i.category == category).toList();
    if (candidates.isEmpty) return [];

    candidates.sort((a, b) {
      final sa = _scoreItem(a, desiredWarmth, category, isRaining, context);
      final sb = _scoreItem(b, desiredWarmth, category, isRaining, context);
      if (sa != sb) return sa.compareTo(sb);

      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return candidates;
  }

  static int _scoreItem(
    ClothingItem item,
    int desiredWarmth,
    String category,
    bool isRaining,
    String context,
  ) {
    final itemWarmth = _parseWarmthScale(item.warmthLevel);
    int score = (itemWarmth - desiredWarmth).abs();

    final c = context.toLowerCase();

    if (isRaining && category == 'Outerwear' && itemWarmth == 0) score += 2;
    if ((c.contains('outdoor') || c.contains('casual')) && itemWarmth == 2) score += 1;
    if ((c.contains('air-conditioned') || c.contains('air conditioned') || c.contains('client') || c.contains('office')) &&
        itemWarmth == 0) score += 1;

    return score;
  }
}
