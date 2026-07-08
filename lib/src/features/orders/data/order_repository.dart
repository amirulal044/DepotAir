import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_model.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  // 1. Fungsi Ambil Riwayat Transaksi (dengan JOIN tabel pelanggan dan produk)
  Future<List<Order>> fetchOrders() async {
    final response = await _supabase
        .from('orders')
        .select('*, pelanggan(nama), produk(nama_produk)')
        .order('created_at', ascending: false);

    return response.map((data) => Order.fromJson(data)).toList();
  }

  // 2. FUNGSI INTI: Simpan Transaksi dengan Logika Bisnis
  Future<void> createOrder({
    required String customerId,
    required String productId,
    required int productPrice,
    required String productSize,
    required int qty,
    required bool isAntar,
    required bool isBagiHasil,
    required bool isPakaiKupon,
  }) async {
    // A. Hitung Harga Dasar
    int currentPrice = isPakaiKupon ? 0 : productPrice;

    // B. Hitung Biaya Antar (1.000 per galon jika diantar)
    int biayaAntar = isAntar ? (qty * 1000) : 0;

    // C. Hitung Total Akhir
    int totalHarga = (currentPrice * qty) + biayaAntar;

    // D. Simpan ke Tabel Orders
    await _supabase.from('orders').insert({
      'customer_id': customerId,
      'product_id': productId,
      'qty': qty,
      'is_antar': isAntar,
      'biaya_antar': biayaAntar,
      'is_bagi_hasil': isBagiHasil,
      'total_harga': totalHarga,
      'is_pakai_kupon': isPakaiKupon,
    });

    // // E. Logika Update Kupon Pelanggan
    // if (isPakaiKupon) {
    //   // Jika pakai kupon, kurangi 10 kupon pelanggan
    //   await _supabase.rpc(
    //     'increment_kupon',
    //     params: {'row_id': customerId, 'amount': -10},
    //   );
    // } else if (productSize == "19 Liter") {
    //   // Jika beli galon 19L biasa, tambah kupon sebanyak qty
    //   await _supabase.rpc(
    //     'increment_kupon',
    //     params: {'row_id': customerId, 'amount': qty},
    //   );
    // }
  }
}

// Provider untuk digunakan di UI
final orderRepositoryProvider = Provider((ref) => OrderRepository());
final ordersListProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchOrders();
});
