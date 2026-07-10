import '../../products/domain/product_model.dart';

class CartItem {
  final Product product;
  final int qty;
  final bool isAntar;
  final bool isBagiHasil;
  final bool isPakaiKupon;

  CartItem({
    required this.product,
    required this.qty,
    required this.isAntar,
    required this.isBagiHasil,
    required this.isPakaiKupon,
  });

  // Fungsi otomatis untuk menghitung subtotal harga dari item ini saja
  int get subtotal {
    final hargaDasar = isPakaiKupon ? 0 : product.harga;
    final biayaAntar = isAntar ? (qty * 1000) : 0;
    return (hargaDasar * qty) + biayaAntar;
  }
}
