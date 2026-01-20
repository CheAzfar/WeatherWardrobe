import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'add_item_screen.dart';

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

  Query<Map<String, dynamic>> q = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('wardrobe_items');

  // If "All", we can order directly (no composite index needed)
  if (selectedCategory == 'All') {
    q = q.orderBy('createdAt', descending: true);
  } else {
    // If filtered by category, DO NOT orderBy to avoid composite index
    q = q.where('category', isEqualTo: selectedCategory);
  }

  return q.snapshots();
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

                    final docs = (snap.data?.docs ?? []).toList();
                    
                    if (selectedCategory != 'All') {
                      // Sort locally by createdAt descending (handles null safely)
                      docs.sort((a, b) {
                        final at = a.data()['createdAt'];
                        final bt = b.data()['createdAt'];

                        final aTime = (at is Timestamp) ? at.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                        final bTime = (bt is Timestamp) ? bt.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

                        return bTime.compareTo(aTime);
                      });
                    }

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
                        final d = docs[i].data();

                        final name = (d['name'] ?? '').toString();
                        final category = (d['category'] ?? '').toString();
                        final warmth = (d['warmthLevel'] ?? '').toString();
                        final imageUrl = (d['imageUrl'] ?? '').toString();

                        // Optional labels (works with your order-writing later)
                        final source = (d['source'] ?? '').toString(); // 'purchase' or 'manual'

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
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
                                            color: Colors.black.withValues(alpha: 0.55),
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

  Widget _itemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        color: AppColors.softGreen.withValues(alpha: 0.6),
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
        color: AppColors.softGreen.withValues(alpha: 0.6),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.primaryGreen),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: double.infinity,
          color: AppColors.softGreen.withValues(alpha: 0.35),
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
            AppColors.primaryGreen.withValues(alpha: 0.95),
            AppColors.primaryGreen.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
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
                  'Purchased items appear here automatically',
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
        'No items yet.\nBuy from Shop and it will appear here.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
