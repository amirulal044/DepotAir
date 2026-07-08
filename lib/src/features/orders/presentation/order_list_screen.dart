import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/order_repository.dart';
import 'order_form_screen.dart';

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
                      title: Text(
                        '${order.customerName} - ${order.productName}',
                      ),
                      subtitle: Text(
                        '${dateFormat.format(order.createdAt)}\nQty: ${order.qty} galon',
                      ),
                      trailing: Text(
                        currencyFormat.format(order.totalHarga),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      isThreeLine: true,
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
