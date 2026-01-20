import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/marketplace_listing.dart';
import '../services/cart_service.dart';
import 'create_listing_screen.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialWarmth;
  final String? initialQuery;
  final int initialTabIndex;

  const ShopScreen({
    super.key,
    this.initialCategory,
    this.initialWarmth,
    this.initialQuery,
    this.initialTabIndex = 0,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters
  String _selectedCategory = 'All';
  String _selectedWarmth = 'All';
  String _sort = 'Newest';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categoryOptions = const ['All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes'];
  final List<String> _warmthOptions = const ['All', 'Light', 'Medium', 'Heavy'];
  final List<String> _sortOptions = const ['Newest', 'Price: Low', 'Price: High'];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {}); // so FAB updates on tab change
    });

    _selectedCategory = widget.initialCategory?.trim().isNotEmpty == true ? widget.initialCategory!.trim() : 'All';
    _selectedWarmth = widget.initialWarmth?.trim().isNotEmpty == true ? _normalizeWarmth(widget.initialWarmth!.trim()) : 'All';
    if (widget.initialQuery?.trim().isNotEmpty == true) _searchCtrl.text = widget.initialQuery!.trim();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Firestore stream (Browse)
  Stream<QuerySnapshot<Map<String, dynamic>>> _browseStream() {
  return FirebaseFirestore.instance
      .collection('marketplace_listings')
      .orderBy('createdAt', descending: true)
      .snapshots();
}


  // My listings (avoid composite index by sorting locally)
  Stream<QuerySnapshot<Map<String, dynamic>>> _myListingsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('marketplace_listings')
        .where('isAvailable', isEqualTo: true)
        .where('sellerId', isEqualTo: uid)
        .snapshots();
  }

  String _normalizeWarmth(String v) {
    final lower = v.toLowerCase();
    if (lower == 'warm') return 'Heavy';
    if (lower == 'heavy') return 'Heavy';
    if (lower == 'medium') return 'Medium';
    if (lower == 'light') return 'Light';
    return v;
  }

  bool get _hasActiveFilters {
    return _selectedCategory != 'All' || _selectedWarmth != 'All' || _searchCtrl.text.trim().isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedWarmth = 'All';
      _sort = 'Newest';
      _searchCtrl.clear();
    });
  }

  List<MarketplaceListing> _applyFilters(List<MarketplaceListing> all) {
    final q = _searchCtrl.text.trim().toLowerCase();

    var filtered = all.where((p) {
      final catOk = _selectedCategory == 'All' || p.category == _selectedCategory;
      final warmOk = _selectedWarmth == 'All' || p.warmthLevel == _selectedWarmth;

      final searchOk = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.warmthLevel.toLowerCase().contains(q);

      return catOk && warmOk && searchOk;
    }).toList();

    if (_sort == 'Price: Low') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'Price: High') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _tabController.index == 1; // only on My Listings

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          // Cart icon + badge
          StreamBuilder(
            stream: CartService.streamCart(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateListingScreen()));
              },
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _browseTab(),
          _myListingsTab(),
        ],
      ),
    );
  }

  Widget _browseTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              _searchBar(),
              const SizedBox(height: 10),
              _filterRow(),
              if (_hasActiveFilters) ...[
                const SizedBox(height: 10),
                _activeFiltersBar(),
              ],
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _browseStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final docs = snap.data?.docs ?? [];
              final allDocs = docs.map((d) {
              final data = d.data();
              final isAvailable = data['isAvailable'];

              // Treat missing as available (backward compatible with old listings)
              final available = (isAvailable == null) ? true : (isAvailable == true);

              return available ? MarketplaceListing.fromDoc(d) : null;
            }).whereType<MarketplaceListing>().toList();

            final filtered = _applyFilters(allDocs);


              if (filtered.isEmpty) return _emptyState();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _listingCard(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _myListingsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _myListingsStream(),
      builder: (context, snap) {
        if (FirebaseAuth.instance.currentUser == null) {
          return const Center(child: Text('Please sign in to manage listings.'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final docs = snap.data?.docs ?? [];
        final list = docs.map(MarketplaceListing.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (list.isEmpty) {
          return const Center(child: Text('No listings yet. Tap “Add Listing”.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _myListingCard(list[i]),
        );
      },
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search items...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () => setState(() => _searchCtrl.clear()),
                icon: const Icon(Icons.clear),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          child: _chipDropdown(
            label: 'Category',
            value: _selectedCategory,
            values: _categoryOptions,
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _chipDropdown(
            label: 'Warmth',
            value: _selectedWarmth,
            values: _warmthOptions,
            onChanged: (v) => setState(() => _selectedWarmth = v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _chipDropdown(
            label: 'Sort',
            value: _sort,
            values: _sortOptions,
            onChanged: (v) => setState(() => _sort = v),
          ),
        ),
      ],
    );
  }

  Widget _chipDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: values.map((v) => DropdownMenuItem(value: v, child: Text('$label: $v'))).toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _activeFiltersBar() {
    final chips = <Widget>[];

    if (_selectedCategory != 'All') {
      chips.add(_activeChip('Category: $_selectedCategory', () => setState(() => _selectedCategory = 'All')));
    }
    if (_selectedWarmth != 'All') {
      chips.add(_activeChip('Warmth: $_selectedWarmth', () => setState(() => _selectedWarmth = 'All')));
    }
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty) {
      chips.add(_activeChip('Search: $q', () => setState(() => _searchCtrl.clear())));
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList(),
            ),
          ),
        ),
        TextButton(onPressed: _clearFilters, child: const Text('Clear')),
      ],
    );
  }

  Widget _activeChip(String text, VoidCallback onRemove) {
    return Chip(
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 10),
            const Text('No items match your filters.', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              _hasActiveFilters ? 'Try clearing filters or changing your search.' : 'No listings available yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_hasActiveFilters)
              ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _listingCard(MarketplaceListing p) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _imageBox(p.imageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.category} • ${p.warmthLevel}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('RM ${p.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                tooltip: 'Add to cart',
                icon: const Icon(Icons.add_shopping_cart_rounded),
                onPressed: () async {
                  try {
                    await CartService.addToCart(listingId: p.id, qty: 1);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myListingCard(MarketplaceListing p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _imageBox(p.imageUrl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${p.category} • ${p.warmthLevel}',
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('RM ${p.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('marketplace_listings').doc(p.id).delete();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
            },
          ),
        ],
      ),
    );
  }

  Widget _imageBox(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
      child: SizedBox(
        width: 96,
        height: 96,
        child: url.isEmpty
            ? Container(
                color: AppColors.softGreen.withValues(alpha: 0.5),
                child: const Icon(Icons.image_outlined, color: AppColors.primaryGreen),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.softGreen.withValues(alpha: 0.5),
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.primaryGreen),
                ),
              ),
      ),
    );
  }
}
