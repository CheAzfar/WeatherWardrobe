import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  // Update here if you want different structure
  static CollectionReference<Map<String, dynamic>> _cartRef(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('cart');
  }

  static Future<void> addToCart({
    required String listingId,
    int qty = 1,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _cartRef(user.uid).doc(listingId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'listingId': listingId,
        'qty': qty,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snap.data() ?? {};
      final current = (data['qty'] is num) ? (data['qty'] as num).toInt() : 1;
      await ref.update({'qty': current + qty});
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _cartRef(user.uid).snapshots();
  }

  static Future<void> removeFromCart({required String listingId}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('cart')
      .doc(listingId);

  await ref.delete();
}


  static Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    final snap = await _cartRef(user.uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
