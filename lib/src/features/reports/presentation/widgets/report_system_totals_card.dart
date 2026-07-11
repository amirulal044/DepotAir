import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportSystemTotalsCard extends StatelessWidget {
  final int totalToko;
  final int totalDriver;
  final int totalIsi;
  final int totalSistem;

  const ReportSystemTotalsCard({
    super.key,
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
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Pemasukan Toko:', currencyFormat.format(totalToko)),
            const Divider(),
            _buildInfoRow(
              'Komisi Driver (Antar):',
              currencyFormat.format(totalDriver),
            ),
            const Divider(),
            _buildInfoRow(
              'Komisi Pengisi (Bagi Hasil):',
              currencyFormat.format(totalIsi),
            ),
            const Divider(thickness: 1.5, color: Colors.blue),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Uang Sistem:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
