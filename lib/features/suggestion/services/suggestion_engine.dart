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

    if (user == null) {
      return const OutfitSuggestion(
        recommendedByCategory: {},
        missingNeeds: [],
        selectedItems: [],
        missingCategories: [],
        reason: 'Please sign in.',
      );
    }

    final items = await _loadWardrobeItems(user.uid);

    // 1. Warmth Logic
    final baseWarmth = _baseWarmthFromTemp(temperature);
    final delta = _contextWarmthDelta(context);
    final desiredWarmth = _clampWarmth(baseWarmth + delta);
    final desiredLabel = _warmthLabel(desiredWarmth);

    // 2. Categories Needed
    final required = <String>['Tops', 'Bottoms', 'Shoes'];
    final wantsOuterwear = isRaining || _contextNeedsOuterwear(context) || desiredWarmth >= 2;
    if (wantsOuterwear) required.add('Outerwear');

    // 3. Filtering & Ranking
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
        // If empty (because no "Formal" item found), treat as Missing
        missingNeeds.add(MissingNeed(category: cat, warmthLevel: desiredLabel));
        missingCategories.add(cat);
      } else {
        selectedOnePerCategory.add(ranked.first);
      }
    }

    final ctxShort = context.trim().isEmpty ? 'Selected' : context;
    final rainText = isRaining ? 'Rain expected.' : 'Conditions clear.';

    return OutfitSuggestion(
      recommendedByCategory: recommendedByCategory,
      missingNeeds: missingNeeds,
      selectedItems: selectedOnePerCategory,
      missingCategories: missingCategories,
      reason: 'Context: $ctxShort (${temperature.toInt()}°C). Target: $desiredLabel. $rainText',
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

  // --- WARMTH HELPERS ---
  static int _baseWarmthFromTemp(double t) {
    if (t >= 28) return 0; // Light
    if (t >= 22) return 1; // Medium
    return 2;              // Heavy
  }

  static int _contextWarmthDelta(String context) {
    final c = context.toLowerCase();
    if (c.contains('office') || c.contains('client') || c.contains('meeting')) return 1; 
    if (c.contains('outdoor') || c.contains('active')) return -1;
    return 0;
  }

  static bool _contextNeedsOuterwear(String context) {
    final c = context.toLowerCase();
    return c.contains('office') || c.contains('client') || c.contains('meeting');
  }

  static int _clampWarmth(int w) => w < 0 ? 0 : (w > 2 ? 2 : w);
  static String _warmthLabel(int w) => w == 2 ? 'Heavy' : (w == 1 ? 'Medium' : 'Light');
  
  static int _parseWarmthScale(String warmth) {
    final w = warmth.trim().toLowerCase();
    if (w == 'heavy' || w == 'warm') return 2;
    if (w == 'medium') return 1;
    return 0;
  }

  // --- RANKING LOGIC ---

  static List<ClothingItem> _rankForCategory({
    required List<ClothingItem> items,
    required String category,
    required int desiredWarmth,
    required bool isRaining,
    required String context,
  }) {
    // 1. Basic Category Filter
    var candidates = items.where((i) => i.category == category).toList();
    if (candidates.isEmpty) return [];

    // 2. *** STRICT RULE FOR CLIENT MEETING ***
    // If context is "Client Meeting", item name MUST start with "Formal"
    final c = context.toLowerCase();
    if (c.contains('client') || c.contains('meeting')) {
      
      candidates = candidates.where((i) => 
        i.name.trim().toLowerCase().startsWith('formal')
      ).toList();

      // IF candidates IS NOW EMPTY, we simply return []
      // The main generate() function detects [] and adds a "MissingNeed"
      // This forces the "Find in Shop" UI to appear.
      if (candidates.isEmpty) return [];
    }

    // 3. Score & Sort (for other contexts or tie-breaking)
    candidates.sort((a, b) {
      final sa = _scoreItem(a, desiredWarmth, category, isRaining, context);
      final sb = _scoreItem(b, desiredWarmth, category, isRaining, context);
      if (sa != sb) return sa.compareTo(sb);
      
      // Tie-breaker: Newest items first
      final ad = a.createdAt ?? DateTime(1970);
      final bd = b.createdAt ?? DateTime(1970);
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
    int score = 0;
    final name = item.name.toLowerCase();
    final c = context.toLowerCase();
    final itemWarmth = _parseWarmthScale(item.warmthLevel);

    // Base Warmth Score
    score += (itemWarmth - desiredWarmth).abs() * 10;

    // Context Scoring (Lower is Better)
    
    // Office / AC
    if (c.contains('office') || c.contains('air-conditioned')) {
      if (name.contains('short') || name.contains('beach') || name.contains('flip')) score += 100;
      if (name.contains('blazer') || name.contains('cardigan')) score -= 20;
    }
    
    // Outdoor
    if (c.contains('outdoor') || c.contains('active')) {
      if (name.contains('suit') || name.contains('formal')) score += 100;
      if (name.contains('sport') || name.contains('active')) score -= 20;
    }

    // Rain
    if (isRaining) {
      if (category == 'Outerwear' && (name.contains('rain') || name.contains('waterproof'))) score -= 50;
      if (name.contains('suede') || name.contains('canvas')) score += 50;
    }

    return score;
  }
}