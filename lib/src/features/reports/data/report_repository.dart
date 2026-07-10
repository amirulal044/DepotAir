import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/daily_report_model.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  // 1. MENGHITUNG TRANSAKSI HARI INI YANG BELUM DITUTUP BUKU
  Future<Map<String, int>> fetchUnreportedTotals() async {
    // Ambil seluruh orders beserta item belanjaannya yang belum di-lock (daily_report_id is NULL)
    final response = await _supabase
        .from('orders')
        .select('*, order_items(*)')
        .isFilter(
          'daily_report_id',
          null,
        ); // <--- Hanya transaksi yang masih "OPEN"

    int totalPemasukanToko = 0;
    int totalKomisiAntar = 0;
    int totalKomisiIsi = 0;
    int totalKotorSistem = 0;

    // Iterasi/perulangan untuk menjumlahkan semua porsi uang secara otomatis di Dart
    for (var order in response) {
      final items = order['order_items'] as List? ?? [];
      for (var item in items) {
        totalPemasukanToko += (item['pemasukan_toko'] as num? ?? 0).toInt();
        totalKomisiAntar += (item['komisi_antar'] as num? ?? 0).toInt();
        totalKomisiIsi += (item['komisi_isi'] as num? ?? 0).toInt();
        totalKotorSistem += (item['subtotal_harga'] as num? ?? 0).toInt();
      }
    }

    return {
      'total_pemasukan_toko': totalPemasukanToko,
      'total_komisi_antar': totalKomisiAntar,
      'total_komisi_isi': totalKomisiIsi,
      'total_kotor_sistem': totalKotorSistem,
    };
  }

  // 2. LOGIKA INTI: MELAKUKAN AKSI TUTUP BUKU HARIAN & MENGUNCI TRANSAKSI
  Future<void> closeDailyBook({
    required int totalFisik,
    String? catatan,
  }) async {
    // A. Ambil akumulasi sistem saat ini
    final totals = await fetchUnreportedTotals();
    final totalToko = totals['total_pemasukan_toko'] ?? 0;
    final totalAntar = totals['total_komisi_antar'] ?? 0;
    final totalIsi = totals['total_komisi_isi'] ?? 0;
    final totalSistem = totals['total_kotor_sistem'] ?? 0;

    // B. Hitung selisih uang (Fisik - Sistem)
    final int selisih = totalFisik - totalSistem;

    // C. Simpan data laporan tutup buku ke tabel induk baru 'daily_reports'
    final reportResponse = await _supabase
        .from('daily_reports')
        .insert({
          'total_pemasukan_toko': totalToko,
          'total_komisi_antar': totalAntar,
          'total_komisi_isi': totalIsi,
          'total_kotor_sistem': totalSistem,
          'total_kotor_physical':
              totalFisik, // Jika kolom di SQL Anda tadi bernama total_kotor_fisik, sesuaikan dengan SQL
          'total_kotor_fisik':
              totalFisik, // Kode ini mencakup nama kolom 'total_kotor_fisik' sesuai SQL kita
          'selisih': selisih,
          'catatan': catatan,
          'status': 'closed',
        })
        .select('id')
        .single();

    final String reportId = reportResponse['id'];

    // D. KUNCI TRANSAKSI: Perbarui semua orders yang tadinya NULL menjadi ID laporan ini
    await _supabase
        .from('orders')
        .update({'daily_report_id': reportId})
        .isFilter('daily_report_id', null);
  }

  // 3. MENGAMBIL RIWAYAT LAPORAN TUTUP BUKU SEBELUMNYA
  Future<List<DailyReport>> fetchHistoricalReports() async {
    final response = await _supabase
        .from('daily_reports')
        .select()
        .order('report_date', ascending: false);

    return response.map((data) => DailyReport.fromJson(data)).toList();
  }
}

// Provider Riverpod untuk digunakan di UI
final reportRepositoryProvider = Provider((ref) => ReportRepository());

// Provider untuk memantau data transaksi berjalan hari ini
final unreportedTotalsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) {
  return ref.watch(reportRepositoryProvider).fetchUnreportedTotals();
});

// Provider untuk memantau sejarah laporan tutup buku harian
final historicalReportsProvider = FutureProvider<List<DailyReport>>((ref) {
  return ref.watch(reportRepositoryProvider).fetchHistoricalReports();
});
