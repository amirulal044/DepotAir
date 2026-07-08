import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer_model.dart';

class CustomerDialogs {
  // Kita buat fungsi static agar bisa dipanggil tanpa inisialisasi class
  static void showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan?'),
        content: Text('Apakah Anda yakin ingin menghapus ${customer.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Jalankan fungsi delete
              await ref
                  .read(customerRepositoryProvider)
                  .deleteCustomer(customer.id);

              // Refresh data
              ref.invalidate(customersListProvider);

              // Tutup dialog
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
