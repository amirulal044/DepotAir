import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/daily_report_model.dart';
// <--- Impor model Order asli
import '../../data/report_repository.dart'; // <--- Impor provider

// Kelas penampung rincian komposit dalam histori harian
class HistoryReportDetail {
  int qty = 0;
  int subtotal = 0;
  int toko = 0;
  int driver = 0;
  int bagiHasil = 0;
}

class ReportHistoryItem extends ConsumerStatefulWidget {
  final DailyReport report;

  const ReportHistoryItem({super.key, required this.report});

  @override
  ConsumerState<ReportHistoryItem> createState() => _ReportHistoryItemState();
}

class _ReportHistoryItemState extends ConsumerState<ReportHistoryItem> {
  // Status pelacakan apakah kartu ini sedang diperlebar (expanded) atau dilipat
  bool _isExpanded = false;

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
      child: Theme(
        // Menghilangkan garis divider default bawaan ListTile/ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            // Hanya aktifkan pemuatan data saat kartu benar-benar diklik/dibuka (Lazy Loading)
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            dateFormat.format(widget.report.reportDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uang Fisik: ${currencyFormat.format(widget.report.totalKotorFisik)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(widget.report.totalKotorSistem),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Klik untuk melihat rincian nota harian 🔽',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // ==========================================
          // DETAIL YANG DI-LOAD SECARA PEMUATAN TUNDA (LAZY LOADING)
          // ==========================================
          children: [
            if (_isExpanded)
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
                    _buildInfoRow(
                      '• Pendapatan Bersih Toko:',
                      currencyFormat.format(widget.report.totalPemasukanToko),
                    ),
                    _buildInfoRow(
                      '• Komisi Driver:',
                      currencyFormat.format(widget.report.totalKomisiAntar),
                      color: Colors.green.shade800,
                    ),
                    _buildInfoRow(
                      '• Komisi Pengisi:',
                      currencyFormat.format(widget.report.totalKomisiIsi),
                      color: Colors.orange.shade900,
                    ),
                    const Divider(color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selisih Uang Laci:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.report.selisih),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: widget.report.selisih == 0
                                ? Colors.green
                                : (widget.report.selisih < 0
                                      ? Colors.red
                                      : Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    if (widget.report.catatan != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Catatan: ${widget.report.catatan}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'Uraian Rincian Penjualan Terpadu Hari Ini:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // MEMANGGIL PROVIDER FAMILY KHUSUS UNTUK MENARIK DETAIL BARANG TRANSAKSI LAMA
                    ref
                        .watch(closedOrdersByReportProvider(widget.report.id))
                        .when(
                          data: (orders) {
                            if (orders.isEmpty) {
                              return const Text(
                                'Tidak ada rincian transaksi ditemukan.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              );
                            }

                            // JALANKAN LOGIKA GRUP KOMPOSIT DI SINI
                            final Map<String, HistoryReportDetail>
                            rincianTerpadu = {};

                            for (var order in orders) {
                              for (var item in order.items) {
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
                                  rincianTerpadu[kunciUnik] =
                                      HistoryReportDetail();
                                }

                                rincianTerpadu[kunciUnik]!.qty += item.qty;
                                rincianTerpadu[kunciUnik]!.subtotal +=
                                    item.subtotalHarga;
                                rincianTerpadu[kunciUnik]!.toko +=
                                    item.pemasukanToko;
                                rincianTerpadu[kunciUnik]!.driver +=
                                    item.komisiAntar;
                                rincianTerpadu[kunciUnik]!.bagiHasil +=
                                    item.komisiIsi;
                                rincianTerpadu[kunciUnik] =
                                    rincianTerpadu[kunciUnik]!;
                              }
                            }

                            // Menggambar list rincian komposit untuk tanggal tertentu secara rapi
                            return Column(
                              children: rincianTerpadu.entries.map((entry) {
                                final String namaUraian = entry.key;
                                final HistoryReportDetail detail = entry.value;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                            currencyFormat.format(
                                              detail.subtotal,
                                            ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                              }).toList(),
                            );
                          },
                          error: (e, st) => Text(
                            'Gagal memuat rincian: $e',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget helper privat merapikan baris informasi rekapitulasi harian
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
