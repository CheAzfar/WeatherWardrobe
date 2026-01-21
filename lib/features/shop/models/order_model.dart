import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime date;
  final int itemCount;

  OrderModel({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.date,
    required this.itemCount,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Processing',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // --- FIX IS HERE ---
      // 1. Try reading the new 'itemsCount' number we save.
      // 2. If that doesn't exist (old orders), try counting the 'items' array.
      // 3. If neither exists, default to 0.
      itemCount: (data['itemsCount'] as num?)?.toInt() ?? (data['items'] as List?)?.length ?? 0,
    );
  }
}