import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_model.dart';

// Impor semua sub-widget modular
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
      ref.invalidate(
        periodOrdersProvider,
      ); // <--- BARU: Ikut invalidate saat tutup buku sukses

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
    final periodOrdersAsync = ref.watch(
      periodOrdersProvider,
    ); // <--- BARU: Pantau pesanan periodik
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
                final int openOrdersCount = totals['open_orders_count'] ?? 0;
                final int totalSistem = totals['total_kotor_sistem'] ?? 0;

                if (openOrdersCount == 0) {
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
                      openOrders: totals['open_orders'] as List<Order>? ?? [],
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
            // TAB 2: SEJARAH LAPORAN DENGAN FILTER PERIODIK COMPOSITE
            // ==========================================
            Column(
              children: [
                const ReportFilterSection(),
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

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: listLaporan.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // 2. KARTU REKAPITULASI PERIODIK (Membaca data periodOrdersAsync)
                            return periodOrdersAsync.when(
                              data: (orders) => ReportPeriodSummaryCard(
                                activeFilterType: activeFilterType,
                                periodOrders:
                                    orders, // <--- Kirim list order periodik asli
                              ),
                              error: (e, st) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Gagal memuat rekap: $e'),
                                ),
                              ),
                              loading: () => const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            );
                          }

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
