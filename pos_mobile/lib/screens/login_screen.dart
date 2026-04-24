import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/shift_data.dart';

// --- IMPORT DUA HALAMAN DASHBOARD ---
import 'dashboard_screen.dart'; // Dashboard Kasir
import '../admin/screens/admin_dashboard_screen.dart'; // Dashboard Admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller buat ngebaca ketikan username
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// LOGO
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGrey,
                  ),
                  children: [
                    TextSpan(text: 'Floo'),
                    TextSpan(text: '.'),
                    TextSpan(text: 'ID'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// LOGIN CARD
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Please enter your credentials',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    /// USERNAME
                    const Text(
                      'USERNAME',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _usernameController, // <-- Pasang controller di sini
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        hintText: 'Ketik "admin" atau "kasir"', 
                        filled: true,
                        fillColor: AppColors.bgLight.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// PASSWORD
                    const Text(
                      'PASSWORD',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: const Icon(Icons.visibility_off_outlined),
                        hintText: '••••••••',
                        filled: true,
                        fillColor: AppColors.bgLight.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Ambil teks username dan ubah jadi huruf kecil semua biar aman
                          String inputUsername = _usernameController.text.trim().toLowerCase();

                          if (inputUsername.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Isi username dulu ges!"), backgroundColor: AppColors.error),
                            );
                            return;
                          }

                          /// RESET SHIFT SETIAP LOGIN
                          shiftActive.value = false;

                          // --- LOGIKA CABANG NAVIGASI ---
                          if (inputUsername.contains('admin')) {
                            // Kalau ngetik admin -> Masuk Dashboard Admin
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            );
                          } else {
                            // Kalau ngetik selain admin (misal kasir_01) -> Masuk Dashboard Kasir
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}