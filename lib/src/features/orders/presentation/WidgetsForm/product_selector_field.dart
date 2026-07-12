import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/product_model.dart';

class ProductSelectorField extends StatelessWidget {
  final AsyncValue<List<Product>> productsAsync;
  final Product? selectedProduct;
  final Function(Product?) onChanged;

  const ProductSelectorField({
    super.key,
    required this.productsAsync,
    required this.selectedProduct,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      data: (list) => DropdownButtonFormField<Product>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Pilih Produk',
          prefixIcon: Icon(Icons.water_drop_outlined),
          border: OutlineInputBorder(),
        ),
        initialValue: selectedProduct,
        items: list
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text('${p.namaProduk} (${p.ukuran})'),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
      error: (e, st) => const Text('Gagal memuat data produk'),
      loading: () => const LinearProgressIndicator(),
    );
  }
}
