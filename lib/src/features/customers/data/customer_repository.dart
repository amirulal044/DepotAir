import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_model.dart';

class CustomerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Customer>> fetchCustomers() async {
    try {
      debugPrint('🔄 Memulai pengambilan data pelanggan...');

      final response = await _supabase.from('pelanggan').select().order('nama');

      final customers = (response as List)
          .map((json) => Customer.fromJson(json))
          .toList();

      debugPrint('✅ Berhasil memuat ${customers.length} pelanggan.');

      return customers;
    } catch (e, stackTrace) {
      debugPrint('❌ Gagal mengambil data pelanggan');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> addCustomer(String nama, String alamat, String nomorHp) async {
    await _supabase.from('pelanggan').insert({
      'nama': nama,
      'alamat': alamat,
      'nomor_hp': nomorHp,
    });
  }

  Future<void> updateCustomer(
    String id,
    String nama,
    String alamat,
    String nomorHp,
  ) async {
    await _supabase
        .from('pelanggan')
        .update({'nama': nama, 'alamat': alamat, 'nomor_hp': nomorHp})
        .eq('id', id);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase.from('pelanggan').delete().eq('id', id);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customersListProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.fetchCustomers();
});
