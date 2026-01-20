import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceListing {
  final String id; // Firestore docId

  final String name;
  final String category;
  final String warmthLevel;

  /// Must be a public URL (Cloudinary) so it works on all devices.
  final String imageUrl;

  final double price;

  final String sellerId;
  final String sellerEmail;

  final DateTime createdAt;

  const MarketplaceListing({
    required this.id,
    required this.name,
    required this.category,
    required this.warmthLevel,
    required this.imageUrl,
    required this.price,
    required this.sellerId,
    required this.sellerEmail,
    required this.createdAt,
  });

  /// Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'warmthLevel': warmthLevel,
      'imageUrl': imageUrl,
      'price': price,
      'sellerId': sellerId,
      'sellerEmail': sellerEmail,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Safe parsing from Firestore document
  factory MarketplaceListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return MarketplaceListing(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      warmthLevel: (data['warmthLevel'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      price: _toDouble(data['price']),
      sellerId: (data['sellerId'] ?? '').toString(),
      sellerEmail: (data['sellerEmail'] ?? '').toString(),
      createdAt: _toDate(data['createdAt']),
    );
  }

  MarketplaceListing copyWith({
    String? id,
    String? name,
    String? category,
    String? warmthLevel,
    String? imageUrl,
    double? price,
    String? sellerId,
    String? sellerEmail,
    DateTime? createdAt,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      warmthLevel: warmthLevel ?? this.warmthLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      sellerId: sellerId ?? this.sellerId,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
