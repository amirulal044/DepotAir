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

          // KUNCI EFISIENSI: Satukan kartu akumulasi ke dalam satu ListView
          return ListView.builder(
            // Jumlah item ditambah 1 untuk menaruh kartu akumulasi di paling atas
            itemCount: orders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // 1. Tampilkan kartu akumulasi di indeks ke-0 (paling atas)
                return OrderAccumulationCard(orders: orders);
              }

              // 2. Tampilkan baris pesanan di bawahnya (indeks digeser mundur 1)
              final order = orders[index - 1];
              return OrderListItem(order: order);
            },
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
