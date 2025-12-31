import '../models/shop_item.dart';

class ShopService {
  static List<ShopItem> getItemsByCategory(String category) {
    // Mock affiliate products
    return [
      ShopItem(
        name: '$category Lightweight Jacket',
        category: category,
        price: 89.90,
        store: 'Zalora',
        url: 'https://www.zalora.com.my',
      ),
      ShopItem(
        name: '$category Casual Wear',
        category: category,
        price: 59.90,
        store: 'Shopee',
        url: 'https://shopee.com.my',
      ),
      ShopItem(
        name: '$category Premium Style',
        category: category,
        price: 129.90,
        store: 'Uniqlo',
        url: 'https://www.uniqlo.com/my',
      ),
    ];
  }
}
