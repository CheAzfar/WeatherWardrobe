import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (required)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Stripe.publishableKey =
      'pk_test_51SrHwI3uzkOxb9ef84LHpu96WTijJ00OSdv3KTKpNz6M3dKxITyKcgiTF0lv8lLJZEPsnxwQKjqKzV9ComzR0sdf00zoNk463I';
  await Stripe.instance.applySettings();

  runApp(const WeatherWardrobeApp());
}
