import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_repository.dart';
import '../../orders/data/order_repository.dart';

// Impor semua sub-widget modular baru kita
import 'widgets/report_system_totals_card.dart';
import 'widgets/report_discrepancy_card.dart';
import 'widgets/report_filter_section.dart';
import 'widgets/report_period_summary_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final totalsAsync = ref.watch(unreportedTotalsProvider);
    final historyAsync = ref.watch(historicalReportsProvider);
    final activeFilterType = ref.watch(reportFilterTypeProvider);

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
            // TAB 2: SEJARAH LAPORAN DENGAN FILTER (SANGAT BERSIH & MODULAR)
            // ==========================================
            Column(
              children: [
                // 1. WIDGET BAGIAN FILTER (ChoiceChips & Kalender)
                const ReportFilterSection(),

                // 2. DAFTAR RIWAYAT DENGAN KARTU AKUMULASI PERIODE
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

                      // Hitung akumulasi periode terpilih
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
                        itemCount: listLaporan.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // 2. KARTU RINGKASAN AKUMULASI PERIODE (DIPISAH)
                            return ReportPeriodSummaryCard(
                              activeFilterType: activeFilterType,
                              totalToko: totalTokoPeriode,
                              totalDriver: totalDriverPeriode,
                              totalIsi: totalIsiPeriode,
                              totalSistem: totalSistemPeriode,
                            );
                          }

                          // 3. BARIS RIWAYAT LAPORAN HARIAN (DIPISAH)
                          return ReportHistoryItem(
                            report: listLaporan[index - 1],
                          );
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
}
