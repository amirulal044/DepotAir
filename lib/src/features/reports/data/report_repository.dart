import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../domain/daily_report_model.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  // 1. MENGHITUNG TRANSAKSI HARI INI YANG BELUM DITUTUP BUKU
  Future<Map<String, int>> fetchUnreportedTotals() async {
    final response = await _supabase
        .from('orders')
        .select('*, order_items(*)')
        .isFilter('daily_report_id', null);

    int totalPemasukanToko = 0;
    int totalKomisiAntar = 0;
    int totalKomisiIsi = 0;
    int totalKotorSistem = 0;

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
    final totals = await fetchUnreportedTotals();
    final totalToko = totals['total_pemasukan_toko'] ?? 0;
    final totalAntar = totals['total_komisi_antar'] ?? 0;
    final totalIsi = totals['total_komisi_isi'] ?? 0;
    final totalSistem = totals['total_kotor_sistem'] ?? 0;

    final int selisih = totalFisik - totalSistem;

    final reportResponse = await _supabase
        .from('daily_reports')
        .insert({
          'total_pemasukan_toko': totalToko,
          'total_komisi_antar': totalAntar,
          'total_komisi_isi': totalIsi,
          'total_kotor_sistem': totalSistem,
          'total_kotor_fisik': totalFisik,
          'selisih': selisih,
          'catatan': catatan,
          'status': 'closed',
        })
        .select('id')
        .single();

    final String reportId = reportResponse['id'];

    await _supabase
        .from('orders')
        .update({'daily_report_id': reportId})
        .isFilter('daily_report_id', null);
  }

  // 3. MENGAMBIL RIWAYAT LAPORAN TUTUP BUKU DENGAN RENTANG TANGGAL OPSIONAL (Bisa untuk filter)
  Future<List<DailyReport>> fetchHistoricalReports({
    String? startDate,
    String? endDate,
  }) async {
    var query = _supabase.from('daily_reports').select();

    // Jika parameter tanggal dikirim, lakukan filter rentang tanggal di database Supabase
    if (startDate != null && endDate != null) {
      query = query.gte('report_date', startDate).lte('report_date', endDate);
    }

    final response = await query.order('report_date', ascending: false);
    return response.map((data) => DailyReport.fromJson(data)).toList();
  }
}

// Provider Riverpod untuk Repository
final reportRepositoryProvider = Provider((ref) => ReportRepository());

// Provider untuk memantau data transaksi berjalan hari ini
final unreportedTotalsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) {
  return ref.watch(reportRepositoryProvider).fetchUnreportedTotals();
});

// ==========================================
// STATE FILTER BARU (RIVERPOD) UNTUK LAPORAN
// ==========================================

// Menyimpan tipe filter yang sedang aktif: 'semua', 'harian', 'mingguan', atau 'bulanan'
final reportFilterTypeProvider = StateProvider<String>((ref) => 'semua');

// Menyimpan objek tanggal acuan yang sedang dipilih pengguna (default: hari ini)
final reportFilterDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// Provider sejarah laporan yang secara otomatis memicu query ulang jika filter di atas berubah
final historicalReportsProvider = FutureProvider<List<DailyReport>>((ref) {
  final filterType = ref.watch(reportFilterTypeProvider);
  final selectedDate = ref.watch(reportFilterDateProvider);

  String? startDate;
  String? endDate;

  final formatter = DateFormat('yyyy-MM-dd');

  if (filterType == 'harian') {
    startDate = formatter.format(selectedDate);
    endDate = formatter.format(selectedDate);
  } else if (filterType == 'mingguan') {
    // Cari hari Senin (Awal Minggu) dan Minggu (Akhir Minggu) dari tanggal terpilih
    final int dayOfWeek = selectedDate.weekday; // Senin = 1, Minggu = 7
    final DateTime monday = selectedDate.subtract(
      Duration(days: dayOfWeek - 1),
    );
    final DateTime sunday = selectedDate.add(Duration(days: 7 - dayOfWeek));
    startDate = formatter.format(monday);
    endDate = formatter.format(sunday);
  } else if (filterType == 'bulanan') {
    // Cari tanggal 1 (Awal Bulan) s.d hari terakhir bulan tersebut (Akhir Bulan)
    final DateTime firstDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    );
    final DateTime lastDay = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );
    startDate = formatter.format(firstDay);
    endDate = formatter.format(lastDay);
  }

  // Panggil fungsi repository dengan menyertakan rentang tanggal filter hasil konversi di atas
  return ref
      .read(reportRepositoryProvider)
      .fetchHistoricalReports(startDate: startDate, endDate: endDate);
});
