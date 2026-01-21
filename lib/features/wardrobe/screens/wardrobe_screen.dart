import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart'; 

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String selectedCategory = 'All';

  final categories = const ['All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes'];

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // FIX 1: REMOVED .orderBy() here to prevent the Index Error
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wardrobe_items');

    if (selectedCategory != 'All') {
      q = q.where('category', isEqualTo: selectedCategory);
    }

    return q.snapshots();
  }

  // Delete Logic
  Future<void> _deleteItem(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wardrobe_items')
          .doc(docId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 14),
              _chips(),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    // FIX 2: Manually Sort the list here (Newest First)
                    // We copy the list using List.of() so we can sort it safely
                    final docs = List.of(snap.data?.docs ?? []);
                    
                    docs.sort((a, b) {
                      final d1 = a.data();
                      final d2 = b.data();
                      // Safely get dates, defaulting to old date if null
                      final t1 = (d1['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      final t2 = (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      // Sort Descending (Newest first)
                      return t2.compareTo(t1); 
                    });

                    if (docs.isEmpty) return _empty();

                    return GridView.builder(
                      itemCount: docs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, i) {
                        final doc = docs[i]; // Use our sorted list
                        final d = doc.data();

                        final name = (d['name'] ?? '').toString();
                        final category = (d['category'] ?? '').toString();
                        final warmth = (d['warmthLevel'] ?? '').toString();
                        final imageUrl = (d['imageUrl'] ?? '').toString();
                        final source = (d['source'] ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditItemScreen(
                                  docId: doc.id,
                                  initialName: name,
                                  initialCategory: category,
                                  initialWarmth: warmth,
                                  initialImageUrl: imageUrl,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(18),
                                        ),
                                        child: _itemImage(imageUrl),
                                      ),
                                      
                                      if (source == 'purchase')
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.55),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Purchased',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),

                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: InkWell(
                                          onTap: () => _deleteItem(doc.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                )
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$category • $warmth',
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Keep existing helpers: _itemImage, _header, _chips, _empty) ...
  // Or copy them from below if you want the complete file:

  Widget _itemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        color: AppColors.softGreen.withOpacity(0.6),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 40, color: AppColors.primaryGreen),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        color: AppColors.softGreen.withOpacity(0.6),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.primaryGreen),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: double.infinity,
          color: AppColors.softGreen.withOpacity(0.35),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _header() {
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap an item to edit, or tap the trash icon to delete.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c == selectedCategory;

          return ChoiceChip(
            label: Text(
              c,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primaryGreen : Colors.black87,
              ),
            ),
            selected: selected,
            selectedColor: AppColors.softGreen,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            onSelected: (_) => setState(() => selectedCategory = c),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text(
        'No items yet.\nAdd items or buy from Shop.',
        textAlign: TextAlign.center,
      ),
    );
  }
}