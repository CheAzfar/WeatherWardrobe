import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../services/shop_service.dart';

class ShopSimilarScreen extends StatelessWidget {
  final String category;

  const ShopSimilarScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final items = ShopService.getItemsByCategory(category);

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop $category'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.store} • RM ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(item.url);

                      final launched = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!launched) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unable to open link. Please install or enable a browser.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('View Product'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
