import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/customers/presentation/customer_list_screen.dart';
import 'src/features/products/presentation/product_list_screen.dart';
import 'src/features/orders/presentation/order_list_screen.dart';
import 'home_screen.dart';

void main() async {
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Simpan URL dan Key ke variabel agar rapi
  const String supabaseUrl = 'https://sxawyieonvxwzulugqvv.supabase.co';
  const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YXd5aWVvbnZ4d3p1bHVncXZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NzY3NTgsImV4cCI6MjA5MjE1Mjc1OH0.RAmjuyWHMvbyqzw3lF2_cmaM2vRpRdXohIK3U6bNOD0';

  try {
    // Inisialisasi Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    // Pesan Debug Berhasil
    debugPrint('=========================================');
    debugPrint('✅ KONEKSI SUPABASE BERHASIL!');
    debugPrint('🌐 URL Project: $supabaseUrl'); // Mengambil dari variabel lokal
    debugPrint('🚀 Status: SDK Ready');
    debugPrint('=========================================');
  } catch (e) {
    // Pesan Debug Gagal
    debugPrint('=========================================');
    debugPrint('❌ KONEKSI SUPABASE GAGAL!');
    debugPrint('⚠️ Error: $e');
    debugPrint('=========================================');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug di UI
      title: 'Depot Air Pro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home:
          const HomeScreen(), // Saya ganti Placeholder dengan widget sederhana
    );
  }
}
