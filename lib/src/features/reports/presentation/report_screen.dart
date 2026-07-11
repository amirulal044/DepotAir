import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/report_repository.dart';
import '../../orders/data/order_repository.dart';

import 'widgets/report_system_totals_card.dart';
import 'widgets/report_discrepancy_card.dart';
import 'widgets/report_history_item.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _fisikController = TextEditingController();
  final _catatanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fisikController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _prosesTutupBuku(int totalSistem) async {
    final fisikText = _fisikController.text;
    if (fisikText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan jumlah uang fisik terlebih dahulu!'),
        ),
      );
      return;
    }

    final totalFisik = int.tryParse(fisikText) ?? 0;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(reportRepositoryProvider)
          .closeDailyBook(
            totalFisik: totalFisik,
            catatan: _catatanController.text.isNotEmpty
                ? _catatanController.text
                : null,
          );

      ref.invalidate(unreportedTotalsProvider);
      ref.invalidate(historicalReportsProvider);
      ref.invalidate(ordersListProvider);

      _fisikController.clear();
      _catatanController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutup Buku Hari Ini Berhasil Disimpan & Dikunci!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan tutup buku: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi memicu munculnya pemilih tanggal (Date Picker)
  Future<void> _pilihTanggalFilter(
    BuildContext context,
    DateTime currentDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != currentDate) {
      ref.read(reportFilterDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalsAsync = ref.watch(unreportedTotalsProvider);
    final historyAsync = ref.watch(historicalReportsProvider);

    // Watch status filter yang sedang aktif
    final activeFilterType = ref.watch(reportFilterTypeProvider);
    final activeFilterDate = ref.watch(reportFilterDateProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy');
    final monthFormat = DateFormat('MMMM yyyy');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembukuan & Laporan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: 'Tutup Buku'),
              Tab(icon: Icon(Icons.history), text: 'Riwayat Tutup Buku'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ==========================================
            // TAB 1: FORM TUTUP BUKU HARIAN
            // ==========================================
            totalsAsync.when(
              data: (totals) {
                final int totalSistem = totals['total_kotor_sistem'] ?? 0;

                if (totalSistem == 0) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Belum ada transaksi baru yang berjalan.\nSemua pesanan hari ini sudah ditutup buku atau kosong.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                final int totalFisik = int.tryParse(_fisikController.text) ?? 0;
                final int selisih = totalFisik - totalSistem;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Uang Masuk Hari Ini (Sistem)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReportSystemTotalsCard(
                      totalToko: totals['total_pemasukan_toko'] ?? 0,
                      totalDriver: totals['total_komisi_antar'] ?? 0,
                      totalIsi: totals['total_komisi_isi'] ?? 0,
                      totalSistem: totalSistem,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verifikasi Uang Fisik di Laci',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _fisikController,
                      decoration: const InputDecoration(
                        labelText: 'Masukkan Jumlah Uang Nyata di Laci',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    ReportDiscrepancyCard(selisih: selisih),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Penjelasan (Jika ada selisih)',
                        border: OutlineInputBorder(),
                        hintText:
                            'Contoh: Kurang Rp 2.000 karena salah kembalian',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _prosesTutupBuku(totalSistem),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Kunci & Tutup Buku Hari Ini',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                );
              },
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),

            // ==========================================
            // TAB 2: SEJARAH LAPORAN TUTUP BUKU HARIAN DENGAN FILTER FLEKSIBEL
            // ==========================================
            Column(
              children: [
                // A. PILIHAN TOMBOL FILTER HORISONTAL (SEUMUA, HARIAN, MINGGUAN, BULANAN)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(ref, 'semua', 'Semua', activeFilterType),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        'harian',
                        'Harian',
                        activeFilterType,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        'mingguan',
                        'Mingguan',
                        activeFilterType,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        'bulanan',
                        'Bulanan',
                        activeFilterType,
                      ),
                    ],
                  ),
                ),

                // B. PEMILIH TANGGAL DINAMIS (Hanya muncul jika bukan filter 'semua')
                if (activeFilterType != 'semua')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _pilihTanggalFilter(context, activeFilterDate),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        activeFilterType == 'harian'
                            ? 'Tanggal: ${dateFormat.format(activeFilterDate)}'
                            : (activeFilterType == 'mingguan'
                                  ? 'Minggu dari: ${dateFormat.format(activeFilterDate)}'
                                  : 'Bulan: ${monthFormat.format(activeFilterDate)}'),
                      ),
                    ),
                  ),

                // C. LIST DATA SEJARAH TUTUP BUKU & KARTU AKUMULASI PERIODE
                Expanded(
                  child: historyAsync.when(
                    data: (listLaporan) {
                      if (listLaporan.isEmpty) {
                        return const Center(
                          child: Text(
                            'Tidak ada riwayat laporan pada periode ini.',
                          ),
                        );
                      }

                      // LOGIKA HITUNG AKUMULASI PERIODE TERPILIH
                      int totalTokoPeriode = 0;
                      int totalDriverPeriode = 0;
                      int totalIsiPeriode = 0;
                      int totalSistemPeriode = 0;

                      for (var lap in listLaporan) {
                        totalTokoPeriode += lap.totalPemasukanToko;
                        totalDriverPeriode += lap.totalKomisiAntar;
                        totalIsiPeriode += lap.totalKomisiIsi;
                        totalSistemPeriode += lap.totalKotorSistem;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            listLaporan.length +
                            1, // +1 untuk menyelipkan Card Akumulasi Periode di paling atas
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // TAMPILKAN CARD AKUMULASI REKAPITULASI UNTUK PERIODE YANG SEDANG DIFILTER
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
                                      currencyFormat.format(totalTokoPeriode),
                                    ),
                                    _buildSummaryRow(
                                      '• Total Gaji Driver:',
                                      currencyFormat.format(totalDriverPeriode),
                                      color: Colors.green.shade800,
                                    ),
                                    _buildSummaryRow(
                                      '• Total Bagi Hasil:',
                                      currencyFormat.format(totalIsiPeriode),
                                      color: Colors.orange.shade900,
                                    ),
                                    const Divider(color: Colors.blue),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Kotor Periode:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          currencyFormat.format(
                                            totalSistemPeriode,
                                          ),
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

                          // TAMPILKAN ITEM DAFTAR LAPORAN HARIAN DI BAWAH KARTU AKUMULASI
                          final lap = listLaporan[index - 1];
                          return ReportHistoryItem(report: lap);
                        },
                      );
                    },
                    error: (e, st) => Center(child: Text('Error: $e')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk membuat baris informasi rapi kiri-kanan
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

  // Widget helper untuk ChoiceChip filter horisontal
  Widget _buildFilterChip(
    WidgetRef ref,
    String type,
    String label,
    String activeType,
  ) {
    final isSelected = activeType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(reportFilterTypeProvider.notifier).state = type;
        }
      },
    );
  }

  // Widget helper untuk baris rekapitulasi atas
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
