import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDiscrepancyCard extends StatelessWidget {
  final int selisih;

  const ReportDiscrepancyCard({super.key, required this.selisih});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selisih == 0
            ? Colors.green.shade50
            : (selisih < 0 ? Colors.red.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selisih == 0
              ? Colors.green.shade200
              : (selisih < 0 ? Colors.red.shade200 : Colors.blue.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Status Selisih:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            selisih == 0
                ? 'PAS (Cocok)'
                : (selisih < 0
                      ? 'Kurang ${currencyFormat.format(selisih.abs())}'
                      : 'Lebih ${currencyFormat.format(selisih)}'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: selisih == 0
                  ? Colors.green.shade800
                  : (selisih < 0 ? Colors.red.shade800 : Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
