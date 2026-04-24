import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/shift_data.dart';

// Import halaman kasir
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'order_history_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';

class CashierDrawer extends StatelessWidget {
  final String activeMenu;
  const CashierDrawer({super.key, required this.activeMenu});

  // Fungsi warning lokal khusus untuk drawer
  void _showWarning(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          /// HEADER DRAWER KASIR
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: AppColors.accent, // Pakai aksen toska
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NaWa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Cashier", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),

          /// LIST MENU (ICON TOSKA, TEKS HITAM)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                _buildMenuItem(context, Icons.dashboard, "Dashboard", activeMenu == "Dashboard", () {
                  if (activeMenu != "Dashboard") {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (route) => false);
                  } else {
                    Navigator.pop(context);
                  }
                }),
                _buildMenuItem(context, Icons.point_of_sale, "Sales", activeMenu == "Sales", () {
                  if (!shiftActive.value) {
                    _showWarning(context, "Akses Ditolak", "Kamu harus memulai shift (Start Shift) terlebih dahulu.");
                    return;
                  }
                  if (activeMenu != "Sales") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesScreen()));
                  } else {
                    Navigator.pop(context);
                  }
                }),
                _buildMenuItem(context, Icons.receipt_long, "Order History", activeMenu == "Order History", () {
                  if (!shiftActive.value) {
                    _showWarning(context, "Akses Ditolak", "Kamu harus memulai shift (Start Shift) terlebih dahulu.");
                    return;
                  }
                  if (activeMenu != "Order History") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  } else {
                    Navigator.pop(context);
                  }
                }),
                _buildMenuItem(context, Icons.bar_chart, "Reports", activeMenu == "Reports", () {
                  if (activeMenu != "Reports") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                  } else {
                    Navigator.pop(context);
                  }
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text("Logout", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (shiftActive.value) {
                      _showWarning(context, "Gagal Logout", "Tolong akhiri shift (End Shift) terlebih dahulu sebelum logout.");
                      return;
                    }
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary), // Icon selalu toska
      title: Text(
        title, 
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87, // Teks hitam jika tidak aktif
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
        )
      ),
      selected: isSelected, 
      selectedTileColor: AppColors.bgLight.withOpacity(0.5), 
      onTap: onTap,
    );
  }
}