import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- IMPORT SUPABASE
import '../theme/colors.dart';
import '../data/shift_data.dart';
import '../services/session_service.dart';

// --- IMPORT DUA HALAMAN DASHBOARD ---
import 'dashboard_screen.dart'; // Dashboard Kasir
import '../admin/screens/admin_dashboard_screen.dart'; // Dashboard Admin

// --- FUNGSI GLOBAL UNTUK POP-UP WARNING ---
void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller buat ngebaca ketikan username dan password
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); 
  
  bool _isLoading = false; // <-- INDIKATOR LOADING
  bool _isObscure = true;  // 🔥 VARIABEL BARU BUAT MATA PASSWORD 🔥

  // 🔥 FUNGSI LOGIN SUNGGUHAN KE SUPABASE 🔥
  Future<void> _loginToSupabase() async {
    String inputUsername = _usernameController.text.trim();
    String inputPassword = _passwordController.text.trim();

    if (inputUsername.isEmpty || inputPassword.isEmpty) {
      showWarningPopup(
        context,
        "Data Kosong",
        "Username dan Password wajib diisi bosku!",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Cek kecocokan username dan password di tabel ms_user
      final user = await supabase
          .from('ms_user')
          .select('id, role, username')
          .eq('username', inputUsername)
          .eq('password', inputPassword)
          .maybeSingle();

      setState(() => _isLoading = false);

      if (user == null) {
        // Gagal login: Data tidak ditemukan / password salah
        showWarningPopup(
          context,
          "Login Gagal",
          "Username atau Password salah!",
        );
        return;
      }

      // Kalau sukses, reset status shift
      shiftActive.value = false;

      // Ambil role-nya (apakah admin atau kasir)
      String role = user['role']?.toString().toLowerCase() ?? 'kasir';
      SessionService.setUser(
        id: user['id'].toString(),
        userName: user['username'].toString(),
        userRole: role,
      );

      if (mounted) {
        if (role == 'admin') {
          // Masuk Dashboard Admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          );
        } else {
          // Masuk Dashboard Kasir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showWarningPopup(context, "Error Sistem", "Terjadi kesalahan: $e");
    }
  }

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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Please enter your credentials',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    /// USERNAME
                    const Text(
                      'USERNAME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        hintText: 'Ketik username...',
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _passwordController, 
                      obscureText: _isObscure, // 🔥 PAKAI VARIABEL MATA 🔥
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        
                        // 🔥 TAMBAHAN ICON MATA DI SINI 🔥
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure; // Ganti status saat diklik
                            });
                          },
                        ),
                        
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
                        // Kalau lagi loading, tombolnya dimatikan (null)
                        onPressed: _isLoading ? null : _loginToSupabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        // Ganti teks jadi loading muter-muter kalau lagi proses
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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