import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customers/domain/customer_model.dart';

class CustomerSelectorField extends StatelessWidget {
  final AsyncValue<List<Customer>> customersAsync;
  final Customer? selectedCustomer;
  final Function(Customer?) onChanged;

  const CustomerSelectorField({
    super.key,
    required this.customersAsync,
    required this.selectedCustomer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return customersAsync.when(
      data: (list) => DropdownButtonFormField<Customer>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Pilih Pelanggan',
          prefixIcon: Icon(Icons.person_outline),
          border: OutlineInputBorder(),
        ),
        value: selectedCustomer,
        items: list
            .map((c) => DropdownMenuItem(value: c, child: Text(c.nama)))
            .toList(),
        onChanged: onChanged,
      ),
      error: (e, st) => const Text('Gagal memuat data pelanggan'),
      loading: () => const LinearProgressIndicator(),
    );
  }
}
