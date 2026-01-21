import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) print('User granted permission');
        
        // 2. Get Token (Wrapped in try-catch to prevent "SERVICE_NOT_AVAILABLE" crash)
        try {
          String? token = await _messaging.getToken();
          if (kDebugMode) print('FCM Token: $token');

          // 3. Save Token
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && token != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'fcmToken': token}, SetOptions(merge: true));
          }
        } catch (e) {
          // If token fetch fails (common on emulators), just log it and continue
          if (kDebugMode) print('Failed to get FCM token: $e');
        }

        // 4. Listen for refreshes
        _messaging.onTokenRefresh.listen((newToken) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': newToken}, SetOptions(merge: true));
            }
        }).onError((e) {
           if (kDebugMode) print('Token refresh error: $e');
        });

      } else {
        if (kDebugMode) print('User declined permission');
      }
    } catch (e) {
      // Catch ANY other error so the app doesn't freeze at startup
      if (kDebugMode) print('Notification Init Error: $e');
    }
  }
}