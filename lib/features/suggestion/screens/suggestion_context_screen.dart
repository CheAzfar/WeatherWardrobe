import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../../settings/screens/city_selector_screen.dart';
import '../../settings/services/city_store.dart';

import '../../weather/models/weather_info.dart';
import '../../weather/services/weather_service.dart';

import '../models/outfit_suggestion.dart';
import '../services/suggestion_engine.dart';
import '../../wardrobe/models/clothing_item.dart';

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
  String _city = CityStore.defaultCity;

  // FIX: make nullable (no late)
  Future<WeatherInfo>? _weatherFuture;

  @override
  void initState() {
    super.initState();

    // Set an initial future immediately so the screen can build safely
    _weatherFuture = WeatherService.fetchByCity(_city);

    // Then fetch the saved city (Firestore) and refresh weather
    _initCityAndWeather();
  }

  Future<void> _initCityAndWeather() async {
    try {
      final c = await CityStore.fetchCity(); // Firestore-based
      if (!mounted) return;

      setState(() {
        _city = c;
        _weatherFuture = WeatherService.fetchByCity(_city);
      });
    } catch (e) {
      // If Firestore city fetch fails, we still keep default city weather future
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved city. Using default. ($e)')),
      );
    }
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchByCity(_city);
    });
  }

  Future<void> _changeCity() async {
    final chosen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectorScreen()),
    );

    // After returning, re-fetch Firestore city + refresh weather.
    if (chosen != null) {
      try {
        final c = await CityStore.fetchCity();
        if (!mounted) return;

        setState(() {
          _city = c;
          _weatherFuture = WeatherService.fetchByCity(_city);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('City updated to $_city')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update city: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: handle null future safely
    final wf = _weatherFuture;
    if (wf == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            onPressed: _refreshWeather,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<WeatherInfo>(
        future: wf,
        builder: (context, wSnap) {
          if (wSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wSnap.hasError) {
            return _errorState('Weather error: ${wSnap.error}');
          }
          if (!wSnap.hasData) {
            return _errorState('Weather error: No data returned.');
          }

          final weather = wSnap.data!;

          return FutureBuilder<OutfitSuggestion>(
            future: SuggestionEngine.generate(
              temperature: weather.tempC,
              isRaining: weather.isRaining,
              context: widget.contextType,
            ),
            builder: (context, sSnap) {
              if (sSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (sSnap.hasError) {
                return _errorState('Suggestion error: ${sSnap.error}');
              }
              if (!sSnap.hasData) {
                return _errorState('Suggestion error: No data returned.');
              }

              final suggestion = sSnap.data!;
              return _content(weather, suggestion);
            },
          );
        },
      ),
    );
  }

  Widget _content(WeatherInfo w, OutfitSuggestion s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      children: [
        _heroHeader(city: w.city, contextType: widget.contextType),
        const SizedBox(height: 12),
        _weatherSummary(w),
        const SizedBox(height: 12),
        _reasonCard(s.reason),
        const SizedBox(height: 16),
        _sectionTitle('Recommended Outfit'),
        const SizedBox(height: 10),

        if (s.selectedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No suitable items found. Try adding more wardrobe items.'),
          )
        else
          _itemsGrid(s.selectedItems),

        if (s.missingCategories.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionTitle('Missing Items'),
          const SizedBox(height: 6),
          const Text(
            'Add these categories to improve future recommendations.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ...s.missingCategories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _missingCard(category: c),
            ),
          ),
        ],
      ],
    );
  }

  Widget _heroHeader({required String city, required String contextType}) {
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
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Context: $contextType',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'City: $city',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${w.tempC.toStringAsFixed(1)}°C • ${w.condition}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            w.isRaining ? 'Raining' : 'Not raining',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: w.isRaining ? Colors.blue : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        reason,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }

  Widget _itemsGrid(List<ClothingItem> items) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final url = item.imageUrl ?? '';

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
                  child: url.isEmpty
                      ? Container(
                          color: AppColors.softGreen.withValues(alpha: 0.6),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.primaryGreen,
                              size: 36,
                            ),
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.softGreen.withValues(alpha: 0.6),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.primaryGreen,
                                size: 36,
                              ),
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
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} • ${item.warmthLevel}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

  Widget _missingCard({required String category}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String msg) {
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
              onPressed: _refreshWeather,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
