import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_model.dart';
import '../domain/cart_item_model.dart'; // <--- Pastikan import model keranjang belanja ini ada

class OrderRepository {
  final _supabase = Supabase.instance.client;

  // 1. Fungsi Mengambil Riwayat Transaksi (Hanya mengambil yang BELUM tutup buku)
  Future<List<Order>> fetchOrders() async {
    final response = await _supabase
        .from('orders')
        .select(
          '*, pelanggan(nama), order_items(*, produk(nama_produk, ukuran))',
        )
        .isFilter(
          'daily_report_id',
          null,
        ) // <--- TAMBAHKAN BARIS INI (Filter reset otomatis)
        .order('created_at', ascending: false);

    return response.map((data) => Order.fromJson(data)).toList();
  }

  // 2. FUNGSI UTAMA: Menyimpan banyak pesanan sekaligus (Batch Insert) dengan pembagian bagi hasil
  Future<void> createBulkOrders({
    required String customerId,
    required List<CartItem> cartItems,
    required int totalBayar,
  }) async {
    // A. Simpan data transaksi utama ke tabel induk 'orders'
    final response = await _supabase
        .from('orders')
        .insert({'customer_id': customerId, 'total_bayar': totalBayar})
        .select('id')
        .single();

    final String orderId =
        response['id']; // Ambil ID transaksi induk yang baru saja dibuat

    // B. Siapkan rincian barang belanjaan beserta pembagian porsi uangnya
    final List<Map<String, dynamic>> itemsToInsert = cartItems.map((item) {
      // 1. Hitung harga air (jika pakai kupon gratis, harga air dihitung 0)
      final int hargaDasar = item.isPakaiKupon ? 0 : item.product.harga;

      // 2. Hitung biaya antar total (Rp 1.000 per galon jika diantar)
      final int biayaAntarTotal = item.isAntar ? (item.qty * 1000) : 0;

      // 3. Hitung subtotal harga yang harus dibayar pembeli (harga air + biaya antar)
      final int subtotalHarga = (hargaDasar * item.qty) + biayaAntarTotal;

      // ------------------------------------------
      // LOGIKA PEMBAGIAN PORSI UANG (PLOTING BIAYA)
      // ------------------------------------------
      int pemasukanTokoPerItem = 0;
      int komisiAntarPerItem = 0;
      int komisiIsiPerItem = 0;

      // > Porsi Karyawan Antar (Tetap dapat Rp 1.000/galon jika diantar, meskipun airnya gratis pakai kupon)
      if (item.isAntar) {
        komisiAntarPerItem = item.qty * 1000;
      }

      // > Porsi Karyawan Pengisi (Hanya dapat bagi hasil 10% jika beli di tempat, pakai bagi hasil, produk 19L, dan BUKAN pakai kupon)
      if (!item.isPakaiKupon &&
          !item.isAntar &&
          item.isBagiHasil &&
          item.product.ukuran == "19 Liter") {
        komisiIsiPerItem =
            (hargaDasar * 0.1).round() *
            item.qty; // 10% dari harga dasar (misal Rp 500 per galon)
      }

      // > Porsi Toko (Sisa uang setelah dipotong hak karyawan antar dan pengisi)
      pemasukanTokoPerItem =
          subtotalHarga - komisiAntarPerItem - komisiIsiPerItem;

      // Masukkan hasil pemetaan data ke dalam format JSON Supabase
      return {
        'order_id': orderId,
        'product_id': item.product.id,
        'qty': item.qty,
        'is_antar': item.isAntar,
        'biaya_antar': biayaAntarTotal,
        'is_bagi_hasil': item.isBagiHasil,
        'is_pakai_kupon': item.isPakaiKupon,
        'subtotal_harga': subtotalHarga,

        // Simpan nilai pembagian porsi keuangan ke kolom database yang baru kita buat
        'pemasukan_toko': pemasukanTokoPerItem,
        'komisi_antar': komisiAntarPerItem,
        'komisi_isi': komisiIsiPerItem,
      };
    }).toList();

    // C. Simpan semua rincian belanja ke tabel anak 'order_items'
    await _supabase.from('order_items').insert(itemsToInsert);
  }
}

// Provider untuk digunakan di UI
final orderRepositoryProvider = Provider((ref) => OrderRepository());
final ordersListProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchOrders();
});
