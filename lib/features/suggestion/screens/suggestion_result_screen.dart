import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../../shop/screens/shop_screen.dart';
import '../../weather/models/weather_info.dart';

import '../../wardrobe/models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../services/suggestion_engine.dart';

class SuggestionResultScreen extends StatefulWidget {
  final WeatherInfo weather;
  final String contextType;

  const SuggestionResultScreen({
    super.key,
    required this.weather,
    required this.contextType,
  });

  @override
  State<SuggestionResultScreen> createState() => _SuggestionResultScreenState();
}

class _SuggestionResultScreenState extends State<SuggestionResultScreen> {
  late Future<OutfitSuggestion> _future;

  /// Holds the current picked index for each category, so refresh can cycle
  final Map<String, int> _pickIndex = {};

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    _future = SuggestionEngine.generate(
      temperature: widget.weather.tempC,
      isRaining: widget.weather.isRaining,
      context: widget.contextType,
    );

    // When we regenerate (new context/weather), reset picks to start from best item
    _pickIndex.clear();
  }

  /// Refresh SHOULD NOT regenerate (that feels random).
  /// It should cycle within the existing candidate lists.
  void _cycleAll(OutfitSuggestion s) {
    setState(() {
      for (final cat in s.recommendedByCategory.keys) {
        final list = s.recommendedByCategory[cat] ?? const <ClothingItem>[];
        if (list.isEmpty) continue;
        final cur = _pickIndex[cat] ?? 0;
        _pickIndex[cat] = (cur + 1) % list.length;
      }
    });
  }

  ClothingItem? _picked(String category, OutfitSuggestion s) {
    final list = s.recommendedByCategory[category] ?? const <ClothingItem>[];
    if (list.isEmpty) return null;

    final idx = _pickIndex[category] ?? 0;
    return list[idx % list.length];
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.weather;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Suggestion'),
        actions: [
          IconButton(
            tooltip: 'Regenerate (re-run engine)',
            onPressed: () => setState(_regenerate),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: FutureBuilder<OutfitSuggestion>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _errorState('Suggestion error: ${snap.error}', onRetry: () => setState(_regenerate));
          }

          final suggestion = snap.data;
          if (suggestion == null) {
            return _errorState('No suggestion returned.', onRetry: () => setState(_regenerate));
          }

          final hasAnyCandidates = suggestion.recommendedByCategory.values.any((l) => l.isNotEmpty);
          final hasMissing = suggestion.missingNeeds.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              _topHeader(w),
              const SizedBox(height: 14),
              _summaryCard(
                contextType: widget.contextType,
                reason: suggestion.reason,
              ),
              const SizedBox(height: 16),

              _sectionTitle('Recommended Outfit'),
              const SizedBox(height: 10),

              if (!hasAnyCandidates)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No suitable items found. Try adding more wardrobe items.'),
                )
              else
                _recommendedOutfitCard(suggestion),

              // Big missing card (like screenshot)
              if (hasMissing) ...[
                const SizedBox(height: 18),
                _missingDetectedCard(
                  suggestion: suggestion,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _recommendedOutfitCard(OutfitSuggestion s) {
    // IMPORTANT: This assumes your engine uses these keys in recommendedByCategory:
    // Tops, Bottoms, Outerwear, Shoes.
    // If your keys differ (e.g., "Shoes" vs "Footwear"), update here.
    final orderedCategories = <String>[
      'Tops',
      'Bottoms',
      if ((s.recommendedByCategory['Outerwear'] ?? const []).isNotEmpty || _isMissingCategory(s, 'Outerwear'))
        'Outerwear',
      'Shoes',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Outfit',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),

          ...orderedCategories.map((cat) {
            final item = _picked(cat, s);
            if (item == null) {
              // If missing, show “Not in wardrobe” row with Shop button
              final warm = _desiredWarmthForMissing(s, cat);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _missingRow(category: cat, warmthLevel: warm),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _itemRow(item: item),
            );
          }).toList(),

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _cycleAll(s),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMissingCategory(OutfitSuggestion s, String category) {
    return s.missingNeeds.any((m) => m.category == category);
  }

  String _desiredWarmthForMissing(OutfitSuggestion s, String category) {
    final match = s.missingNeeds.where((m) => m.category == category).toList();
    if (match.isEmpty) return 'Medium';
    // If multiple, take the first
    return match.first.warmthLevel;
  }

  Widget _itemRow({required ClothingItem item}) {
    final url = item.imageUrl ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.isEmpty
                  ? const Icon(Icons.checkroom_outlined, color: AppColors.primaryGreen)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, color: AppColors.primaryGreen),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                const Text(
                  '✓ In your wardrobe',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _missingRow({required String category, required String warmthLevel}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.close_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  'Not in wardrobe • Need $warmthLevel',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopScreen(
                    initialTabIndex: 0,
                    initialCategory: _mapMissingToShopCategory(category),
                    initialWarmth: warmthLevel,
                  ),
                ),
              );
            },
            child: const Text('Shop'),
          ),
        ],
      ),
    );
  }

  Widget _missingDetectedCard({required OutfitSuggestion suggestion}) {
    // Use the first missing need for the main CTA
    final primary = suggestion.missingNeeds.first;
    final cat = _mapMissingToShopCategory(primary.category);
    final warm = primary.warmthLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.softGreen.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 12),
          const Text(
            'Missing Item Detected',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'You are missing: ${suggestion.missingNeeds.map((m) => '${m.category} (${m.warmthLevel})').join(', ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopScreen(
                      initialTabIndex: 0,
                      initialCategory: cat,
                      initialWarmth: warm,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Browse $cat',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Continue Without',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapMissingToShopCategory(String c) {
    final v = c.trim();
    if (v.isEmpty) return 'All';
    return v;
  }

  Widget _topHeader(WeatherInfo w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.95),
            AppColors.primaryGreen.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outfit Suggestion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on ${w.tempC.toStringAsFixed(0)}°C, ${w.condition}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required String contextType, required String reason}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contextType,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }

  Widget _errorState(String msg, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.red),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
