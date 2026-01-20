import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../../settings/screens/city_selector_screen.dart';
import '../../settings/services/city_store.dart';

import '../../weather/models/weather_info.dart';
import '../../weather/services/weather_service.dart';

import 'suggestion_result_screen.dart';

/// Step 1/2: Pick the situation/context ("Where are you going?")
/// Then navigate to [SuggestionResultScreen] with weather + selected context.
class SuggestionContextScreen extends StatefulWidget {
  const SuggestionContextScreen({super.key});

  @override
  State<SuggestionContextScreen> createState() => _SuggestionContextScreenState();
}

class _SuggestionContextScreenState extends State<SuggestionContextScreen> {
  String _city = CityStore.defaultCity;
  Future<WeatherInfo>? _weatherFuture;

  // Default selection (matches your screenshot style)
  String _selectedContext = 'Air-Conditioned Office';

  final List<_ContextOption> _options = const [
    _ContextOption(
      title: 'Air-Conditioned Office',
      subtitle: 'Cold indoor (18–20°C)',
      icon: Icons.ac_unit_rounded,
    ),
    _ContextOption(
      title: 'Outdoor Activities',
      subtitle: 'Full sun exposure',
      icon: Icons.wb_sunny_rounded,
    ),
    _ContextOption(
      title: 'Mixed Indoor/Outdoor',
      subtitle: 'Frequent transitions',
      icon: Icons.swap_horiz_rounded,
    ),
    _ContextOption(
      title: 'Client Meeting',
      subtitle: 'Professional setting',
      icon: Icons.business_center_rounded,
    ),
    _ContextOption(
      title: 'Casual Day Out',
      subtitle: 'Relaxed environment',
      icon: Icons.emoji_emotions_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchByCity(_city);
    _initCityAndWeather();
  }

  Future<void> _initCityAndWeather() async {
    try {
      final c = await CityStore.fetchCity();
      if (!mounted) return;
      setState(() {
        _city = c;
        _weatherFuture = WeatherService.fetchByCity(_city);
      });
    } catch (_) {
      // Keep default city
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

    if (chosen != null) {
      await _initCityAndWeather();
    }
  }

  void _goToResult(WeatherInfo weather) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestionResultScreen(
          weather: weather,
          contextType: _selectedContext,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wf = _weatherFuture;
    if (wf == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestion'),
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
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _errorState('Weather error: ${snap.error}');
          }
          if (!snap.hasData) {
            return _errorState('Weather error: No data returned.');
          }

          final weather = snap.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Help us suggest the perfect outfit',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _weatherCard(weather),
              const SizedBox(height: 14),
              ..._options.map(_contextTile),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToResult(weather),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Personalized Suggestion',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _weatherCard(WeatherInfo w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(_conditionIcon(w.condition), size: 34, color: AppColors.primaryGreen),
          const SizedBox(height: 6),
          Text(
            '${w.tempC.toStringAsFixed(0)}°C',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Text(
            w.condition,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextTile(_ContextOption o) {
    final selected = _selectedContext == o.title;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primaryGreen : AppColors.border),
        color: selected ? AppColors.softGreen.withValues(alpha: 0.35) : Colors.white,
      ),
      child: ListTile(
        leading: Icon(o.icon, color: selected ? AppColors.primaryGreen : AppColors.textMuted),
        title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          o.subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
            : const Icon(Icons.radio_button_unchecked, color: AppColors.border),
        onTap: () => setState(() => _selectedContext = o.title),
      ),
    );
  }

  IconData _conditionIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('sun')) {
      return Icons.wb_sunny_rounded;
    }
    if (lower.contains('cloud')) return Icons.cloud_rounded;
    if (lower.contains('rain') || lower.contains('drizzle')) {
      return Icons.beach_access_rounded;
    }
    if (lower.contains('thunder')) return Icons.flash_on_rounded;
    return Icons.cloud_outlined;
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

class _ContextOption {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ContextOption({required this.title, required this.subtitle, required this.icon});
}
