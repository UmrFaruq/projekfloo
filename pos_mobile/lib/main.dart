import 'package:flutter/material.dart';

// --- IMPORT SCREENS ---
import 'screens/login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart'; 
import 'admin/screens/manage_product_screen.dart';
import 'admin/screens/manage_category_screen.dart';

void main() {
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
        useMaterial3: true, // Biar tampilan button & komponen lebih modern
      ),
      
      // Pintu utama aplikasi: Halaman Login
      home: const LoginScreen(), 
      
      // Daftarkan rute halaman biar navigasi Navigator.pushNamed bisa jalan
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/manage_product': (context) => const ManageProductScreen(),
        '/manage_category': (context) => const ManageCategoryScreen(),
      },
    );
  }
}