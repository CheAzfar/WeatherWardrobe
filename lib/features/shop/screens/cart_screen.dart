import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/marketplace_listing.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';


class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream() {
    // Same collection as Shop
    return FirebaseFirestore.instance
        .collection('marketplace_listings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () async {
              await CartService.clearCart();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: CartService.streamCart(),
        builder: (context, cartSnap) {
          if (cartSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cartSnap.hasError) {
            return Center(child: Text('Cart error: ${cartSnap.error}'));
          }
          final cartDocs = cartSnap.data?.docs ?? [];
          if (cartDocs.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final qtyByListing = <String, int>{};
          for (final d in cartDocs) {
            final data = d.data();
            final id = (data['listingId'] ?? d.id).toString();
            final qty = (data['qty'] is num) ? (data['qty'] as num).toInt() : 1;
            qtyByListing[id] = qty;
          }

          return StreamBuilder(
            stream: _listingsStream(),
            builder: (context, listSnap) {
              if (listSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (listSnap.hasError) {
                return Center(child: Text('Listings error: ${listSnap.error}'));
              }

              final listingDocs = listSnap.data?.docs ?? [];
              final listings = listingDocs.map(MarketplaceListing.fromDoc).toList();
              final inCart = listings.where((l) => qtyByListing.containsKey(l.id)).toList();

              double total = 0.0;
              for (final l in inCart) {
                total += l.price * (qtyByListing[l.id] ?? 1);
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: inCart.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = inCart[i];
                        final qty = qtyByListing[item.id] ?? 1;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _thumb(item.imageUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text('${item.category} • ${item.warmthLevel}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text('RM ${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => CartService.updateQty(listingId: item.id, qty: qty + 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  IconButton(
                                    onPressed: () => CartService.updateQty(listingId: item.id, qty: qty - 1),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total: RM ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  cartItems: inCart,
                                  subtotalAmount: total,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Checkout'),
                        ),

                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _thumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
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
