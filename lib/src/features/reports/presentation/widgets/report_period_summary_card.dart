import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../orders/domain/order_model.dart'; // <--- Impor model Order ditambahkan

class CombinedReportDetail {
  int qty = 0;
  int subtotal = 0;
  int toko = 0;
  int driver = 0;
  int bagiHasil = 0;
}

class ReportPeriodSummaryCard extends StatelessWidget {
  final String activeFilterType;
  final List<Order> periodOrders; // <--- UBAH: Menerima list orders periode

  const ReportPeriodSummaryCard({
    super.key,
    required this.activeFilterType,
    required this.periodOrders,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // ==========================================
    // LOGIKA PERHITUNGAN AKUMULASI TERPADU PERIODE (COMPOSITE GROUPING)
    // ==========================================
    int totalToko = 0;
    int totalDriver = 0;
    int totalBagiHasil = 0;
    int totalSistem = 0;
    int totalGalon = 0;

    final Map<String, CombinedReportDetail> rincianTerpadu = {};

    for (var order in periodOrders) {
      totalSistem += order.totalHarga;
      for (var item in order.items) {
        totalGalon += item.qty;
        totalToko += item.pemasukanToko;
        totalDriver += item.komisiAntar;
        totalBagiHasil += item.komisiIsi;

        // Tentukan nama metode transaksi
        String metode = 'Biasa (Di Tempat)';
        if (item.isPakaiKupon) {
          metode = 'Tukar Kupon';
        } else if (item.isAntar) {
          metode = 'Diantar';
        } else if (item.isBagiHasil) {
          metode = 'Bagi Hasil';
        }

        final String kunciUnik =
            '${item.productName} - ${item.productSize} ($metode)';

        if (!rincianTerpadu.containsKey(kunciUnik)) {
          rincianTerpadu[kunciUnik] = CombinedReportDetail();
        }

        rincianTerpadu[kunciUnik]!.qty += item.qty;
        rincianTerpadu[kunciUnik]!.subtotal += item.subtotalHarga;
        rincianTerpadu[kunciUnik]!.toko += item.pemasukanToko;
        rincianTerpadu[kunciUnik]!.driver += item.komisiAntar;
        rincianTerpadu[kunciUnik]!.bagiHasil += item.komisiIsi;
        rincianTerpadu[kunciUnik] = rincianTerpadu[kunciUnik]!;
      }
    }

    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            'TOTAL REKAPITULASI PERIODE (${activeFilterType.toUpperCase()})',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
              letterSpacing: 0.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Galon: $totalGalon Galon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalSistem),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Klik untuk melihat rincian detail 🔽',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // ==========================================
          // DETAIL URUAIAN TERPADU PERIODE SAAT DIBUKA
          // ==========================================
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.blue),
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

                  const SizedBox(height: 16),
                  const Text(
                    'Uraian Rincian Penjualan Terpadu Periode:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Menggambar secara dinamis list rincian komposit periodik
                  ...rincianTerpadu.entries.map((entry) {
                    final String namaUraian = entry.key;
                    final CombinedReportDetail detail = entry.value;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  namaUraian,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${detail.qty}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currencyFormat.format(detail.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• Toko: ${currencyFormat.format(detail.toko)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                              if (detail.driver > 0)
                                Text(
                                  '• Driver: ${currencyFormat.format(detail.driver)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (detail.bagiHasil > 0)
                                Text(
                                  '• Pengisi: ${currencyFormat.format(detail.bagiHasil)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
