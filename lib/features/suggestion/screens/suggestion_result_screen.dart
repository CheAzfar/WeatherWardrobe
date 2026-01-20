import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../wardrobe/models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../services/suggestion_engine.dart';

class SuggestionResultScreen extends StatefulWidget {
  final double temperature;
  final bool isRaining;
  final String context;

  const SuggestionResultScreen({
    super.key,
    required this.temperature,
    required this.isRaining,
    required this.context,
  });

  @override
  State<SuggestionResultScreen> createState() => _SuggestionResultScreenState();
}

class _SuggestionResultScreenState extends State<SuggestionResultScreen> {
  late Future<OutfitSuggestion> _future;

  @override
  void initState() {
    super.initState();
    _future = SuggestionEngine.generate(
      temperature: widget.temperature,
      isRaining: widget.isRaining,
      context: widget.context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Suggestion'),
      ),
      body: FutureBuilder<OutfitSuggestion>(
        future: _future,
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

          final suggestion = snap.data;
          if (suggestion == null) {
            return const Center(child: Text('No suggestion available'));
          }

          return _buildContent(suggestion);
        },
      ),
    );
  }

  Widget _buildContent(OutfitSuggestion suggestion) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(suggestion.reason),
          const SizedBox(height: 16),

          if (suggestion.selectedItems.isNotEmpty)
            Expanded(child: _itemsGrid(suggestion.selectedItems))
          else
            const Expanded(
              child: Center(child: Text('No suitable outfit found')),
            ),

          if (suggestion.missingCategories.isNotEmpty)
            _missingBox(suggestion.missingCategories),
        ],
      ),
    );
  }

  Widget _header(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.9),
            AppColors.primaryGreen.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsGrid(List<ClothingItem> items) {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

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
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: AppColors.softGreen.withValues(alpha: 0.6),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.primaryGreen,
                              size: 36,
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} • ${item.warmthLevel}',
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
  }

  Widget _missingBox(List<String> missing) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Missing categories: ${missing.join(', ')}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
