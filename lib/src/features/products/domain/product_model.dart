class Product {
  final String id;
  final String namaProduk;
  final int harga;
  final String ukuran;

  Product({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.ukuran,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      namaProduk: json['nama_produk'],
      harga: json['harga'] ?? 0,
      ukuran: json['ukuran'] ?? '', // Mengambil data ukuran dari database
    );
  }
}
