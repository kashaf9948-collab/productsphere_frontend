import 'package:get/get.dart';
import '../../../core/widgets/snackbars.dart';

class CartController extends GetxController {
  // Cart items: Map of { productId: { 'product': productMap, 'quantity': qty } }
  var cartItems = <int, Map<String, dynamic>>{}.obs;

  void addToCart(Map<String, dynamic> product) {
    final id = product['id'] as int;
    if (cartItems.containsKey(id)) {
      final currentQty = cartItems[id]!['quantity'] as int;
      final maxQty = product['quantity'] as int? ?? 999;
      if (currentQty < maxQty) {
        cartItems[id]!['quantity'] = currentQty + 1;
        cartItems.refresh();
      } else {
        AppSnackbars.warning(
          title: "Limit Reached",
          message: "Cannot add more than available stock quantity.",
        );
      }
    } else {
      cartItems[id] = {
        'product': product,
        'quantity': 1,
      };
    }
  }

  void removeFromCart(int id) {
    cartItems.remove(id);
  }

  void decrementQuantity(int id) {
    if (cartItems.containsKey(id)) {
      final currentQty = cartItems[id]!['quantity'] as int;
      if (currentQty > 1) {
        cartItems[id]!['quantity'] = currentQty - 1;
        cartItems.refresh();
      } else {
        cartItems.remove(id);
      }
    }
  }

  void clearCart() {
    cartItems.clear();
  }

  double get totalAmount {
    double total = 0.0;
    cartItems.forEach((id, item) {
      final product = item['product'] as Map<String, dynamic>;
      final qty = item['quantity'] as int;
      final price = double.tryParse(product['price'].toString()) ?? 0.0;
      total += price * qty;
    });
    return total;
  }

  int get totalCount {
    int count = 0;
    cartItems.forEach((id, item) {
      count += item['quantity'] as int;
    });
    return count;
  }
}