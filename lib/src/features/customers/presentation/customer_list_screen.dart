import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repository.dart';
import 'customer_form_screen.dart';
import 'widgets/customer_dialogs.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data dari provider
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pelanggan')),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? const Center(child: Text('Belum ada pelanggan'))
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(customer.nama),
                    subtitle: Text(customer.alamat),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerFormScreen(
                            customer: customer,
                          ), // Mengirim data customer
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // 2. Panggil fungsi dari file terpisah
                        CustomerDialogs.showDeleteConfirm(
                          context,
                          ref,
                          customer,
                        );
                      },
                    ),
                  );
                },
              ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
