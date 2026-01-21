import '../../wardrobe/models/clothing_item.dart';

class MissingNeed {
  final String category;     // e.g. "Tops"
  final String warmthLevel;  // "Light" | "Medium" | "Heavy"
  const MissingNeed({
    required this.category,
    required this.warmthLevel,
  });
}

class OutfitSuggestion {
  /// Candidate items per category (ranked best-first).
  /// UI will pick only ONE per category, but can cycle on refresh.
  final Map<String, List<ClothingItem>> recommendedByCategory;

  /// Missing requirement(s) including the warmth we wanted.
  final List<MissingNeed> missingNeeds;

  /// Backward compatibility if other screens still use these:
  final List<ClothingItem> selectedItems;
  final List<String> missingCategories;

  final String reason;

  const OutfitSuggestion({
    required this.recommendedByCategory,
    required this.missingNeeds,
    required this.selectedItems,
    required this.missingCategories,
    required this.reason,
  });
}
