import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_listing.dart';

class MarketplaceService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  // Create listing
  static Future<String?> createListing({
    required String name,
    required String category,
    required String warmthLevel,
    required double price,
    String? imagePath,
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
        imagePath: imagePath,
        price: price,
        sellerId: userId,
        sellerEmail: userEmail,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('listings')
          .add(listing.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating listing: $e');
      return null;
    }
  }

  // Get all listings (excluding user's own)
  static Stream<List<MarketplaceListing>> getAllListings() {
    final userId = currentUserId;

    return _firestore
        .collection('listings')
        .where('sellerId', isNotEqualTo: userId ?? '')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MarketplaceListing.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get user's own listings
  static Stream<List<MarketplaceListing>> getMyListings() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MarketplaceListing.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Delete listing
  static Future<bool> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
      return true;
    } catch (e) {
      print('Error deleting listing: $e');
      return false;
    }
  }

  // Create order
  static Future<String?> createOrder({
    required List<MarketplaceListing> items,
    required double totalAmount,
    required String paymentToken,
  }) async {
    try {
      final userId = currentUserId;
      final userEmail = currentUserEmail;
      if (userId == null || userEmail == null) return null;

      final orderData = {
        'buyerId': userId,
        'buyerEmail': userEmail,
        'items': items
            .map(
              (item) => {
                'listingId': item.id,
                'name': item.name,
                'price': item.price,
                'sellerId': item.sellerId,
                'sellerEmail': item.sellerEmail,
              },
            )
            .toList(),
        'totalAmount': totalAmount,
        'commission': totalAmount * 0.05, // 5% commission
        'paymentToken': paymentToken,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);

      // Delete purchased listings
      for (var item in items) {
        await deleteListing(item.id);
      }

      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Get user's orders
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
