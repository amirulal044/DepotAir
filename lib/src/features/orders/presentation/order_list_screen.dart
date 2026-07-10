import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import 'order_form_screen.dart';
// Impor kedua widget baru yang baru saja kita pisahkan
import 'WidgetsList/order_accumulation_card.dart';
import 'WidgetsList/order_list_item.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Belum ada transaksi.'));
          }

          // ==========================================
          // LOGIKA HITUNG AKUMULASI DARI DATA ORDERS
          // ==========================================
          int totalPemasukanToko = 0;
          int totalKomisiAntar = 0;
          int totalKomisiIsi = 0;
          int totalKotorSistem = 0;
          int totalGalonTerjual = 0;

          for (var order in orders) {
            totalKotorSistem += order.totalHarga;
            for (var item in order.items) {
              totalPemasukanToko += item.pemasukanToko;
              totalKomisiAntar += item.komisiAntar;
              totalKomisiIsi += item.komisiIsi;
              totalGalonTerjual += item.qty;
            }
          }

          return Column(
            children: [
              // 1. KARTU RINGKASAN AKUMULASI (Memanggil Widget yang Dipisah)
              OrderAccumulationCard(
                totalGalon: totalGalonTerjual,
                totalToko: totalPemasukanToko,
                totalDriver: totalKomisiAntar,
                totalBagiHasil: totalKomisiIsi,
                totalKotor: totalKotorSistem,
              ),

              // 2. DAFTAR RIWAYAT TRANSAKSI (Memanggil List Item yang Dipisah)
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return OrderListItem(order: orders[index]);
                  },
                ),
              ),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderFormScreen()),
        ),
        label: const Text('Tambah Pesanan'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
