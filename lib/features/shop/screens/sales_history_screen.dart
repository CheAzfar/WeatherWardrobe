  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shop/models/marketplace_listing.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(title: const Text("My Sales")),
      body: StreamBuilder<QuerySnapshot>(
        // Query items listed by ME that are SOLD
        stream: FirebaseFirestore.instance
            .collection('marketplace_listings')
            .where('sellerId', isEqualTo: uid)
            .where('status', isEqualTo: 'sold')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Calculate Total
          double totalSales = 0;
          for (var doc in docs) {
            totalSales += (doc['price'] ?? 0);
          }

          return Column(
            children: [
              // Total Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))]
                ),
                child: Column(
                  children: [
                    const Text("Total Earnings", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      "RM ${totalSales.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text("${docs.length} items sold", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const Divider(),

              // Sales List
              Expanded(
                child: docs.isEmpty 
                  ? const Center(child: Text("No items sold yet."))
                  : ListView.builder(
                      itemCount: docs.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final date = (data['soldAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                              child: const Icon(Icons.attach_money, color: Colors.green),
                            ),
                            title: Text(data['title'] ?? 'Item'),
                            subtitle: Text("Sold on ${DateFormat('MMM dd, yyyy').format(date)}"),
                            trailing: Text(
                              "+ RM ${(data['price'] ?? 0).toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}