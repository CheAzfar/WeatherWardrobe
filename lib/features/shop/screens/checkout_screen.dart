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

  /// IMPORTANT:
  /// Stripe PaymentIntent must be created on a backend (Cloud Function / server).
  /// Put your endpoint here when ready.
  ///
  /// Expected response JSON:
  /// { "clientSecret": "...", "paymentIntentId": "pi_..." }
  static const String stripeBackendUrl = 'https://createpaymentintent-g3f5ehvnnq-uc.a.run.app';

  Future<String?> _payWithStripe() async {
    if (stripeBackendUrl.trim().isEmpty) return null;

    final resp = await http.post(
      Uri.parse(stripeBackendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (_finalTotal * 100).round(), // cents
        'currency': 'myr',
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Stripe backend error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final clientSecret = (data['clientSecret'] ?? '').toString();
    final paymentIntentId = (data['paymentIntentId'] ?? '').toString();

    if (clientSecret.isEmpty || paymentIntentId.isEmpty) {
      throw Exception('Invalid Stripe backend response (missing clientSecret/paymentIntentId)');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Weather Wardrobe',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return paymentIntentId;
  }

  Future<void> _confirmAndPay() async {
    if (widget.cartItems.isEmpty) return;

    setState(() => _processing = true);

    try {
      // 1) Try Stripe (if backend configured)
      String paymentRef;
      final stripeIntentId = await _payWithStripe();

      if (stripeIntentId != null) {
        paymentRef = stripeIntentId;
      } else {
        // 2) Fallback: dev/test payment to keep app usable before backend is ready
        await Future.delayed(const Duration(seconds: 1));
        paymentRef = 'test_${DateTime.now().millisecondsSinceEpoch}';
      }

      // 3) Create order in Firestore + move items into Wardrobe (handled in MarketplaceService)
      final orderId = await MarketplaceService.createOrder(
        items: widget.cartItems,
        subtotalAmount: widget.subtotalAmount,
        paymentRef: paymentRef,
      );

      if (!mounted) return;

      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order creation failed. Please try again.')),
        );
        return;
      }

      // 4) Success UI
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 12),
              Text('Order ID: ${orderId.substring(0, 8)}'),
              const SizedBox(height: 6),
              Text('Total: RM ${_finalTotal.toStringAsFixed(2)}'),
              if (stripeBackendUrl.trim().isEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  '(Stripe backend not set yet — using test payment)',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Pop Checkout -> Cart -> Shop (or wherever you came from)
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _thumb(item.imageUrl),
                        ),
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${item.category} • ${item.warmthLevel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _summaryCard(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _confirmAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Pay RM ${_finalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Subtotal', 'RM ${widget.subtotalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _row('Platform Fee (5%)', 'RM ${_fee.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _row(
            'Total',
            'RM ${_finalTotal.toStringAsFixed(2)}',
            bold: true,
            green: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false, bool green = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
        Text(
          right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            color: green ? AppColors.primaryGreen : null,
          ),
        ),
      ],
    );
  }

  Widget _thumb(String url) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.softGreen.withValues(alpha: 0.6),
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.primaryGreen),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.softGreen.withValues(alpha: 0.6),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.primaryGreen),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.softGreen.withValues(alpha: 0.35),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
