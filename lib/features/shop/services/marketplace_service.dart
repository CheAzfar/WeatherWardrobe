import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/marketplace_listing.dart';
import 'cart_service.dart';

class MarketplaceService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // -------------------------
  // Helpers
  // -------------------------
  static String _normalizeWarmth(String v) {
    final lower = v.trim().toLowerCase();
    if (lower == 'warm') return 'Heavy'; // backward compatibility
    if (lower == 'heavy') return 'Heavy';
    if (lower == 'medium') return 'Medium';
    if (lower == 'light') return 'Light';
    return v;
  }

  // -------------------------
  // 1) Create Listing
  // -------------------------
  static Future<String?> createListing({
    required String name,
    required String category,
    required String warmthLevel,
    required double price,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('marketplace_listings').add({
      // Save both keys to avoid breaking any screen that uses either
      'title': name.trim(),
      'name': name.trim(),

      'category': category.trim(),
      'warmthLevel': _normalizeWarmth(warmthLevel),
      'price': price,
      'imageUrl': imageUrl,

      'sellerId': user.uid,

      // ✅ Added: availability fields (so sold items can be hidden)
      'isAvailable': true,
      'status': 'active',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // -------------------------
  // 2) Create Order
  // -------------------------
  /// Creates an order record under users/{uid}/orders/{orderId}
  /// and writes the order items into users/{uid}/orders/{orderId}/items.
  /// ✅ Restored behavior:
  /// - Marks marketplace listing as sold/unavailable (so it disappears from browse)
  /// - Adds item into buyer wardrobe
  /// Clears cart after success.
  static Future<String?> createOrder({
    required List<MarketplaceListing> items,
    required double subtotalAmount,
    required String paymentRef,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final fee = subtotalAmount * 0.05;
    final total = subtotalAmount + fee;

    try {
      // 1) Create order doc
      final orderRef = await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .add({
        'userId': uid,
        'subtotalAmount': subtotalAmount,
        'platformFeeRate': 0.05,
        'platformFee': fee,
        'totalAmount': total,
        'paymentRef': paymentRef,
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2) Add order items + fulfill purchase (batch)
      final batch = _db.batch();

      for (final it in items) {
        // 2.1) Order item record
        final itemRef = orderRef.collection('items').doc(it.id);
        batch.set(itemRef, {
          'listingId': it.id,

          // Keep compatibility
          'title': it.title,
          'name': it.title,

          'category': it.category,
          'warmthLevel': _normalizeWarmth(it.warmthLevel),
          'price': it.price,
          'imageUrl': it.imageUrl,
          'sellerId': it.sellerId,

          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2.2) Mark listing sold/unavailable so it disappears from browse
        final listingRef = _db.collection('marketplace_listings').doc(it.id);
        batch.update(listingRef, {
          'isAvailable': false,
          'status': 'sold',
          'soldTo': uid,
          'soldAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2.3) Add to buyer wardrobe (restore old behavior)
        //
        // IMPORTANT:
        // If your wardrobe collection name is different, change ONLY this line:
        // .collection('wardrobe_items')
        final wardrobeRef =
            _db.collection('users').doc(uid).collection('wardrobe_items').doc(it.id);

        batch.set(
          wardrobeRef,
          {
            'name': it.title,
            'title': it.title,
            'category': it.category,
            'warmthLevel': _normalizeWarmth(it.warmthLevel),
            'imageUrl': it.imageUrl,

            // RESTORE PURCHASE BADGE SUPPORT
            'purchased': true,
            'isPurchased': true,
            'purchaseStatus': 'purchased',

            'source': 'marketplace',
            'listingId': it.id,
            'sellerId': it.sellerId,
            'boughtAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

      }

      await batch.commit();

      // 3) Clear cart
      await CartService.clearCart();

      return orderRef.id;
    } catch (_) {
      return null;
    }
  }
}
