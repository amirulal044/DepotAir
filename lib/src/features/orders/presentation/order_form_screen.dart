import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/data/customer_repository.dart';
import '../../customers/domain/customer_model.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_model.dart';
import '../data/order_repository.dart';

import 'widgets/customer_selector_field.dart';
import 'widgets/product_selector_field.dart';
import 'widgets/transaction_options_group.dart';
import 'widgets/order_summary_card.dart';

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

  int _hitungTotal() {
    if (selectedProduct == null) return 0;

    final qty = int.tryParse(qtyController.text) ?? 1;

    final hargaDasar = isPakaiKupon ? 0 : selectedProduct!.harga;
    final biayaAntar = isAntar ? qty * 1000 : 0;

    return (hargaDasar * qty) + biayaAntar;
  }

  Future<void> _submitOrder() async {
    // 1. Validasi Input
    if (selectedCustomer == null || selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih pelanggan dan produk dulu!'),
        ),
      );
      return;
    }

    // 2. Set Loading
    setState(() => isLoading = true);

    try {
      // 3. Panggil Repository
      await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerId: selectedCustomer!.id,
            productId: selectedProduct!.id,
            productPrice: selectedProduct!.harga,
            productSize: selectedProduct!.ukuran,
            qty: int.tryParse(qtyController.text) ?? 1,
            isAntar: isAntar,
            isBagiHasil: isBagiHasil,
            isPakaiKupon: isPakaiKupon,
          );

      // 4. Refresh List Riwayat Transaksi
      ref.invalidate(ordersListProvider);

      // 5. Kembali ke halaman sebelumnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Berhasil Disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan Baru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomerSelectorField(
            customersAsync: customersAsync,
            selectedCustomer: selectedCustomer,
            onChanged: (value) {
              setState(() {
                selectedCustomer = value;
              });
            },
          ),

          const SizedBox(height: 16),

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

          const SizedBox(height: 24),

          OrderSummaryCard(total: _hitungTotal()),

          const SizedBox(height: 32),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitOrder,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Simpan Pesanan"),
            ),
          ),
        ],
      ),
    );
  }
}
