class Order {
  final String id;
  final String customerName;
  final int totalHarga; // Total_bayar dari tabel induk 'orders'
  final DateTime createdAt;
  final List<OrderItem> items; // Menampung daftar barang yang dibeli
  final String?
  dailyReportId; // <--- BARU: Untuk mengecek apakah transaksi ini sudah terkunci (Tutup Buku) atau belum

  Order({
    required this.id,
    required this.customerName,
    required this.totalHarga,
    required this.createdAt,
    required this.items,
    this.dailyReportId, // <--- BARU
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parsing list item belanjaan dari tabel 'order_items'
    final listItems = json['order_items'] as List? ?? [];
    final parsedItems = listItems
        .map((item) => OrderItem.fromJson(item))
        .toList();

    return Order(
      id: json['id'],
      customerName: json['pelanggan']['nama'] ?? 'Tanpa Nama',
      totalHarga: json['total_bayar'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      items: parsedItems,
      dailyReportId:
          json['daily_report_id'], // <--- BARU: Membaca kolom pengunci dari Supabase
    );
  }
}

class OrderItem {
  final String productName;
  final int qty;
  final int subtotalHarga;
  final int pemasukanToko;
  final int komisiAntar;
  final int komisiIsi;

  OrderItem({
    required this.productName,
    required this.qty,
    required this.subtotalHarga,
    required this.pemasukanToko,
    required this.komisiAntar,
    required this.komisiIsi,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['produk']['nama_produk'] ?? 'Produk Tidak Dikenal',
      qty: json['qty'] ?? 1,
      subtotalHarga: json['subtotal_harga'] ?? 0,
      pemasukanToko: json['pemasukan_toko'] ?? 0,
      komisiAntar: json['komisi_antar'] ?? 0,
      komisiIsi: json['komisi_isi'] ?? 0,
    );
  }
}
