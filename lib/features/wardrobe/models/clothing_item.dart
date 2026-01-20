import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for a wardrobe item.
/// Stored under: users/{uid}/wardrobe_items/{docId}
class ClothingItem {
  final String id; // Firestore docId
  final String name;
  final String category;
  final String warmthLevel;

  /// Use this for all devices (Cloudinary URL).
  final String? imageUrl;

  /// Legacy field from old Hive/local storage. Keep for now to reduce breakages.
  /// You will remove it later when all screens stop referencing it.
  @Deprecated('Use imageUrl instead. This was used for local device paths.')
  final String? imagePath;

  final DateTime? createdAt;   // manual add time
  final DateTime? purchasedAt; // purchase time (if from shop)

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.warmthLevel,
    this.imageUrl,
    this.imagePath,
    this.createdAt,
    this.purchasedAt,
  });

  /// For creating a new item before saving to Firestore
  factory ClothingItem.newItem({
    required String name,
    required String category,
    required String warmthLevel,
    String? imageUrl,
  }) {
    return ClothingItem(
      id: '',
      name: name,
      category: category,
      warmthLevel: warmthLevel,
      imageUrl: imageUrl,
      imagePath: null,
      createdAt: DateTime.now(),
      purchasedAt: null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'warmthLevel': warmthLevel,
      'imageUrl': imageUrl,
      // Keep legacy field to avoid crashing if something still writes it.
      'imagePath': imagePath,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      if (purchasedAt != null) 'purchasedAt': Timestamp.fromDate(purchasedAt!),
    };
  }

  factory ClothingItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? _tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ClothingItem(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      warmthLevel: (() {
        final v = (data['warmthLevel'] ?? '').toString();
        return v.toLowerCase() == 'warm' ? 'Heavy' : v;
      })(),
      imageUrl: (data['imageUrl'] == null) ? null : data['imageUrl'].toString(),
      imagePath: (data['imagePath'] == null) ? null : data['imagePath'].toString(),
      createdAt: _tsToDate(data['createdAt']),
      purchasedAt: _tsToDate(data['purchasedAt']),
    );
  }

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? warmthLevel,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    DateTime? purchasedAt,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      warmthLevel: warmthLevel ?? this.warmthLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }
}
