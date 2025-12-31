import 'package:hive/hive.dart';

part 'clothing_item.g.dart';

@HiveType(typeId: 1)
class ClothingItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  String warmthLevel;

  @HiveField(3)
  String? imagePath;

  ClothingItem({
    required this.name,
    required this.category,
    required this.warmthLevel,
    this.imagePath,
  });
}
