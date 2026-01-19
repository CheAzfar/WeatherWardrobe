class MarketplaceListing {
  final String id;
  final String name;
  final String category;
  final String warmthLevel;
  final String? imagePath;
  final double price;
  final String sellerId;
  final String sellerEmail;
  final DateTime createdAt;

  MarketplaceListing({
    required this.id,
    required this.name,
    required this.category,
    required this.warmthLevel,
    this.imagePath,
    required this.price,
    required this.sellerId,
    required this.sellerEmail,
    required this.createdAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'warmthLevel': warmthLevel,
      'imagePath': imagePath,
      'price': price,
      'sellerId': sellerId,
      'sellerEmail': sellerEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore
  factory MarketplaceListing.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return MarketplaceListing(
      id: docId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      warmthLevel: data['warmthLevel'] ?? '',
      imagePath: data['imagePath'],
      price: (data['price'] ?? 0).toDouble(),
      sellerId: data['sellerId'] ?? '',
      sellerEmail: data['sellerEmail'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }
}
