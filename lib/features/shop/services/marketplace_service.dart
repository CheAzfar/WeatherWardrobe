import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/marketplace_listing.dart';

class MarketplaceService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  /// Create listing (Firestore only)
  /// NOTE: imageUrl is required (Cloudinary URL), not local path.
  static Future<String?> createListing({
    required String name,
    required String category,
    required String warmthLevel,
    required double price,
    required String imageUrl,
  }) async {
    try {
      final userId = currentUserId;
      final userEmail = currentUserEmail;
      if (userId == null || userEmail == null) return null;

      final listing = MarketplaceListing(
        id: '',
        name: name,
        category: category,
        warmthLevel: warmthLevel,
        imageUrl: imageUrl,
        price: price,
        sellerId: userId,
        sellerEmail: userEmail,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('listings').add(listing.toFirestore());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating listing: $e');
      return null;
    }
  }

  /// Get all listings excluding user's own
  static Stream<List<MarketplaceListing>> getAllListings() {
    final userId = currentUserId ?? '';

    return _firestore
        .collection('listings')
        .where('sellerId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MarketplaceListing.fromDoc(doc);
      }).toList();
    });
  }

  /// Get current user's listings
  static Stream<List<MarketplaceListing>> getMyListings() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MarketplaceListing.fromDoc(doc);
      }).toList();
    });
  }

  /// Delete listing
  static Future<bool> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting listing: $e');
      return false;
    }
  }

  /// Create order + move purchased items into Wardrobe (Firestore-only)
  ///
  /// Backward-compatible parameters:
  /// - New: subtotalAmount + paymentRef
  /// - Old: totalAmount + paymentToken
  ///
  /// Behavior:
  /// 1) create order doc in /orders
  /// 2) add each purchased item into /users/{uid}/wardrobe_items
  /// 3) delete purchased listings from /listings
  static Future<String?> createOrder({
    required List<MarketplaceListing> items,

    // NEW style (recommended)
    double? subtotalAmount,
    String? paymentRef,

    // OLD style (supported)
    double? totalAmount,
    String? paymentToken,
  }) async {
    try {
      final userId = currentUserId;
      final userEmail = currentUserEmail;
      if (userId == null || userEmail == null) return null;

      // Determine amounts
      final double subtotal = subtotalAmount ?? totalAmount ?? 0.0;
      final double commission = subtotal * 0.05;
      final double finalTotal = subtotal + commission;

      final String payRef = paymentRef ?? paymentToken ?? 'unknown_payment';

      // 1) Create order
      final orderData = {
        'buyerId': userId,
        'buyerEmail': userEmail,
        'items': items.map((item) {
          return {
            'listingId': item.id,
            'name': item.name,
            'category': item.category,
            'warmthLevel': item.warmthLevel,
            'price': item.price,
            'imageUrl': item.imageUrl,
            'sellerId': item.sellerId,
            'sellerEmail': item.sellerEmail,
          };
        }).toList(),
        'subtotal': subtotal,
        'commission': commission,
        'totalAmount': finalTotal,
        'paymentRef': payRef,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final orderDoc = await _firestore.collection('orders').add(orderData);

      // 2) Batch: add to wardrobe + delete listings
      final wardrobeCol =
          _firestore.collection('users').doc(userId).collection('wardrobe_items');

      final batch = _firestore.batch();

      for (final item in items) {
        // Put item into wardrobe
        batch.set(wardrobeCol.doc(), {
          'name': item.name,
          'category': item.category,
          'warmthLevel': item.warmthLevel,
          'imageUrl': item.imageUrl,
          'price': item.price,
          'source': 'purchase',
          'sourceListingId': item.id,
          'sourceOrderId': orderDoc.id,

          // ✅ Wardrobe screens orderBy(createdAt)
          'createdAt': FieldValue.serverTimestamp(),

          // Optional
          'purchasedAt': FieldValue.serverTimestamp(),
        });

        // Delete the listing
        batch.delete(_firestore.collection('listings').doc(item.id));
      }

      await batch.commit();
      return orderDoc.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating order: $e');
      return null;
    }
  }

  /// User's orders
  static Stream<List<Map<String, dynamic>>> getMyOrders() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
