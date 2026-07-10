class DailyReport {
  final String id;
  final DateTime reportDate;
  final int totalPemasukanToko;
  final int totalKomisiAntar;
  final int totalKomisiIsi;
  final int totalKotorSistem;
  final int totalKotorFisik;
  final int selisih;
  final String status;
  final String? closedBy;
  final String? catatan;
  final DateTime createdAt;

  DailyReport({
    required this.id,
    required this.reportDate,
    required this.totalPemasukanToko,
    required this.totalKomisiAntar,
    required this.totalKomisiIsi,
    required this.totalKotorSistem,
    required this.totalKotorFisik,
    required this.selisih,
    required this.status,
    this.closedBy,
    this.catatan,
    required this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id'],
      reportDate: DateTime.parse(json['report_date']),
      totalPemasukanToko: json['total_pemasukan_toko'] ?? 0,
      totalKomisiAntar: json['total_komisi_antar'] ?? 0,
      totalKomisiIsi: json['total_komisi_isi'] ?? 0,
      totalKotorSistem: json['total_kotor_sistem'] ?? 0,
      totalKotorFisik: json['total_kotor_fisik'] ?? 0,
      selisih: json['selisih'] ?? 0,
      status: json['status'] ?? 'closed',
      closedBy: json['closed_by'],
      catatan: json['catatan'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
