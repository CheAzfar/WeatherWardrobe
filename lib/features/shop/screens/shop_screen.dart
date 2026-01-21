import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/marketplace_listing.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'create_listing_screen.dart';
import 'product_details_screen.dart'; 
import '/notifications/screens/notifications_screen.dart';
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

  // Browse Tab Filters
  String _selectedCategory = 'All';
  String _selectedWarmth = 'All';
  String _sort = 'Newest';
  final TextEditingController _searchCtrl = TextEditingController();

  // My Listings Tab Filter
  String _myListingsFilter = 'Active'; // 'Active' or 'Sold'

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
    
    // Initialize filters if passed from Home Screen
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
          p.description.toLowerCase().contains(q);

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
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          StreamBuilder(
            stream: CartService.streamCart(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
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
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Sell Item'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen()));
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyListingsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BROWSE TAB
  // ---------------------------------------------------------------------------
  Widget _buildBrowseTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _searchBar(),
              const SizedBox(height: 12),
              _filterRow(),
              if (_hasActiveFilters) ...[
                const SizedBox(height: 12),
                _activeFiltersBar(),
              ],
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('marketplace_listings')
                .where('isAvailable', isEqualTo: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final docs = snap.data?.docs ?? [];
              final allDocs = docs.map((d) => MarketplaceListing.fromDoc(d)).toList();
              final filtered = _applyFilters(allDocs);

              if (filtered.isEmpty) return _emptyState();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _listingCard(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MY LISTINGS TAB (Updated with Active/Sold logic)
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // MY LISTINGS TAB (FIXED)
  // ---------------------------------------------------------------------------
  Widget _buildMyListingsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please sign in to manage listings.'));
    }

    return Column(
      children: [
        // 1. Toggle Active/Sold
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              _myListingToggleBtn('Active', _myListingsFilter == 'Active'),
              _myListingToggleBtn('Sold', _myListingsFilter == 'Sold'),
            ],
          ),
        ),

        // 2. List
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('marketplace_listings')
                .where('sellerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final docs = snap.data?.docs ?? [];
              
              // FIX: Filter the raw docs FIRST, using 'd' correctly
              final filteredDocs = docs.where((d) {
                final data = d.data();
                final status = data['status'] ?? 'active';
                final isAvailable = data['isAvailable'] ?? true;

                if (_myListingsFilter == 'Active') {
                  // Show if available AND not marked sold
                  return isAvailable == true && status != 'sold';
                } else {
                  // Show if sold OR unavailable
                  return status == 'sold' || isAvailable == false;
                }
              }).toList();

              // THEN convert the filtered docs to your model
              final filteredListings = filteredDocs
                  .map((d) => MarketplaceListing.fromDoc(d))
                  .toList();

              if (filteredListings.isEmpty) {
                return Center(child: Text('No ${_myListingsFilter.toLowerCase()} listings.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredListings.length,
                itemBuilder: (context, i) {
                  final item = filteredListings[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(width:60, height:60, color:Colors.grey[200]),
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("RM ${item.price.toStringAsFixed(2)} • ${item.size}"),
                      trailing: _myListingsFilter == 'Active'
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteListing(item.id),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                            child: const Text("SOLD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Helper to check availability safely
  bool isAvailable(MarketplaceListing item) {
    // We can't see the raw doc here easily without re-parsing, 
    // but the stream builder above does the map lookup.
    return true; 
  }

  Widget _myListingToggleBtn(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _myListingsFilter = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteListing(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('marketplace_listings').doc(id).delete();
    }
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search items...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                onPressed: () => setState(() => _searchCtrl.clear()),
                icon: const Icon(Icons.clear, color: Colors.grey),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
        const SizedBox(width: 8),
        Expanded(
          child: _chipDropdown(
            label: 'Warmth',
            value: _selectedWarmth,
            values: _warmthOptions,
            onChanged: (v) => setState(() => _selectedWarmth = v),
          ),
        ),
        const SizedBox(width: 8),
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: values.map((v) {
            final display = (v == value && v != 'All' && label != 'Sort') ? v : (v == 'All' ? label : v);
            return DropdownMenuItem(value: v, child: Text(display, maxLines: 1));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList(),
      ),
    );
  }

  Widget _activeChip(String text, VoidCallback onRemove) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      labelStyle: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryGreen),
      onDeleted: onRemove,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('No items match your filters.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All Filters', style: TextStyle(color: AppColors.primaryGreen)),
            ),
        ],
      ),
    );
  }

  Widget _listingCard(MarketplaceListing item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(listing: item)),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: item.id,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.size,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.category,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RM ${item.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}