import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    try {
      debugPrint('🔄 [DEBUG] Memulai pengambilan data Produk...');

      final response = await _supabase
          .from('produk')
          .select()
          .order('nama_produk');

      final list = response.map((data) => Product.fromJson(data)).toList();

      debugPrint('=========================================');
      debugPrint('✅ [DEBUG] DATA PRODUK BERHASIL DIMUAT');
      debugPrint('📦 Jumlah Data: ${list.length}');
      if (list.isNotEmpty) {
        debugPrint(
          '💧 Sampel Produk: ${list.first.namaProduk} (${list.first.ukuran})',
        );
      }
      debugPrint('=========================================');

      return list;
    } catch (e, stacktrace) {
      debugPrint('❌ [DEBUG] GAGAL MEMUAT PRODUK!');
      debugPrint('⚠️ Error: $e');
      rethrow;
    }
  }

  Future<void> addProduct(String nama, int harga, String ukuran) async {
    await _supabase.from('produk').insert({
      'nama_produk': nama,
      'harga': harga,
      'ukuran': ukuran, // Simpan ukuran sebagai text
    });
  }

  Future<void> updateProduct(
    String id,
    String nama,
    int harga,
    String ukuran,
  ) async {
    await _supabase
        .from('produk')
        .update({'nama_produk': nama, 'harga': harga, 'ukuran': ukuran})
        .eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('produk').delete().eq('id', id);
  }
}

final productRepositoryProvider = Provider((ref) => ProductRepository());
final productsListProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchProducts();
});
