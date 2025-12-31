import '../../wardrobe/models/clothing_item.dart';

class OutfitSuggestion {
  final List<ClothingItem> selectedItems;
  final List<String> missingCategories;
  final String reason;

  OutfitSuggestion({
    required this.selectedItems,
    required this.missingCategories,
    required this.reason,
  });
}
