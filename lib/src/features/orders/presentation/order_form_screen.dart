import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../customers/data/customer_repository.dart';
import '../../customers/domain/customer_model.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_model.dart';
import '../data/order_repository.dart';
import '../data/cart_provider.dart'; // Import provider keranjang baru

import 'WidgetsForm/customer_selector_field.dart';
import 'WidgetsForm/product_selector_field.dart';
import 'WidgetsForm/transaction_options_group.dart';
import 'WidgetsForm/order_summary_card.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  Customer? selectedCustomer;
  Product? selectedProduct;

  final qtyController = TextEditingController(text: '1');

  bool isAntar = false;
  bool isBagiHasil = false;
  bool isPakaiKupon = false;
  bool isLoading = false;

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  // Fungsi untuk memasukkan barang ke daftar keranjang belanja di memori aplikasi
  void _tambahKeKeranjangLokal() {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih produk terlebih dahulu!')),
      );
      return;
    }

    final qty = int.tryParse(qtyController.text) ?? 1;

    // Panggil fungsi tambah dari provider keranjang belanja
    ref
        .read(cartProvider.notifier)
        .tambahKeKeranjang(
          product: selectedProduct!,
          qty: qty,
          isAntar: isAntar,
          isBagiHasil: isBagiHasil,
          isPakaiKupon: isPakaiKupon,
        );

    // Reset pilihan produk di form agar bisa memilih produk lainnya lagi
    setState(() {
      selectedProduct = null;
      qtyController.text = '1';
      isAntar = false;
      isBagiHasil = false;
      isPakaiKupon = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil menambahkan ke keranjang!')),
    );
  }

  // Fungsi akhir untuk mengirim seluruh isi keranjang ke database
  Future<void> _submitOrderAkhir() async {
    final keranjang = ref.read(cartProvider);

    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih pelanggan terlebih dahulu!'),
        ),
      );
      return;
    }

    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja Anda masih kosong!')),
      );
      return;
    }

    setState(() => isLoading = true);

    // Hitung total bayar dari semua item di keranjang sebelum dikirim
    final totalBayar = keranjang.fold<int>(
      0,
      (previousValue, item) => previousValue + item.subtotal,
    );

    try {
      // Panggil fungsi repository massal dengan menyertakan parameter totalBayar
      await ref
          .read(orderRepositoryProvider)
          .createBulkOrders(
            customerId: selectedCustomer!.id,
            cartItems: keranjang,
            totalBayar: totalBayar, // <--- TAMBAHKAN BARIS INI
          );

      // Refresh riwayat transaksi di halaman list
      ref.invalidate(ordersListProvider);

      // Kosongkan keranjang belanja
      ref.read(cartProvider.notifier).bersihkanKeranjang();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua transaksi berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final productsAsync = ref.watch(productsListProvider);

    // Memantau isi keranjang belanja secara real-time
    final keranjangBelanja = ref.watch(cartProvider);

    // Menghitung total keseluruhan pembayaran dari semua item di keranjang
    final totalPembayaranSemua = keranjangBelanja.fold<int>(
      0,
      (previousValue, item) => previousValue + item.subtotal,
    );

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Bersihkan keranjang jika pengguna keluar/batal
            ref.read(cartProvider.notifier).bersihkanKeranjang();
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Pilih Pelanggan (Hanya perlu dipilih sekali)
          CustomerSelectorField(
            customersAsync: customersAsync,
            selectedCustomer: selectedCustomer,
            onChanged: (value) {
              setState(() {
                selectedCustomer = value;
              });
            },
          ),
          const Divider(height: 32),

          // Judul Area Pemilihan Barang
          const Text(
            'Pilih Barang & Opsi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // 2. Pilih Produk
          ProductSelectorField(
            productsAsync: productsAsync,
            selectedProduct: selectedProduct,
            onChanged: (value) {
              setState(() {
                selectedProduct = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // 3. Masukkan Qty Produk saat ini
          TextField(
            controller: qtyController,
            decoration: const InputDecoration(
              labelText: 'Jumlah (Qty)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 4. Atur Opsi Tambahan untuk produk terpilih
          TransactionOptionsGroup(
            selectedProduct: selectedProduct,
            isAntar: isAntar,
            isBagiHasil: isBagiHasil,
            isPakaiKupon: isPakaiKupon,
            onAntarChanged: (value) {
              setState(() {
                isAntar = value;
                if (value) {
                  isBagiHasil = false;
                }
              });
            },
            onBagiHasilChanged: (value) {
              setState(() {
                isBagiHasil = value;
              });
            },
            onKuponChanged: (value) {
              setState(() {
                isPakaiKupon = value;
                if (value) {
                  qtyController.text = '1';
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // 5. Tombol untuk memasukkan ke keranjang lokal aplikasi
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade900,
            ),
            onPressed: _tambahKeKeranjangLokal,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Masukkan ke Keranjang'),
          ),

          const Divider(height: 40),

          // 6. Area Menampilkan Keranjang Belanja Sementara
          const Text(
            'Keranjang Belanja Anda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          keranjangBelanja.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Belum ada produk di keranjang.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: keranjangBelanja.length,
                  itemBuilder: (context, index) {
                    final item = keranjangBelanja[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(item.product.namaProduk),
                        subtitle: Text(
                          'Qty: ${item.qty} | '
                          '${item.isAntar ? "Diantar" : "Ambil Sendiri"}'
                          '${item.isPakaiKupon ? " (Pakai Kupon)" : ""}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormat.format(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Panggil fungsi hapus dari provider
                                ref
                                    .read(cartProvider.notifier)
                                    .hapusDariKeranjang(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          const SizedBox(height: 24),

          // 7. Menampilkan Total Pembayaran Keseluruhan
          OrderSummaryCard(total: totalPembayaranSemua),

          const SizedBox(height: 32),

          // 8. Tombol Utama untuk checkout semua isi keranjang ke database
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : _submitOrderAkhir,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Simpan Semua Pesanan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
