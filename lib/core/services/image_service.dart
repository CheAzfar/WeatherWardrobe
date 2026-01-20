import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  ImageService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<String> uploadWardrobeImage({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final ext = fileExt.toLowerCase();
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? "jpg" : ext}';
    final ref = _storage.ref().child('wardrobe_images/$fileName');

    final metadata = SettableMetadata(contentType: _contentTypeFromExt(ext));
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  Future<void> createWardrobeItem({
    required String name,
    required String category,
    required String warmthLevel,
    required String imageUrl,
  }) async {
    await _firestore.collection('wardrobe_items').add({
      'name': name,
      'category': category,
      'warmthLevel': warmthLevel,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWardrobeItem({
    required String docId,
    required String name,
    required String category,
    required String warmthLevel,
    String? imageUrl, // only update when provided
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'category': category,
      'warmthLevel': warmthLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }

    await _firestore.collection('wardrobe_items').doc(docId).update(data);
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
