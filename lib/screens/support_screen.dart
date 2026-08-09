import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _productIds = {
    'support_coffee',
    'support_update',
    'support_super',
  };

  final _inAppPurchase = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = const [];
  bool _loading = true;
  bool _storeAvailable = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchases,
      onError: (_) => _showMessage('付款服務暫時無法使用'),
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _storeAvailable = false;
          _loading = false;
          _message = '目前無法連接商店，請稍後再試';
        });
      }
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(_productIds);
    if (!mounted) return;
    final products = [...response.productDetails]
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    setState(() {
      _storeAvailable = true;
      _products = products;
      _loading = false;
      _message = response.error?.message ??
          (products.isEmpty ? '支持方案尚未在商店啟用' : null);
    });
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _showMessage('謝謝你的支持！');
      } else if (purchase.status == PurchaseStatus.error) {
        _showMessage(purchase.error?.message ?? '付款沒有完成');
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(ProductDetails product) async {
    await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
  }

  String _titleFor(String id) {
    return switch (id) {
      'support_coffee' => '請我喝杯咖啡',
      'support_update' => '支持持續更新',
      'support_super' => '大力支持',
      _ => '支持開發',
    };
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('支持開發')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 56,
            color: Color(0xFFE25578),
          ),
          const SizedBox(height: 16),
          Text(
            '讓 Word Speaker 持續進步',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            '查字、翻譯與發音功能永遠不會因為沒有贊助而受限。'
            '如果這個 App 對你有幫助，可以自願支持後續維護。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            for (final product in _products)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.volunteer_activism_rounded),
                  title: Text(_titleFor(product.id)),
                  subtitle: Text(product.description),
                  trailing: FilledButton(
                    onPressed: () => _buy(product),
                    child: Text(product.price),
                  ),
                ),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (!_storeAvailable)
              OutlinedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新載入'),
              ),
          ],
          const SizedBox(height: 24),
          Text(
            '付款由 Apple App Store 或 Google Play 安全處理。'
            '這些方案屬於一次性自願支持，不會解鎖額外數位功能。',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
