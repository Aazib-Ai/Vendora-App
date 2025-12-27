import 'package:vendora/models/product_model.dart';

class CartService {
  static final Map<String, int> items = {};

  static void addToCart(Product product, int qty) {
    items[product.id] = (items[product.id] ?? 0) + qty;
  }

  static void removeItem(String id) {
    items.remove(id);
  }

  static void updateQty(String id, int qty) {
    items[id] = qty;
  }
}
