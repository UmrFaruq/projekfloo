import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../../theme/colors.dart';
import '../../screens/login_screen.dart';
import 'manage_product_screen.dart'; 
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart'; 
import 'manage_payment_screen.dart'; 
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int jumlahKasirAktif = 0;
  
  // --- VARIABEL UNTUK PAJAK (TAX) ---
  double currentTax = 11.0; 

  // --- VARIABEL UNTUK FILTER DASHBOARD ---
  String filterWaktu = "Hari Ini";
  String lastUpdate = "";
  
  // Data dummy yang berubah saat filter ditekan
  String txtOmzet = "Rp 12.450.000";
  String txtTransaksi = "32";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _hitungKasirAktif();
  }

  void _updateTime() {
    setState(() {
      lastUpdate = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  // --- LOGIKA FILTER WAKTU (DUMMY) ---
  void _ubahFilter(String filterBaru) {
    setState(() {
      filterWaktu = filterBaru;
      _updateTime(); 

      if (filterBaru == "Hari Ini") {
        txtOmzet = "Rp 12.450.000";
        txtTransaksi = "32";
      } else if (filterBaru == "Minggu Ini") {
        txtOmzet = "Rp 85.200.000";
        txtTransaksi = "215";
      } else if (filterBaru == "Bulan Ini") {
        txtOmzet = "Rp 340.500.000";
        txtTransaksi = "1,042";
      }
    });
  }

  // --- FUNGSI MENGHITUNG JUMLAH KASIR DARI SUPABASE ---
  Future<void> _hitungKasirAktif() async {
    try {
      final response = await Supabase.instance.client
          .from('ms_user')
          .select('id')
          .eq('role', 'kasir'); 
      
      if (mounted) {
        setState(() {
          jumlahKasirAktif = response.length;
        });
      }
    } catch (e) {
      debugPrint("Gagal menghitung kasir: $e");
    }
  }

  // --- FUNGSI MUNCULIN POPUP PAJAK ---
  void _showTaxSettingDialog() {
    TextEditingController taxController = TextEditingController(text: currentTax.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.percent, color: PastelColors.emerald),
            SizedBox(width: 8),
            Text("Atur Pajak (Tax)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Masukkan persentase pajak yang akan diterapkan pada transaksi kasir.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: taxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Besaran Pajak",
                suffixText: "%",
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.emerald),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PastelColors.emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                currentTax = double.tryParse(taxController.text) ?? currentTax;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Pajak berhasil diubah menjadi $currentTax%"), backgroundColor: PastelColors.emerald)
              );
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
                      IconButton(
                        icon: const Icon(Icons.percent, color: PastelColors.emerald),
                        tooltip: "Atur Pajak",
                        onPressed: _showTaxSettingDialog,
                      ),
                      const SizedBox(width: 8),
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
                      PopupMenuButton<String>(
                        onSelected: _ubahFilter,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: "Hari Ini", child: Text("Hari Ini")),
                          const PopupMenuItem(value: "Minggu Ini", child: Text("Minggu Ini")),
                          const PopupMenuItem(value: "Bulan Ini", child: Text("Bulan Ini")),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(filterWaktu, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_drop_down, size: 16)
                            ],
                          ),
                        ),
                      ),
                      Text("Last Update: Hari ini, $lastUpdate", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                            // SEMUA WARNA DIUBAH KE EMERALD
                            _buildMainStatCard("Omzet $filterWaktu", txtOmzet, "+12% tren naik", Icons.payments, PastelColors.emerald),
                            const SizedBox(height: 12),
                            _buildMainStatCard("Perlu Restock", "8 Produk", "Stok menipis", Icons.inventory_2, PastelColors.emerald),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            // SEMUA WARNA DIUBAH KE EMERALD
                            _buildSmallStatCard("Transaksi", txtTransaksi, "Sukses diproses", Icons.receipt_long, PastelColors.emerald),
                            const SizedBox(height: 12),
                            _buildSmallStatCard("Kasir Aktif", "$jumlahKasirAktif Kasir", "Terdaftar di sistem", Icons.people, PastelColors.emerald),
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
                        Text("Grafik akan tampil setelah ada\ndata transaksi dari Kasir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                      Expanded(child: _buildQuickActionBtn("Manage\nProducts", Icons.inventory_2_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _buildQuickActionBtn("Manage\nCashiers", Icons.people_outline, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCashierScreen()));
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _buildQuickActionBtn("Manage\nCategories", Icons.category_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoryScreen()));
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _buildQuickActionBtn("Payment\nMethods", Icons.payments_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePaymentScreen()));
                      })),
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
                        // SEMUA WARNA DIUBAH KE EMERALD
                        _buildActivityItem(Icons.local_shipping, "Incoming Goods #PO-0012", "12 Produk • 1 jam lalu", "Diterima", PastelColors.emerald),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.receipt_long, "Transaksi #INV-0025", "Rp 350.000 • 2 jam lalu", "Selesai", PastelColors.emerald),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.warning_amber_rounded, "Stok 'Beras 5kg' menipis", "Tersisa 3 pcs • 3 jam lalu", "Restock", PastelColors.emerald),
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

  Widget _buildQuickActionBtn(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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

/// ADMIN DRAWER
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 150, width: double.infinity, padding: const EdgeInsets.only(top: 40, left: 16),
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
                  mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Super Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Owner", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTitle("MAIN MENU"),
                _buildMenuItem(Icons.dashboard, "Dashboard", true, () => Navigator.pop(context)),
                _buildMenuItem(Icons.receipt_long, "Sales Report", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesReportScreen()));
                }),
                
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(Icons.inventory_2_outlined, "Manage Products", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                }),
                _buildMenuItem(Icons.category_outlined, "Manage Categories", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoryScreen()));
                }),
                _buildMenuItem(Icons.people_outline, "Manage Cashiers", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCashierScreen()));
                }),
                _buildMenuItem(Icons.payments_outlined, "Payment Methods", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePaymentScreen()));
                }),

                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(Icons.warehouse_outlined, "Manage Stock", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStockScreen()));
                }),
                _buildMenuItem(Icons.local_shipping_outlined, "Purchase / Incoming", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseIncomingScreen()));
                }),
                _buildMenuItem(Icons.schedule, "Manage Shifts", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageShiftsScreen()));
                }),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(Icons.history, "Audit Trail", false, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditTrailScreen()));
                }),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
  );

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: isSelected ? PastelColors.emerald : PastelColors.grey),
    title: Text(title, style: TextStyle(color: isSelected ? PastelColors.emerald : PastelColors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
    selected: isSelected, selectedTileColor: PastelColors.mint.withOpacity(0.3), onTap: onTap,
  );
}