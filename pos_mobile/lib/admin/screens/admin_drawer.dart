import 'package:flutter/material.dart';

// --- IMPORT TEMA & SCREEN (Sesuaikan foldernya kalau beda) ---
import '../../theme/colors.dart'; // Panggil AppColors dari sini
import '../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String activeMenu; // Menangkap menu mana yang lagi aktif

  const AdminDrawer({super.key, required this.activeMenu});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // =====================================
          // HEADER DRAWER (PROFIL ADMIN)
          // =====================================
          Container(
            height: 150, 
            width: double.infinity, 
            padding: const EdgeInsets.only(top: 40, left: 16),
            decoration: const BoxDecoration(color: AppColors.primary), // Background Toska
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 28), // Icon Toska
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Super Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Owner", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // =====================================
          // LIST MENU DRAWER
          // =====================================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTitle("MAIN MENU"),
                _buildMenuItem(context, Icons.dashboard, "Dashboard", activeMenu == "Dashboard", () {
                  if (activeMenu != "Dashboard") {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
                  } else {
                    Navigator.pop(context);
                  }
                }),
                _buildMenuItem(context, Icons.receipt_long, "Sales Report", activeMenu == "Sales Report", () {
                  _navigate(context, activeMenu, "Sales Report", const SalesReportScreen());
                }),
                
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(context, Icons.inventory_2_outlined, "Manage Products", activeMenu == "Manage Products", () {
                  _navigate(context, activeMenu, "Manage Products", const ManageProductScreen());
                }),
                _buildMenuItem(context, Icons.category_outlined, "Manage Categories", activeMenu == "Manage Categories", () {
                  _navigate(context, activeMenu, "Manage Categories", const ManageCategoryScreen());
                }),
                _buildMenuItem(context, Icons.people_outline, "Manage Cashiers", activeMenu == "Manage Cashiers", () {
                  _navigate(context, activeMenu, "Manage Cashiers", const ManageCashierScreen());
                }),
                _buildMenuItem(context, Icons.payments_outlined, "Payment Methods", activeMenu == "Payment Methods", () {
                  _navigate(context, activeMenu, "Payment Methods", const ManagePaymentScreen());
                }),

                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(context, Icons.warehouse_outlined, "Manage Stock", activeMenu == "Manage Stock", () {
                  _navigate(context, activeMenu, "Manage Stock", const ManageStockScreen());
                }),
                _buildMenuItem(context, Icons.local_shipping_outlined, "Purchase / Incoming", activeMenu == "Purchase / Incoming", () {
                  _navigate(context, activeMenu, "Purchase / Incoming", const PurchaseIncomingScreen());
                }),
                _buildMenuItem(context, Icons.schedule, "Manage Shifts", activeMenu == "Manage Shifts", () {
                  _navigate(context, activeMenu, "Manage Shifts", const ManageShiftsScreen());
                }),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(context, Icons.history, "Audit Trail", activeMenu == "Audit Trail", () {
                  _navigate(context, activeMenu, "Audit Trail", const AuditTrailScreen());
                }),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error), // Icon merah khusus logout
                  title: const Text("Logout", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Balik ke layar login dan buang semua history halaman
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================
  // FUNGSI PINTAR UNTUK NAVIGASI DRAWER
  // =====================================
  // Mencegah memory leak karena layar numpuk.
  void _navigate(BuildContext context, String current, String target, Widget screen) {
    if (current == target) {
      Navigator.pop(context); // Kalau diklik menu yang sama, tutup aja drawernya.
    } else {
      Navigator.pop(context); // Tutup drawer dulu
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen)); // Timpa layar saat ini dengan layar baru
    }
  }

  // Desain Judul Kategori (MAIN MENU, MASTER DATA, dll)
  Widget _buildMenuTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGrey, letterSpacing: 1.2)),
  );

  // Desain Item Menu yang bisa diklik
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppColors.primary), // <-- SEMUA ICON MENU SEKARANG WARNA TOSKA (PRIMARY)
    title: Text(title, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
    selected: isSelected, 
    selectedTileColor: AppColors.primary.withOpacity(0.1), // Efek toska transparan kalau lagi dipilih
    onTap: onTap,
  );
}