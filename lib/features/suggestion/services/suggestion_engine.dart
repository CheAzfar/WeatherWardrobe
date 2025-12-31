import 'package:hive/hive.dart';
import '../../wardrobe/models/clothing_item.dart';
import '../models/outfit_suggestion.dart';

class SuggestionEngine {
  static OutfitSuggestion generate({
    required double temperature,
    required bool isRaining,
    required String context,
  }) {
    final box = Hive.box<ClothingItem>('wardrobeBox');
    final items = box.values.toList();

    String requiredWarmth;

    if (temperature >= 30) {
      requiredWarmth = 'Light';
    } else if (temperature >= 24) {
      requiredWarmth = 'Medium';
    } else {
      requiredWarmth = 'Heavy';
    }

    final selectedItems = <ClothingItem>[];
    final missingCategories = <String>[];

    // Required categories
    final requiredCategories = ['Tops', 'Bottoms', 'Shoes'];

    if (context == 'Office') {
      requiredCategories.add('Outerwear');
    }

    for (final category in requiredCategories) {
      final matches = items.where(
        (i) =>
            i.category == category &&
            i.warmthLevel == requiredWarmth,
      );

      if (matches.isNotEmpty) {
        selectedItems.add(matches.first);
      } else {
        missingCategories.add(category);
      }
    }

    if (isRaining && !requiredCategories.contains('Outerwear')) {
      final rainOuter = items.where(
        (i) => i.category == 'Outerwear',
      );
      if (rainOuter.isNotEmpty) {
        selectedItems.add(rainOuter.first);
      } else {
        missingCategories.add('Outerwear');
      }
    }

    return OutfitSuggestion(
      selectedItems: selectedItems,
      missingCategories: missingCategories,
      reason:
          'Based on ${temperature.toInt()}°C weather and $context context',
    );
  }
}
