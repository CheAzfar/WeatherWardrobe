import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../settings/screens/city_selector_screen.dart';
import '../../settings/services/city_store.dart';

import 'suggestion_result_screen.dart';

class SuggestionContextScreen extends StatefulWidget {
  const SuggestionContextScreen({super.key});

  @override
  State<SuggestionContextScreen> createState() => _SuggestionContextScreenState();
}

class _SuggestionContextScreenState extends State<SuggestionContextScreen> {
  String? _selectedContext;
  late String _city;

  final List<_ContextOption> _options = const [
    _ContextOption(
      id: 'Casual',
      title: 'Casual / Daily',
      subtitle: 'Relaxed outfit for daily activities.',
      icon: Icons.weekend_outlined,
    ),
    _ContextOption(
      id: 'Work',
      title: 'Work / Formal',
      subtitle: 'Neat and presentable for meetings or office.',
      icon: Icons.work_outline,
    ),
    _ContextOption(
      id: 'Outdoor',
      title: 'Outdoor / Active',
      subtitle: 'Comfort-focused for walking or outdoor time.',
      icon: Icons.directions_walk_outlined,
    ),
    _ContextOption(
      id: 'Event',
      title: 'Event / Special',
      subtitle: 'Stylish look for gatherings or special occasions.',
      icon: Icons.celebration_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _city = CityStore.getCity();
  }

  Future<void> _changeCity() async {
    final chosen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectorScreen()),
    );

    if (chosen != null) {
      setState(() {
        _city = CityStore.getCity();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('City updated to $_city')),
      );
    }
  }

  void _continue() {
    if (_selectedContext == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestionResultScreen(contextType: _selectedContext!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestion Setup'),
        actions: [
          IconButton(
            tooltip: 'Change city',
            onPressed: _changeCity,
            icon: const Icon(Icons.location_on_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        children: [
          _heroHeader(),
          const SizedBox(height: 16),

          const Text(
            'Choose your context',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your recommendation will adapt based on weather and wardrobe items.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          ..._options.map((opt) => _contextCard(opt)).toList(),

          const SizedBox(height: 18),

          _primaryCta(),
          const SizedBox(height: 10),

          Center(
            child: Text(
              _selectedContext == null
                  ? 'Select a context to continue'
                  : 'Selected: $_selectedContext',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

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
            child: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Outfit Suggestion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
              'Change',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextCard(_ContextOption opt) {
    final bool isSelected = _selectedContext == opt.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedContext = opt.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
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
                child: Icon(opt.icon, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opt.subtitle,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryCta() {
    final bool enabled = _selectedContext != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? _continue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.35),
          disabledForegroundColor: Colors.white.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Generate Suggestion'),
      ),
    );
  }
}

class _ContextOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ContextOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
