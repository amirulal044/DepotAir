import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/order_repository.dart';
import 'order_form_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('Belum ada transaksi.'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      // Menampilkan nama pelanggan di judul
                      title: Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Menampilkan daftar produk yang dibeli di sub-judul
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateFormat.format(order.createdAt)),
                          const SizedBox(height: 4),
                          // Menggabungkan nama semua produk yang dibeli menjadi satu baris teks
                          Text(
                            order.items
                                .map(
                                  (item) =>
                                      '${item.productName} (${item.qty}x)',
                                )
                                .join(', '),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        currencyFormat.format(order.totalHarga),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),
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
