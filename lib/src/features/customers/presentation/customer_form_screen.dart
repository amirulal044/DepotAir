import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repository.dart';
import '../domain/customer_model.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer; // Jika null = Tambah, Jika ada isi = Edit
  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _hpController;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    // Isi controller jika sedang mode Edit
    _namaController = TextEditingController(text: widget.customer?.nama);
    _alamatController = TextEditingController(text: widget.customer?.alamat);
    _hpController = TextEditingController(text: widget.customer?.nomorHp);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);

    try {
      if (widget.customer == null) {
        // Mode Tambah
        await repo.addCustomer(
          _namaController.text,
          _alamatController.text,
          _hpController.text,
        );
      } else {
        // Mode Edit
        await repo.updateCustomer(
          widget.customer!.id,
          _namaController.text,
          _alamatController.text,
          _hpController.text,
        );
      }

      // Refresh list pelanggan setelah simpan
      ref.invalidate(customersListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              TextFormField(
                controller: _hpController,
                decoration: const InputDecoration(
                  labelText: 'No. HP (WhatsApp)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Simpan Data'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
