import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderAccumulationCard extends StatelessWidget {
  final int totalGalon;
  final int totalToko;
  final int totalDriver;
  final int totalBagiHasil;
  final int totalKotor;

  const OrderAccumulationCard({
    super.key,
    required this.totalGalon,
    required this.totalToko,
    required this.totalDriver,
    required this.totalBagiHasil,
    required this.totalKotor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AKUMULASI RIWAYAT TRANSAKSI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(color: Colors.blue),
            _buildSummaryRow(
              '• Total Galon Terjual:',
              '$totalGalon Galon',
              color: Colors.blue.shade900,
            ),
            const SizedBox(height: 4),
            _buildSummaryRow(
              '• Total Bersih Toko:',
              currencyFormat.format(totalToko),
            ),
            const SizedBox(height: 4),
            _buildSummaryRow(
              '• Total Gaji Driver:',
              currencyFormat.format(totalDriver),
              color: Colors.green.shade800,
            ),
            const SizedBox(height: 4),
            _buildSummaryRow(
              '• Total Bagi Hasil:',
              currencyFormat.format(totalBagiHasil),
              color: Colors.orange.shade900,
            ),
            const Divider(color: Colors.blue),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Kotor Keseluruhan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  currencyFormat.format(totalKotor),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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

  // Widget helper privat untuk merapikan tiap baris informasi data
  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
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
    );
  }
}
