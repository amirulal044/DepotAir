import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../customers/data/customer_repository.dart';
import '../../customers/domain/customer_model.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_model.dart';
import '../data/order_repository.dart';
import 'package:intl/intl.dart';

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
  bool isLoading = false;

  // Tambahkan di dalam State class anda:
  bool isPakaiKupon = false;

  // Fungsi Logika Perhitungan Total (Ditempatkan di dalam build)
  int hitungTotal() {
    if (selectedProduct == null) return 0;

    int qty = int.tryParse(qtyController.text) ?? 0;
    // Jika kupon dipakai, harga produk jadi 0
    int hargaDasar = isPakaiKupon ? 0 : selectedProduct!.harga;
    int subtotalProduk = hargaDasar * qty;

    // Biaya antar Rp 1.000 per galon
    int biayaAntar = isAntar ? (qty * 1000) : 0;

    return subtotalProduk + biayaAntar;
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil data pendukung dari provider fitur lain
    final customersAsync = ref.watch(customersListProvider);
    final productsAsync = ref.watch(productsListProvider);

    // --- LOG DEBUG UNTUK UI ---
    // Memantau status loading pelanggan
    customersAsync.when(
      data: (list) => debugPrint(
        '📱 [UI LOG] Dropdown Pelanggan siap: ${list.length} orang',
      ),
      error: (e, st) =>
          debugPrint('📱 [UI LOG] Dropdown Pelanggan Error di UI: $e'),
      loading: () =>
          debugPrint('📱 [UI LOG] Dropdown Pelanggan sedang loading...'),
    );

    // Memantau status loading produk
    productsAsync.when(
      data: (list) =>
          debugPrint('📱 [UI LOG] Dropdown Produk siap: ${list.length} item'),
      error: (e, st) =>
          debugPrint('📱 [UI LOG] Dropdown Produk Error di UI: $e'),
      loading: () =>
          debugPrint('📱 [UI LOG] Dropdown Produk sedang loading...'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 1. Dropdown Pilih Pelanggan
            customersAsync.when(
              data: (list) => DropdownButtonFormField<Customer>(
                decoration: const InputDecoration(labelText: 'Pilih Pelanggan'),
                value: selectedCustomer,
                items: list
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.nama)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCustomer = val),
              ),
              error: (e, st) => const Text('Gagal memuat pelanggan'),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),

            // 2. Dropdown Pilih Produk
            productsAsync.when(
              data: (list) => DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'Pilih Produk'),
                value: selectedProduct,
                items: list
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.namaProduk} (${p.ukuran})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedProduct = val),
              ),
              error: (e, st) => const Text('Gagal memuat produk'),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),

            // 3. Input Quantity
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Jumlah (Qty)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // 4. Switch Biaya Antar
            SwitchListTile(
              title: const Text('Antar ke Rumah (+Rp 1.000/galon)'),
              value: isAntar,
              onChanged: (val) {
                setState(() {
                  isAntar = val;
                  if (val)
                    isBagiHasil = false; // Antar aktif -> Bagi hasil mati
                });
              },
            ),

            // 5. Switch Bagi Hasil (Hanya muncul jika ambil di tempat & 19L)
            if (!isAntar && selectedProduct?.ukuran == "19 Liter")
              SwitchListTile(
                title: const Text('Sistem Bagi Hasil (10%)'),
                value: isBagiHasil,
                onChanged: (val) => setState(() => isBagiHasil = val),
              ),

            // 6. Switch Pakai Kupon (Hanya muncul jika produk 19L)
            if (selectedProduct?.ukuran == "19 Liter")
              SwitchListTile(
                secondary: const Icon(
                  Icons.confirmation_number,
                  color: Colors.orange,
                ),
                title: const Text('Gunakan Kupon Gratis'),
                subtitle: const Text('10 Kupon = 1 Galon Gratis'),
                value: isPakaiKupon,
                onChanged: (val) {
                  setState(() {
                    isPakaiKupon = val;
                    if (val)
                      qtyController.text = '1'; // Kupon biasanya untuk 1 galon
                  });
                },
              ),

            const Divider(height: 40),

            // 7. Live Preview Total Harga (Sangat Profesional)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(hitungTotal()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 8. Tombol Simpan
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'KONFIRMASI PESANAN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (selectedCustomer == null || selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pelanggan & produk dulu')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerId: selectedCustomer!.id,
            productId: selectedProduct!.id,
            productPrice: selectedProduct!.harga,
            productSize: selectedProduct!.ukuran,
            qty: int.parse(qtyController.text),
            isAntar: isAntar,
            isBagiHasil: isBagiHasil,
            isPakaiKupon: isPakaiKupon,
          );

      ref.invalidate(ordersListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }
}
