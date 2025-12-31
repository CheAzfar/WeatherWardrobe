import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../models/clothing_item.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late Box<ClothingItem> wardrobeBox;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
  ];

  @override
  void initState() {
    super.initState();
    wardrobeBox = Hive.box<ClothingItem>('wardrobeBox');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroHeader(context),
            const SizedBox(height: 14),
            _categoryChips(),
            const SizedBox(height: 14),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: wardrobeBox.listenable(),
                builder: (context, Box<ClothingItem> box, _) {
                  final entries = box.toMap().entries.toList();

                  final filtered = selectedCategory == 'All'
                      ? entries
                      : entries
                          .where((e) => e.value.category == selectedCategory)
                          .toList();

                  if (filtered.isEmpty) return _emptyStateFill();

                  return _wardrobeGrid(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withOpacity(0.95),
            AppColors.primaryGreen.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checkroom_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Wardrobe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Organize your outfits by category',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primaryGreen : Colors.black87,
              ),
            ),
            selected: selected,
            selectedColor: AppColors.softGreen,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            onSelected: (_) => setState(() => selectedCategory = category),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Widget _wardrobeGrid(List<MapEntry<dynamic, ClothingItem>> entries) {
    return GridView.builder(
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final key = entry.key;
        final item = entry.value;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openItemDetails(key, item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: (item.imagePath == null || item.imagePath!.isEmpty)
                        ? Container(
                            color: AppColors.softGreen.withOpacity(0.6),
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 40, color: AppColors.primaryGreen),
                            ),
                          )
                        : Image.file(
                            File(item.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.category} • ${item.warmthLevel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyStateFill() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.06),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.checkroom_outlined, size: 54, color: AppColors.primaryGreen),
                SizedBox(height: 12),
                Text(
                  'No items in this category',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Try selecting another category or add a new clothing item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------- Bottom sheet (taller + bigger image) --------

  void _openItemDetails(dynamic key, ClothingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.90, // ✅ taller
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.checkroom_outlined, color: AppColors.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ✅ BIG image area
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.softGreen.withOpacity(0.6),
                      child: (item.imagePath == null || item.imagePath!.isEmpty)
                          ? const Center(
                              child: Icon(Icons.image_outlined, size: 52, color: AppColors.primaryGreen),
                            )
                          : InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.contain, // ✅ see full picture
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _detailRow('Category', item.category),
                _detailRow('Warmth', item.warmthLevel),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditItemScreen(itemKey: key, item: item),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await _confirmDelete(item.name);
                          if (confirmed != true) return;

                          await wardrobeBox.delete(key);

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item deleted')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Delete "$name" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
