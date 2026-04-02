import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../screens/login_screen.dart';
import 'manage_product_screen.dart'; // IMPORT HALAMAN MANAGE PRODUCT
import 'manage_category_screen.dart'; // IMPORT HALAMAN MANAGE PRODUCT

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(
        width: 260,
        child: AdminDrawer(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// NAVBAR ADMIN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28, color: PastelColors.grey),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const Column(
                    children: [
                      Text("Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PastelColors.grey)),
                      Text("Super Admin", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.notifications_none, color: PastelColors.grey),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: PastelColors.sage, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.person, color: Colors.white),
                      )
                    ],
                  )
                ],
              ),
            ),

            /// KONTEN DASHBOARD
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- HEADER INFO ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            SizedBox(width: 6),
                            Text("Hari Ini", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_drop_down, size: 16)
                          ],
                        ),
                      ),
                      const Text("Last Update: Hari ini, 11:30", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- SUMMARY CARDS ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildMainStatCard("Omzet Hari Ini", "Rp 12.450.000", "+12% dari kemarin", Icons.payments, PastelColors.emerald),
                            const SizedBox(height: 12),
                            _buildMainStatCard("Perlu Restock", "8 Produk", "Stok menipis", Icons.inventory_2, PastelColors.rose),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSmallStatCard("Transaksi", "32", "+5 transaksi", Icons.receipt_long, PastelColors.teal),
                            const SizedBox(height: 12),
                            _buildSmallStatCard("Kasir Aktif", "4 Kasir", "Sedang bertugas", Icons.people, PastelColors.sage),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- GRAFIK PLACEHOLDER ---
                  const Text("Omzet Penjualan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PastelColors.grey)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.show_chart, size: 40, color: PastelColors.emerald),
                        SizedBox(height: 8),
                        Text("Grafik Omzet 30 Hari Terakhir\n(Akan diintegrasikan)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- QUICK ACTIONS ---
                  const Text(
                    "Quick Actions", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PastelColors.grey)
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOMBOL MANAGE PRODUCTS DI DASHBOARD
                      Expanded(child: _buildQuickActionBtn("Manage\nProducts", Icons.inventory_2_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                      })),
                      const SizedBox(width: 8),
                      // Tombol lain biarin kosong dulu fungsinya
                      Expanded(child: _buildQuickActionBtn("Manage\nCashiers", Icons.people_outline, () {})),
                      const SizedBox(width: 8),
                      Expanded(child: _buildQuickActionBtn("Manage\nCategories", Icons.category_outlined, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageCategoryScreen()),
                        );
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _buildQuickActionBtn("Payment\nMethods", Icons.payments_outlined, () {})),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- AKTIVITAS TERBARU ---
                  const Text("Aktivitas Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PastelColors.grey)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildActivityItem(Icons.local_shipping, "Incoming Goods #PO-0012", "12 Produk • 1 jam lalu", "Diterima", PastelColors.sage),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.receipt_long, "Transaksi #INV-0025", "Rp 350.000 • 2 jam lalu", "Selesai", PastelColors.emerald),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.warning_amber_rounded, "Stok 'Beras 5kg' menipis", "Tersisa 3 pcs • 3 jam lalu", "Restock", PastelColors.rose),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PastelColors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon == Icons.inventory_2 ? Icons.warning_amber_rounded : Icons.trending_up, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4), 
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: PastelColors.grey)),
                const SizedBox(height: 4), 
                Text(sub, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REVISI WIDGET QUICK ACTION BTN: TAMBAH PARAMETER onTap ---
  Widget _buildQuickActionBtn(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, // Menjalankan fungsi navigasi pas diklik
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: PastelColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: PastelColors.emerald, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2, color: PastelColors.grey), 
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String sub, String status, Color statusColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: statusColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// ADMIN DRAWER (SIDEBAR KHUSUS ADMIN)
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(color: PastelColors.sage), 
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.admin_panel_settings, color: PastelColors.sage, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Super Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Owner", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTitle("MAIN MENU"),
                _buildMenuItem(Icons.dashboard, "Dashboard", true, () {
                  Navigator.pop(context); // Tutup drawer
                }),
                _buildMenuItem(Icons.receipt_long, "Sales Report", false, () {}),
                
                _buildMenuTitle("MASTER DATA"),
                
                // TOMBOL MANAGE PRODUCTS DI SIDEBAR
                _buildMenuItem(Icons.inventory_2_outlined, "Manage Products", false, () {
                  Navigator.pop(context); // Tutup drawer dulu biar rapi
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                }),
                
                _buildMenuItem(Icons.category_outlined, "Manage Categories", false, () {
                  Navigator.pop(context); // Tutup sidebar dulu
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageCategoryScreen()),
                  );
                }),
                _buildMenuItem(Icons.people_outline, "Manage Cashiers", false, () {}),
                _buildMenuItem(Icons.payments_outlined, "Payment Methods", false, () {}),
                
                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(Icons.warehouse_outlined, "Manage Stock", false, () {}),
                _buildMenuItem(Icons.local_shipping_outlined, "Purchase / Incoming", false, () {}),
                _buildMenuItem(Icons.schedule, "Manage Shifts", false, () {}),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(Icons.history, "Audit Trail", false, () {}),
                
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? PastelColors.emerald : PastelColors.grey),
      title: Text(
        title, 
        style: TextStyle(
          color: isSelected ? PastelColors.emerald : PastelColors.grey, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
        )
      ),
      selected: isSelected,
      selectedTileColor: PastelColors.mint.withOpacity(0.3),
      onTap: onTap,
    );
  }
}