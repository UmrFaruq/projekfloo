import 'package:flutter/material.dart';

// --- IMPORT SERVICE SUPABASE ---
import 'services/supabase_service.dart';

// --- IMPORT SCREENS ---
import 'screens/login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/screens/manage_product_screen.dart';
import 'admin/screens/manage_category_screen.dart';

void main() async {
  // Wajib ditambahin ini kalau main() pakai async
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI SUPABASE ---
  // Memanggil fungsi initialize() dari SupabaseService yang ada di folder services
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Gagal inisialisasi Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        useMaterial3: true,
      ),

      // Halaman pertama kali dibuka adalah Login
      home: const LoginScreen(),

      // Daftar rute navigasi antar halaman
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/manage_product': (context) => const ManageProductScreen(),
        '/manage_category': (context) => const ManageCategoryScreen(),
      },
    );
  }
}