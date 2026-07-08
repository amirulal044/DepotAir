import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_repository.dart';
import '../domain/product_model.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _ukuranController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(
      text: widget.product?.namaProduk ?? '',
    );

    _hargaController = TextEditingController(
      text: widget.product?.harga.toString() ?? '',
    );

    _ukuranController = TextEditingController(
      text: widget.product?.ukuran ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _ukuranController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = ref.read(productRepositoryProvider);

    try {
      final harga = int.parse(_hargaController.text);

      if (widget.product == null) {
        await repo.addProduct(
          _namaController.text.trim(),
          harga,
          _ukuranController.text.trim(),
        );
      } else {
        await repo.updateProduct(
          widget.product!.id,
          _namaController.text.trim(),
          harga,
          _ukuranController.text.trim(),
        );
      }

      ref.invalidate(productsListProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                hintText: 'Contoh: Isi Ulang Galon',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama produk wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ukuranController,
              decoration: const InputDecoration(
                labelText: 'Ukuran',
                hintText: 'Contoh: 19 Liter / 600 ml',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ukuran wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Harga wajib diisi';
                }

                if (int.tryParse(value) == null) {
                  return 'Harga harus berupa angka';
                }

                return null;
              },
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      widget.product == null
                          ? 'Simpan Produk'
                          : 'Update Produk',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
