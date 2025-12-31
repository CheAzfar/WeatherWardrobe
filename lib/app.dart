import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/routing/app_router.dart';

class WeatherWardrobeApp extends StatelessWidget {
  const WeatherWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherWardrobe',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
      ),
      initialRoute: AppRouter.initialRoute,
      routes: AppRouter.routes,
    );
  }
}
