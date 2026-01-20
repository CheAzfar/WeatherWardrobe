import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (required)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey = 'pk_test_51SrKo7F25xLACdfSuSY9mCaRqTZY6jOIp7hDGlA2J6FUjvDOU4RGrsxxiyb2g3QPLbFBH2e9oP5daF5caKIJROeK00ebh1RcH9';
  await Stripe.instance.applySettings();

  runApp(const WeatherWardrobeApp());
}
