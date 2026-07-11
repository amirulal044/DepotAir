import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/daily_report_model.dart';

class ReportHistoryItem extends StatelessWidget {
  final DailyReport report;

  const ReportHistoryItem({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(report.reportDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              'Pendapatan Toko:',
              currencyFormat.format(report.totalPemasukanToko),
            ),
            _buildInfoRow(
              'Komisi Driver:',
              currencyFormat.format(report.totalKomisiAntar),
            ),
            _buildInfoRow(
              'Komisi Pengisi:',
              currencyFormat.format(report.totalKomisiIsi),
            ),
            const Divider(),
            _buildInfoRow(
              'Uang Sistem:',
              currencyFormat.format(report.totalKotorSistem),
            ),
            _buildInfoRow(
              'Uang Fisik di Laci:',
              currencyFormat.format(report.totalKotorFisik),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selisih Uang:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(report.selisih),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: report.selisih == 0
                        ? Colors.green
                        : (report.selisih < 0 ? Colors.red : Colors.blue),
                  ),
                ),
              ],
            ),
            if (report.catatan != null) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: ${report.catatan}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
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
