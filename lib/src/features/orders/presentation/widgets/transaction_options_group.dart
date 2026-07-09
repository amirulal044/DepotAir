import 'package:flutter/material.dart';
import '../../../products/domain/product_model.dart';

class TransactionOptionsGroup extends StatelessWidget {
  final Product? selectedProduct;
  final bool isAntar;
  final bool isBagiHasil;
  final bool isPakaiKupon;
  final Function(bool) onAntarChanged;
  final Function(bool) onBagiHasilChanged;
  final Function(bool) onKuponChanged;

  const TransactionOptionsGroup({
    super.key,
    this.selectedProduct,
    required this.isAntar,
    required this.isBagiHasil,
    required this.isPakaiKupon,
    required this.onAntarChanged,
    required this.onBagiHasilChanged,
    required this.onKuponChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. FITUR ANTAR
        SwitchListTile(
          title: const Text('Antar ke Rumah (+Rp 1.000/galon)'),
          value: isAntar,
          onChanged: onAntarChanged,
        ),

        // 2. FITUR BAGI HASIL (Hanya muncul jika ambil di tempat & 19L)
        if (!isAntar && selectedProduct?.ukuran == "19 Liter")
          SwitchListTile(
            title: const Text('Sistem Bagi Hasil (10%)'),
            value: isBagiHasil,
            onChanged: onBagiHasilChanged,
          ),

        // 3. FITUR TUKAR KUPON (Hanya muncul jika produk 19L)
        if (selectedProduct?.ukuran == "19 Liter")
          SwitchListTile(
            secondary: const Icon(
              Icons.confirmation_number,
              color: Colors.orange,
            ),
            title: const Text('Gunakan Kupon Gratis'),
            subtitle: const Text('10 Kupon = 1 Galon Gratis'),
            value: isPakaiKupon,
            onChanged: onKuponChanged,
          ),
      ],
    );
  }
}
