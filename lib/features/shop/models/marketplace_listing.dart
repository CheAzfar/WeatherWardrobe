import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceListing {
  final String id;
  final String title;
  final String category;     // Tops / Bottoms / Outerwear / Shoes
  final String warmthLevel;  // Light / Medium / Heavy
  final double price;
  final String imageUrl;
  final String sellerId;
  final DateTime createdAt;

  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.category,
    required this.warmthLevel,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.createdAt,
  });

  static MarketplaceListing fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    String normWarmth(String v) {
      final lower = v.trim().toLowerCase();
      if (lower == 'warm') return 'Heavy'; // backward compatibility
      if (lower == 'heavy') return 'Heavy';
      if (lower == 'medium') return 'Medium';
      if (lower == 'light') return 'Light';
      return v;
    }

    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawPrice = data['price'];
    final price = rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice') ?? 0.0;

    return MarketplaceListing(
      id: d.id,
      title: (data['title'] ?? data['name'] ?? '').toString(),
      category: (data['category'] ?? 'All').toString(),
      warmthLevel: normWarmth((data['warmthLevel'] ?? data['warmth'] ?? 'Light').toString()),
      price: price,
      imageUrl: (data['imageUrl'] ?? '').toString(),
      sellerId: (data['sellerId'] ?? '').toString(),
      createdAt: toDate(data['createdAt']),
    );
  }
}
