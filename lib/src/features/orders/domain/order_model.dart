class Order {
  final String id;
  final String customerName;
  final String productName;
  final int qty;
  final int totalHarga;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.qty,
    required this.totalHarga,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerName: json['pelanggan']['nama'], // Data join dari tabel pelanggan
      productName: json['produk']['nama_produk'], // Data join dari tabel produk
      qty: json['qty'],
      totalHarga: json['total_harga'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
