import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/report_repository.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

// Langsung masuk ke kelas State-nya yang benar di bawah ini:
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

  // Fungsi memproses kirim tutup buku harian
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
      // Panggil fungsi penutupan buku harian di repository
      await ref
          .read(reportRepositoryProvider)
          .closeDailyBook(
            totalFisik: totalFisik,
            catatan: _catatanController.text.isNotEmpty
                ? _catatanController.text
                : null,
          );

      // Refresh seluruh data laporan di UI
      ref.invalidate(unreportedTotalsProvider);
      ref.invalidate(historicalReportsProvider);

      // Bersihkan form inputan
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

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy');

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

                // Kalkulasi selisih secara otomatis dan real-time saat diketik
                final int totalFisik = int.tryParse(_fisikController.text) ?? 0;
                final int selisih = totalFisik - totalSistem;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // A. RINGKASAN DATA KEUANGAN SISTEM
                    const Text(
                      'Uang Masuk Hari Ini (Sistem)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Pemasukan Toko:',
                              currencyFormat.format(
                                totals['total_pemasukan_toko'],
                              ),
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Komisi Driver (Antar):',
                              currencyFormat.format(
                                totals['total_komisi_antar'],
                              ),
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Komisi Pengisi (Bagi Hasil):',
                              currencyFormat.format(totals['total_komisi_isi']),
                            ),
                            const Divider(thickness: 1.5, color: Colors.blue),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Uang Sistem:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
                    ),
                    const SizedBox(height: 24),

                    // B. INPUT NOMINAL UANG FISIK DI LACI
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
                      onChanged: (_) {
                        // Memaksa layar merender ulang untuk menghitung selisih real-time
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // C. TAMPILAN SELISIH UANG (HIJAU JIKA PAS, MERAH JIKA KURANG)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selisih == 0
                            ? Colors.green.shade50
                            : (selisih < 0
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selisih == 0
                              ? Colors.green.shade200
                              : (selisih < 0
                                    ? Colors.red.shade200
                                    : Colors.blue.shade200),
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
                                  : (selisih < 0
                                        ? Colors.red.shade800
                                        : Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // D. INPUT CATATAN PENJELASAN
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

                    // E. TOMBOL PROSES TUTUP BUKU
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
            // TAB 2: SEJARAH LAPORAN TUTUP BUKU HARIAN
            // ==========================================
            historyAsync.when(
              data: (listLaporan) => listLaporan.isEmpty
                  ? const Center(
                      child: Text('Belum ada riwayat laporan tutup buku.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listLaporan.length,
                      itemBuilder: (context, index) {
                        final lap = listLaporan[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(lap.reportDate),
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
                                  currencyFormat.format(lap.totalPemasukanToko),
                                ),
                                _buildInfoRow(
                                  'Komisi Driver:',
                                  currencyFormat.format(lap.totalKomisiAntar),
                                ),
                                _buildInfoRow(
                                  'Komisi Pengisi:',
                                  currencyFormat.format(lap.totalKomisiIsi),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  'Uang Sistem:',
                                  currencyFormat.format(lap.totalKotorSistem),
                                ),
                                _buildInfoRow(
                                  'Uang Fisik di Laci:',
                                  currencyFormat.format(lap.totalKotorFisik),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Selisih Uang:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(lap.selisih),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: lap.selisih == 0
                                            ? Colors.green
                                            : (lap.selisih < 0
                                                  ? Colors.red
                                                  : Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                                if (lap.catatan != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Catatan: ${lap.catatan}',
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
                      },
                    ),
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
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
}
