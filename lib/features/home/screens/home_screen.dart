import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../shop/screens/shop_screen.dart'; 
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
  
  // Stream to listen to user's real wardrobe changes live
  Stream<QuerySnapshot>? _wardrobeStream;

  // Controls which item index is picked (for shuffling outfit)
  int _outfitSeed = 0;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchByCity(_city);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _wardrobeStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wardrobe_items')
          .snapshots();
    }

    _initCityAndWeather();
  }
  // --- DYNAMIC WEATHER GRADIENT ---
  LinearGradient _getWeatherGradient(double tempC) {
    if (tempC >= 30) {
      // Hot: Blazing Orange to Gold (Sunny/Hot)
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8008), Color(0xFFFFC837)], 
      );
    } else if (tempC >= 25) {
      // Warm: Soft Orange to Yellow
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2994A), Color(0xFFF2C94C)], 
      );
    } else if (tempC >= 20) {
      // Comfortable: Teal to Green (Pleasant)
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)], 
      );
    } else if (tempC >= 10) {
      // Cool: Blue to Cyan (Chilly)
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], 
      );
    } else {
      // Cold: Dark Slate to Deep Blue (Freezing/Night)
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF373B44), Color(0xFF4286f4)], 
      );
    }
  }
  Future<void> _initCityAndWeather() async {
    try {
      final c = await CityStore.fetchCity();
      if (!mounted) return;
      setState(() {
        _city = c;
        _weatherFuture = WeatherService.fetchByCity(_city);
      });
    } catch (_) {}
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchByCity(_city);
    });
  }

  void _cycleOutfit() {
    setState(() {
      _outfitSeed++; 
    });
  }

  Future<void> _openCitySelector() async {
    final chosen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitySelectorScreen()),
    );
    if (chosen != null) {
      await _initCityAndWeather();
    }
  }

  // --- NEW LOGIC: Determine required warmth based on Temp ---
  String _getRequiredWarmth(double tempC) {
    if (tempC >= 25) return 'Light';   // Hot -> Shorts/T-shirts
    if (tempC >= 18) return 'Medium';  // Mild -> Jeans/Hoodies
    return 'Heavy';                    // Cold -> Jackets/Coats
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshWeather(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            _heroHeader(),
            const SizedBox(height: 16),

            if (_weatherFuture == null)
              _loadingCard()
            else
              FutureBuilder<WeatherInfo>(
                future: _weatherFuture,
                builder: (context, weatherSnap) {
                  if (weatherSnap.connectionState == ConnectionState.waiting) return _loadingCard();
                  if (weatherSnap.hasError) return _errorCard(weatherSnap.error.toString());
                  if (!weatherSnap.hasData) return _errorCard('No weather data.');

                  final w = weatherSnap.data!;

                  return Column(
                    children: [
                      _weatherCard(w),
                      const SizedBox(height: 10),
                      _weatherActionsRow(),
                      const SizedBox(height: 18),
                      
                      // Outfit Section with Wardrobe Data
                      StreamBuilder<QuerySnapshot>(
                        stream: _wardrobeStream,
                        builder: (context, wardrobeSnap) {
                          final docs = wardrobeSnap.data?.docs ?? [];
                          return _smartOutfitSection(context, w, docs);
                        },
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 18),
            _primaryCta(context),
          ],
        ),
      ),
    );
  }

  // ---------------- SMART OUTFIT ENGINE (UPDATED) ----------------

  Widget _smartOutfitSection(BuildContext context, WeatherInfo w, List<QueryDocumentSnapshot> wardrobeItems) {
    // 1. Analyze Weather
    final bool isRainy = w.isRaining || w.condition.toLowerCase().contains('rain');
    final double temp = w.tempC;
    
    // 2. Determine Logic
    final String requiredWarmth = _getRequiredWarmth(temp);
    
    // Logic: Only show Outerwear if it is Cold (Heavy) or Rain is expected
    // This prevents showing jackets in 30 degree weather
    final bool needsOuterwear = (requiredWarmth == 'Heavy') || isRainy;

    // 3. Prep Text
    String prepText = "Conditions are mild.";
    IconData prepIcon = Icons.wb_sunny_outlined;
    Color prepColor = Colors.orange;

    if (isRainy) {
      prepText = "Rain detected. Waterproof gear is recommended.";
      prepIcon = Icons.umbrella;
      prepColor = Colors.blue;
    } else if (requiredWarmth == 'Heavy') {
      prepText = "It's cold (${temp.toInt()}°C). Wear heavy layers.";
      prepIcon = Icons.ac_unit;
      prepColor = Colors.cyan;
    } else if (requiredWarmth == 'Light') {
      prepText = "It's warm (${temp.toInt()}°C). Light clothing is best.";
      prepIcon = Icons.wb_sunny;
      prepColor = Colors.orange;
    } else {
      prepText = "Pleasant weather. Standard comfort wear.";
      prepIcon = Icons.cloud_queue;
      prepColor = Colors.blueGrey;
    }

    return Column(
      children: [
        // Forecast & Prep Card
        _cardShell(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: prepColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(prepIcon, color: prepColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Forecast & Advice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(prepText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Smart Outfit Card
        _cardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Look",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  InkWell(
                    onTap: _cycleOutfit,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.refresh, size: 16, color: AppColors.primaryGreen),
                          SizedBox(width: 4),
                          Text("Shuffle", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Outfit Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1
                  Expanded(
                    child: Column(
                      children: [
                        _outfitItemSlot(context, "Tops", wardrobeItems, requiredWarmth),
                        const SizedBox(height: 12),
                        // Only show Outerwear if truly needed
                        if (needsOuterwear)
                          _outfitItemSlot(context, "Outerwear", wardrobeItems, isRainy ? 'Rain' : requiredWarmth),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Column 2
                  Expanded(
                    child: Column(
                      children: [
                        _outfitItemSlot(context, "Bottoms", wardrobeItems, requiredWarmth),
                        const SizedBox(height: 12),
                        _outfitItemSlot(context, "Shoes", wardrobeItems, isRainy ? 'Rain' : requiredWarmth),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UPDATED LOGIC: Match by Warmth Level, not Name ---
  Widget _outfitItemSlot(BuildContext context, String category, List<QueryDocumentSnapshot> docs, String targetWarmth) {
    
    // Filter Wardrobe
    final matchingItems = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final String itemCat = (data['category'] ?? '').toString();
      // Default to 'Light' if not set
      final String itemWarmth = (data['warmthLevel'] ?? 'Light').toString();

      // 1. Must match Category
      if (itemCat != category) return false;

      // 2. Special Logic for Rain (Shoes/Outerwear)
      if (targetWarmth == 'Rain') {
        // Simple logic: Assume "Heavy" or "Medium" is better for rain than "Light"
        return itemWarmth == 'Heavy' || itemWarmth == 'Medium'; 
      }

      // 3. Strict Warmth Match
      return itemWarmth == targetWarmth;
    }).toList();

    // If User HAS items
    if (matchingItems.isNotEmpty) {
      // Modulus cycle logic
      final index = _outfitSeed % matchingItems.length;
      final item = matchingItems[index].data() as Map<String, dynamic>;
      
      final imageUrl = item['imageUrl'] ?? '';
      final name = item['name'] ?? category;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              if (matchingItems.length > 1)
                const Icon(Icons.swap_horiz, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: imageUrl.isNotEmpty 
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageUrl.isEmpty 
              ? const Center(child: Icon(Icons.checkroom, color: Colors.grey)) 
              : null,
          ),
          const SizedBox(height: 4),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
    } 
    
    // If User DOES NOT HAVE item -> Link to Shop
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Need: $targetWarmth", style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Navigator.push(
                context, 
                // Pass the needed warmth to the shop!
                MaterialPageRoute(builder: (_) => ShopScreen(
                  initialCategory: category, 
                  initialWarmth: targetWarmth == 'Rain' ? 'Heavy' : targetWarmth
                ))
              );
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withOpacity(0.05),
                border: Border.all(color: Colors.orange.withOpacity(0.3), style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.orange, size: 28),
                  const SizedBox(height: 4),
                  Text("Buy $category", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  // ---------------- UI HELPERS (Same as before) ----------------

  Widget _loadingCard() {
    return _cardShell(child: const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
  }

  Widget _errorCard(String msg) {
    return _cardShell(child: Text("Error: $msg"));
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
            child: const Icon(Icons.cloud_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Wardrobe',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Location: $_city',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherActionsRow() {
    return Row(
      children: [
        Expanded(child: _pillButton(icon: Icons.location_on_outlined, label: 'Change city', onTap: _openCitySelector)),
        const SizedBox(width: 10),
        Expanded(child: _pillButton(icon: Icons.refresh, label: 'Refresh', onTap: _refreshWeather)),
      ],
    );
  }

  Widget _pillButton({required IconData icon, required String label, required VoidCallback onTap}) {
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _weatherCard(WeatherInfo w) {
    final icon = _conditionIcon(w.condition);
    // 1. Get the dynamic gradient
    final backgroundGradient = _getWeatherGradient(w.tempC); 
    
    // 2. Text color should be white to stand out against bright gradients
    const textColor = Colors.white; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22), 
      decoration: BoxDecoration(
        gradient: backgroundGradient, // <--- APPLY GRADIENT HERE
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            // The shadow glows with the same color as the card!
            color: backgroundGradient.colors.first.withValues(alpha: 0.4), 
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: City & Icon ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.city, 
                    style: const TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    'Today', 
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14)
                  ),
                ],
              ),
              // Use a white version of the icon or the existing colored one
              Icon(icon, size: 48, color: textColor),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // --- Middle Row: Big Temp ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${w.tempC.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 68, 
                  fontWeight: FontWeight.bold, 
                  color: textColor,
                  height: 1.0, 
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.condition,
                    style: const TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Humidity ${w.humidity}%',
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // --- Bottom Row: Glassmorphism Metrics ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _glassMetric(Icons.air, '${w.windKmh.toStringAsFixed(0)} km/h'),
              _glassMetric(w.isRaining ? Icons.umbrella : Icons.wb_sunny, w.isRaining ? 'Rainy' : 'Clear'),
              // You can add a third metric here if you like
            ],
          ),
        ],
      ),
    );
  }

  // Helper for the "Glass" effect bubbles
  Widget _glassMetric(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2), // Semi-transparent white
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _conditionIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('sun')) return Icons.wb_sunny_rounded;
    if (lower.contains('cloud')) return Icons.cloud_rounded;
    if (lower.contains('rain') || lower.contains('drizzle')) return Icons.beach_access_rounded;
    if (lower.contains('thunder')) return Icons.flash_on_rounded;
    return Icons.cloud_outlined;
  }

  Widget _primaryCta(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SuggestionContextScreen()));
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
            Text('Get Personalized Suggestion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}