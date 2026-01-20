import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/marketplace_listing.dart';
import '../services/cart_service.dart';

class ProductDetailsScreen extends StatelessWidget {
  final MarketplaceListing listing;

  const ProductDetailsScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Large Hero Image AppBar
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: listing.id,
                child: Image.network(
                  listing.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                ),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 2. Details Body
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "RM ${listing.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chips (Category, Size, Warmth)
                    Wrap(
                      spacing: 8,
                      children: [
                        _infoChip(Icons.category, listing.category),
                        _infoChip(Icons.straighten, "Size: ${listing.size}"),
                        _infoChip(Icons.thermostat, listing.warmthLevel),
                      ],
                    ),
                    const Divider(height: 40),

                    // Description Section
                    const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      listing.description.isEmpty ? "No description provided." : listing.description,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                    ),

                    const SizedBox(height: 100), // Spacing for bottom button
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      
      // 3. Floating "Add to Cart" Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await CartService.addToCart(listingId: listing.id, qty: 1);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart!")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text("Add to Cart"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.grey[700]),
      label: Text(label),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
    );
  }
}