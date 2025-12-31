import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/city_store.dart';

class CitySelectorScreen extends StatefulWidget {
  const CitySelectorScreen({super.key});

  @override
  State<CitySelectorScreen> createState() => _CitySelectorScreenState();
}

class _CitySelectorScreenState extends State<CitySelectorScreen> {
  final TextEditingController _customCityController = TextEditingController();

  final List<String> _cities = const [
    'Kuala Lumpur',
    'Putrajaya',
    'Shah Alam',
    'Petaling Jaya',
    'Klang',
    'Kajang',
    'Seremban',
    'Melaka',
    'Johor Bahru',
    'Batu Pahat',
    'Kuala Terengganu',
    'Kota Bharu',
    'Kuantan',
    'Ipoh',
    'Alor Setar',
    'George Town',
    'Butterworth',
    'Kuching',
    'Miri',
    'Kota Kinabalu',
    'Sandakan',
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = CityStore.getCity();
  }

  @override
  void dispose() {
    _customCityController.dispose();
    super.dispose();
  }

  Future<void> _save(String city) async {
    final cleaned = city.trim();
    if (cleaned.isEmpty) return;

    await CityStore.setCity(cleaned);

    if (!mounted) return;
    Navigator.pop(context, cleaned); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('City updated to $cleaned')),
    );// return chosen city to caller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select City')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a city',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _cities.contains(_selected) ? _selected : _cities.first,
              items: _cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selected = v);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _save(_selected),
                child: const Text('Save Selected City'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Or type your city (manual)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customCityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., Bangi / Cyberjaya / Temerloh',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _save(_customCityController.text),
                child: const Text('Save Custom City'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current: ${CityStore.getCity()}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
