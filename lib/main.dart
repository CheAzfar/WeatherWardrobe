import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/wardrobe/models/clothing_item.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(ClothingItemAdapter());
  await Hive.openBox<ClothingItem>('wardrobeBox');
  await Hive.openBox('settingsBox');


  runApp(const WeatherWardrobeApp());
} //test commit
