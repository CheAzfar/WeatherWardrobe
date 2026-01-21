import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../suggestion/screens/suggestion_context_screen.dart';

import '../../weather/models/weather_info.dart';
import '../../weather/services/weather_service.dart';

import '../../settings/screens/city_selector_screen.dart';
import '../../settings/services/city_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _city = CityStore.defaultCity;

  Future<WeatherInfo>? _weatherFuture;

  @override
  void initState() {
    super.initState();

    // Start with default city, so UI can render immediately
    _weatherFuture = WeatherService.fetchByCity(_city);

    // Then load saved city from Firestore and refresh
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
    } catch (_) {
      // If Firestore fails, keep default city
    }
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchByCity(_city);
    });
  }

  Future<void> _openCitySelector() async {
    final chosen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectorScreen()),
    );

    // After returning, re-fetch Firestore city + refresh weather
    if (chosen != null) {
      await _initCityAndWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wf = _weatherFuture;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshWeather(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            _heroHeader(),
            const SizedBox(height: 16),

            if (wf == null)
              _loadingWeatherCard()
            else
              FutureBuilder<WeatherInfo>(
                future: wf,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingWeatherCard();
                  }
                  if (snapshot.hasError) {
                    return _errorWeatherCard(snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return _errorWeatherCard('No weather data returned.');
                  }
                  final w = snapshot.data!;
                  return _weatherCard(w);
                },
              ),

            const SizedBox(height: 10),
            _weatherActionsRow(),
            const SizedBox(height: 18),

            _todayOutfitCard(context),
            const SizedBox(height: 18),

            _primaryCta(context),
          ],
        ),
      ),
    );
  }

  // ---------------- UI SECTIONS ----------------

  Widget _heroHeader() {
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
            child: const Icon(
              Icons.cloud_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Wardrobe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Location: $_city',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _pillButton(
            icon: Icons.location_on_outlined,
            label: 'Change city',
            onTap: _openCitySelector,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pillButton(
            icon: Icons.refresh,
            label: 'Refresh',
            onTap: _refreshWeather,
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingWeatherCard() {
    return _cardShell(
      child: const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _errorWeatherCard(String msg) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Weather',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load weather.\n$msg',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _refreshWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try again'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _openCitySelector,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Change city'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherCard(WeatherInfo w) {
    final icon = _conditionIcon(w.condition);

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Weather',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${w.tempC.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 32, color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${w.condition} • ${w.city}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(
                icon: Icons.water_drop_outlined,
                label: 'Humidity ${w.humidity}%',
              ),
              _miniChip(
                icon: Icons.air,
                label: 'Wind ${w.windKmh.toStringAsFixed(0)} km/h',
              ),
              _miniChip(
                icon: w.isRaining
                    ? Icons.beach_access_rounded
                    : Icons.wb_sunny_outlined,
                label: w.isRaining ? 'Rain: Yes' : 'Rain: No',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip({required IconData icon, required String label}) {
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
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
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

  Widget _todayOutfitCard(BuildContext context) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Outfit',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Generated in Suggestion module',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the button below to get a personalized recommendation.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Outfit details (optional later)')),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _primaryCta(BuildContext context) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SuggestionContextScreen(),
        ),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome_outlined, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Get Personalized Suggestion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}


}
