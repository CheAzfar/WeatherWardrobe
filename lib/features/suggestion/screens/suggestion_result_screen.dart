import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../weather/models/weather_info.dart';
import '../../weather/services/weather_service.dart';

import '../../settings/screens/city_selector_screen.dart';
import '../../settings/services/city_store.dart';

import '../services/suggestion_engine.dart';
import '../../shop/screens/shop_similar_screen.dart';

class SuggestionResultScreen extends StatefulWidget {
  final String contextType;

  const SuggestionResultScreen({
    super.key,
    required this.contextType,
  });

  @override
  State<SuggestionResultScreen> createState() => _SuggestionResultScreenState();
}

class _SuggestionResultScreenState extends State<SuggestionResultScreen> {
  late String _city;
  late Future<WeatherInfo> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _city = CityStore.getCity();
    _weatherFuture = WeatherService.fetchByCity(_city);
  }

  void _refresh() {
    setState(() {
      _city = CityStore.getCity();
      _weatherFuture = WeatherService.fetchByCity(_city);
    });
  }

  Future<void> _changeCity() async {
    final chosen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectorScreen()),
    );
    if (chosen != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('City updated to ${CityStore.getCity()}')),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Suggestion'),
        actions: [
          IconButton(
            tooltip: 'Change city',
            onPressed: _changeCity,
            icon: const Icon(Icons.location_on_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<WeatherInfo>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final w = snapshot.data!;
          final suggestion = SuggestionEngine.generate(
            temperature: w.tempC,
            isRaining: w.isRaining,
            context: widget.contextType,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              _heroHeader(
                contextType: widget.contextType,
                city: w.city,
              ),
              const SizedBox(height: 14),

              _weatherSummary(w),
              const SizedBox(height: 12),

              _reasonCard(suggestion.reason),
              const SizedBox(height: 16),

              _sectionTitle('Recommended Outfit'),
              const SizedBox(height: 10),

              ...suggestion.selectedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _itemCard(
                    title: item.name,
                    subtitle: '${item.category} • Warmth ${item.warmthLevel}',
                    icon: Icons.checkroom,
                  ),
                );
              }).toList(),

              if (suggestion.missingCategories.isNotEmpty) ...[
                const SizedBox(height: 18),
                _sectionTitle('Missing Items'),
                const SizedBox(height: 6),
                const Text(
                  'Add these categories to improve future recommendations.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),

                ...suggestion.missingCategories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _missingCard(category: c),
                  );
                }).toList(),
              ],

              const SizedBox(height: 18),
              _bottomActions(),
            ],
          );
        },
      ),
    );
  }

  // ---------- UI widgets ----------

  Widget _heroHeader({required String contextType, required String city}) {
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
            child: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generated Suggestion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Context: $contextType • $city',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _changeCity,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text(
              'City',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherSummary(WeatherInfo w) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weather Used',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.thermostat, '${w.tempC.toStringAsFixed(0)}°C'),
              _chip(Icons.cloud_outlined, w.condition),
              _chip(
                w.isRaining ? Icons.beach_access_rounded : Icons.wb_sunny_outlined,
                w.isRaining ? 'Rain: Yes' : 'Rain: No',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reasonCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why this outfit?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _itemCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _missingCard({required String category}) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Missing category in wardrobe',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopSimilarScreen(category: category)),
              );
            },
            child: const Text(
              'Find',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _changeCity,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('Change City'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to load weather.',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _changeCity,
                child: const Text('Change city'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
