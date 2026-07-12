import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportPeriodSummaryCard extends StatelessWidget {
  final String activeFilterType;
  final int totalToko;
  final int totalDriver;
  final int totalIsi;
  final int totalSistem;

  const ReportPeriodSummaryCard({
    super.key,
    required this.activeFilterType,
    required this.totalToko,
    required this.totalDriver,
    required this.totalIsi,
    required this.totalSistem,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOTAL REKAPITULASI PERIODE (${activeFilterType.toUpperCase()})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(color: Colors.blue),
            _buildSummaryRow(
              '• Total Bersih Toko:',
              currencyFormat.format(totalToko),
            ),
            _buildSummaryRow(
              '• Total Gaji Driver:',
              currencyFormat.format(totalDriver),
              color: Colors.green.shade800,
            ),
            _buildSummaryRow(
              '• Total Bagi Hasil:',
              currencyFormat.format(totalIsi),
              color: Colors.orange.shade900,
            ),
            const Divider(color: Colors.blue),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Kotor Periode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(totalSistem),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey.shade700,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
