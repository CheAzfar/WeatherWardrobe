import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<MarketplaceListing> cartItems;
  final double subtotalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processing = false;
  double get _fee => widget.subtotalAmount * 0.05;
  double get _finalTotal => widget.subtotalAmount + _fee;

  static const String stripeBackendUrl = 'https://createpaymentintent-g3f5ehvnnq-uc.a.run.app';

  // --- Payment Logic (Kept same, just UI updated) ---
  Future<String?> _payWithStripe() async {
    if (stripeBackendUrl.trim().isEmpty) return null;
    final resp = await http.post(
      Uri.parse(stripeBackendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': (_finalTotal * 100).round(), 'currency': 'myr'}),
    );
    if (resp.statusCode >= 300) throw Exception('Stripe error');
    
    final data = jsonDecode(resp.body);
    final clientSecret = data['clientSecret'];
    
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Weather Wardrobe',
        style: ThemeMode.light,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    return data['paymentIntentId'];
  }

  Future<void> _confirmAndPay() async {
    setState(() => _processing = true);
    try {
      String paymentRef;
      try {
        final stripeId = await _payWithStripe();
        paymentRef = stripeId ?? 'test_${DateTime.now().millisecondsSinceEpoch}';
      } catch (e) {
        // Fallback for demo if Stripe fails/not setup
        await Future.delayed(const Duration(seconds: 1));
        paymentRef = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      }

      final orderId = await MarketplaceService.createOrder(
        items: widget.cartItems,
        subtotalAmount: widget.subtotalAmount,
        paymentRef: paymentRef,
      );

      if (!mounted) return;
      if (orderId == null) throw Exception("Order creation failed");

      _showSuccessDialog(orderId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Payment Successful!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Text("Order #${orderId.substring(0, 6).toUpperCase()}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close checkout
              Navigator.pop(context); // Close cart
            },
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Order Summary"),
                  const SizedBox(height: 10),
                  ...widget.cartItems.map((item) => _orderItem(item)).toList(),
                  
                  const SizedBox(height: 30),
                  _sectionTitle("Payment Method"),
                  const SizedBox(height: 10),
                  _paymentMethodCard(),

                  const SizedBox(height: 30),
                  _sectionTitle("Bill Details"),
                  const SizedBox(height: 10),
                  _billDetailsCard(),
                ],
              ),
            ),
          ),
          _payButton(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _orderItem(MarketplaceListing item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${item.size} • ${item.warmthLevel}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text("RM ${item.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _paymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.credit_card, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Credit / Debit Card", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("via Stripe Payment", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color.fromARGB(255, 46, 125, 50)),
        ],
      ),
    );
  }

  Widget _billDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _billRow("Subtotal", widget.subtotalAmount),
          const SizedBox(height: 10),
          _billRow("Platform Fee (5%)", _fee),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("RM ${_finalTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text("RM ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _payButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: _processing ? null : _confirmAndPay,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 46, 125, 50), // Sleek black button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _processing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
            : Text("Pay RM ${_finalTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}