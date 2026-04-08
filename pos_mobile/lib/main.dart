import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- IMPORT SUPABASE

// --- IMPORT SCREENS ---
import 'screens/login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/screens/manage_product_screen.dart';
import 'admin/screens/manage_category_screen.dart';

void main() async {
  // Wajib ditambahin ini kalau main() pakai async
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI SUPABASE ---
  // Masukkan URL dan Anon Key dari project Supabase kamu
  await Supabase.initialize(
    url: 'https://shoxoghitibiskqxphrj.supabase.co',
    anonKey: 'sb_publishable_n6NzXsS99FR6aO9tfbU9Yg_85dUVvmq',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),

      home: const LoginScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/manage_product': (context) => const ManageProductScreen(),
        '/manage_category': (context) => const ManageCategoryScreen(),
      },
    );
  }
}
