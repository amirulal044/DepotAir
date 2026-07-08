class Customer {
  final String id;
  final String nama;
  final String alamat;
  final String nomorHp;

  Customer({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.nomorHp,
  });

  // Mengubah JSON dari Supabase ke Objek Dart
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      nama: json['nama'],
      alamat: json['alamat'] ?? '',
      nomorHp: json['nomor_hp'] ?? '',
    );
  }
}
