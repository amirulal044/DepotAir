import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/domain/product_model.dart';
import '../domain/cart_item_model.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  // 1. Fungsi menambah barang ke dalam keranjang
  void tambahKeKeranjang({
    required Product product,
    required int qty,
    required bool isAntar,
    required bool isBagiHasil,
    required bool isPakaiKupon,
  }) {
    final newItem = CartItem(
      product: product,
      qty: qty,
      isAntar: isAntar,
      isBagiHasil: isBagiHasil,
      isPakaiKupon: isPakaiKupon,
    );

    state = [...state, newItem];
  }

  // 2. Fungsi menghapus barang dari keranjang berdasarkan urutannya (index)
  void hapusDariKeranjang(int index) {
    final listSementara = List<CartItem>.from(state);
    listSementara.removeAt(index);
    state = listSementara;
  }

  // 3. Fungsi mengosongkan keranjang belanja setelah transaksi selesai
  void bersihkanKeranjang() {
    state = [];
  }
}

// Provider ini yang akan kita panggil di UI untuk memantau isi keranjang
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
