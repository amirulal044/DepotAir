import 'package:flutter/material.dart';

// Import semua layar yang ingin ditampilkan di tab bawah
import 'src/features/customers/presentation/customer_list_screen.dart';
import 'src/features/products/presentation/product_list_screen.dart';
import 'src/features/orders/presentation/order_list_screen.dart';
import 'src/features/reports/presentation/report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Menentukan tab awal yang terbuka (0 = Transaksi/Order)
  int _selectedIndex = 0;

  // Daftar layar yang akan dimasukkan ke dalam IndexedStack
  final List<Widget> _screens = const [
    OrderListScreen(),
    CustomerListScreen(),
    ProductListScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga keadaan (state) setiap halaman agar tidak di-rebuild saat pindah tab
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // Menggunakan NavigationBar (Material 3) yang lebih modern dan responsif
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
