import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/order_model.dart'; // <--- Impor model dari folder domain
import '../order_detail_screen.dart'; // <--- Impor halaman detail

class OrderListItem extends StatelessWidget {
  final Order order;

  const OrderListItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(order.createdAt)),
            const SizedBox(height: 4),
            Text(
              order.items
                  .map(
                    (item) =>
                        '${item.productName}  ${item.productSize} (${item.qty}x)',
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
  }
}
