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
      // FIX 1: Map 'createdAt' (from service) to 'date'
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // FIX 2: Count the items in the list
      itemCount: (data['items'] as List?)?.length ?? 0,
    );
  }
}
