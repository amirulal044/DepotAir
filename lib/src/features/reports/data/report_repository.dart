import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Impor legacy untuk Riverpod 3.x Anda
import 'package:intl/intl.dart';
import '../../orders/domain/order_model.dart';
import '../domain/daily_report_model.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  // 1. MENGHITUNG TRANSAKSI HARI INI YANG BELUM DITUTUP BUKU
  Future<Map<String, dynamic>> fetchUnreportedTotals() async {
    final response = await _supabase
        .from('orders')
        .select(
          '*, pelanggan(nama), order_items(*, produk(nama_produk, ukuran))',
        )
        .isFilter('daily_report_id', null);

    final List<Order> openOrders = response
        .map((data) => Order.fromJson(data))
        .toList();

    int totalPemasukanToko = 0;
    int totalKomisiAntar = 0;
    int totalKomisiIsi = 0;
    int totalKotorSistem = 0;

    for (var order in openOrders) {
      totalKotorSistem += order.totalHarga;
      for (var item in order.items) {
        totalPemasukanToko += item.pemasukanToko;
        totalKomisiAntar += item.komisiAntar;
        totalKomisiIsi += item.komisiIsi;
      }
    }

    return {
      'total_pemasukan_toko': totalPemasukanToko,
      'total_komisi_antar': totalKomisiAntar,
      'total_komisi_isi': totalKomisiIsi,
      'total_kotor_sistem': totalKotorSistem,
      'open_orders_count': openOrders.length,
      'open_orders': openOrders,
    };
  }

  // 2. LOGIKA INTI: MELAKUKAN AKSI TUTUP BUKU HARIAN & MENGUNCI TRANSAKSI
  Future<void> closeDailyBook({
    required int totalFisik,
    String? catatan,
  }) async {
    final totals = await fetchUnreportedTotals();

    final totalToko = (totals['total_pemasukan_toko'] as num? ?? 0).toInt();
    final totalAntar = (totals['total_komisi_antar'] as num? ?? 0).toInt();
    final totalIsi = (totals['total_komisi_isi'] as num? ?? 0).toInt();
    final totalSistem = (totals['total_kotor_sistem'] as num? ?? 0).toInt();

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

  // 3. MENGAMBIL RIWAYAT LAPORAN TUTUP BUKU DENGAN RENTANG TANGGAL OPSIONAL
  Future<List<DailyReport>> fetchHistoricalReports({
    String? startDate,
    String? endDate,
  }) async {
    var query = _supabase.from('daily_reports').select();

    if (startDate != null && endDate != null) {
      query = query.gte('report_date', startDate).lte('report_date', endDate);
    }

    final response = await query.order('report_date', ascending: false);
    return response.map((data) => DailyReport.fromJson(data)).toList();
  }

  // 4. MENARIK NOTA TRANSAKSI ASLI MASA LALU BERDASARKAN RENTANG FILTER TANGGAL
  Future<List<Order>> fetchOrdersByDateRange({
    String? startDate,
    String? endDate,
  }) async {
    var query = _supabase
        .from('orders')
        .select(
          '*, pelanggan(nama), order_items(*, produk(nama_produk, ukuran))',
        );

    if (startDate != null && endDate != null) {
      query = query
          .gte('created_at', '$startDate 00:00:00')
          .lte('created_at', '$endDate 23:59:59');
    }

    query = query.not('daily_report_id', 'is', null);

    final response = await query.order('created_at', ascending: false);
    return response.map((data) => Order.fromJson(data)).toList();
  }

  // 5. BARU: MENARIK NOTA TRANSAKSI ASLI BERDASARKAN ID LAPORAN TUTUP BUKU SPESIFIK (LAZY LOADING)
  Future<List<Order>> fetchOrdersByReportId(String reportId) async {
    final response = await _supabase
        .from('orders')
        .select(
          '*, pelanggan(nama), order_items(*, produk(nama_produk, ukuran))',
        )
        .eq('daily_report_id', reportId) // <--- Cari yang laporannya sama
        .order('created_at', ascending: false);

    return response.map((data) => Order.fromJson(data)).toList();
  }
}

// Provider Riverpod untuk Repository
final reportRepositoryProvider = Provider((ref) => ReportRepository());

// Provider untuk memantau data transaksi berjalan hari ini
final unreportedTotalsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(reportRepositoryProvider).fetchUnreportedTotals();
    });

// State filter laporan
final reportFilterTypeProvider = StateProvider<String>((ref) => 'semua');
final reportFilterDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);
final reportFilterWeekIndexProvider = StateProvider<int>((ref) => 1);

// Provider sejarah laporan tutup buku
final historicalReportsProvider = FutureProvider<List<DailyReport>>((ref) {
  final filterType = ref.watch(reportFilterTypeProvider);
  final selectedDate = ref.watch(reportFilterDateProvider);
  final weekIndex = ref.watch(reportFilterWeekIndexProvider);

  String? startDate;
  String? endDate;

  final formatter = DateFormat('yyyy-MM-dd');

  if (filterType == 'harian') {
    startDate = formatter.format(selectedDate);
    endDate = formatter.format(selectedDate);
  } else if (filterType == 'mingguan') {
    final year = selectedDate.year;
    final month = selectedDate.month.toString().padLeft(2, '0');

    if (weekIndex == 1) {
      startDate = '$year-$month-01';
      endDate = '$year-$month-07';
    } else if (weekIndex == 2) {
      startDate = '$year-$month-08';
      endDate = '$year-$month-14';
    } else if (weekIndex == 3) {
      startDate = '$year-$month-15';
      endDate = '$year-$month-21';
    } else if (weekIndex == 4) {
      final lastDay = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        0,
      ).day;
      startDate = '$year-$month-22';
      endDate = '$year-$month-${lastDay.toString().padLeft(2, '0')}';
    }
  } else if (filterType == 'bulanan') {
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

  return ref
      .read(reportRepositoryProvider)
      .fetchHistoricalReports(startDate: startDate, endDate: endDate);
});

// Provider untuk memantau & menarik pesanan asli masa lalu secara dinamis sesuai filter
final periodOrdersProvider = FutureProvider<List<Order>>((ref) {
  final filterType = ref.watch(reportFilterTypeProvider);
  final selectedDate = ref.watch(reportFilterDateProvider);
  final weekIndex = ref.watch(reportFilterWeekIndexProvider);

  String? startDate;
  String? endDate;

  final formatter = DateFormat('yyyy-MM-dd');

  if (filterType == 'harian') {
    startDate = formatter.format(selectedDate);
    endDate = formatter.format(selectedDate);
  } else if (filterType == 'mingguan') {
    final year = selectedDate.year;
    final month = selectedDate.month.toString().padLeft(2, '0');

    if (weekIndex == 1) {
      startDate = '$year-$month-01';
      endDate = '$year-$month-07';
    } else if (weekIndex == 2) {
      startDate = '$year-$month-08';
      endDate = '$year-$month-14';
    } else if (weekIndex == 3) {
      startDate = '$year-$month-15';
      endDate = '$year-$month-21';
    } else if (weekIndex == 4) {
      final lastDay = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        0,
      ).day;
      startDate = '$year-$month-22';
      endDate = '$year-$month-${lastDay.toString().padLeft(2, '0')}';
    }
  } else if (filterType == 'bulanan') {
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

  return ref
      .read(reportRepositoryProvider)
      .fetchOrdersByDateRange(startDate: startDate, endDate: endDate);
});

// ==========================================
// BARU: FAMILY PROVIDER KHUSUS LAZY LOADING HISTORI HARIAN SPESIFIK
// ==========================================
final closedOrdersByReportProvider = FutureProvider.family<List<Order>, String>(
  (ref, reportId) {
    return ref.watch(reportRepositoryProvider).fetchOrdersByReportId(reportId);
  },
);
