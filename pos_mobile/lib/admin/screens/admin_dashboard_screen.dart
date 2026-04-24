import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'manage_product_screen.dart'; 
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart'; 
import 'manage_payment_screen.dart'; 

// --- IMPORT FILE DRAWER ADMIN SENTRAL ---
import 'admin_drawer.dart';

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
            Icon(Icons.percent, color: AppColors.primary), // Toska
            SizedBox(width: 8),
            Text("Atur Pajak (Tax)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Masukkan persentase pajak yang akan diterapkan pada transaksi kasir.", style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: taxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Besaran Pajak",
                labelStyle: const TextStyle(color: AppColors.textGrey),
                suffixText: "%",
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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
            child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Toska
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                currentTax = double.tryParse(taxController.text) ?? currentTax;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Pajak berhasil diubah menjadi $currentTax%"), backgroundColor: AppColors.primary)
              );
            },
            child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- MENGGUNAKAN DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260,
        child: AdminDrawer(activeMenu: "Dashboard"), 
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
                      icon: const Icon(Icons.menu, size: 28, color: Colors.black87), // Hitam
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const Column(
                    children: [
                      Text("Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Hitam
                      Text("Super Admin", style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.percent, color: AppColors.primary), // Toska
                        tooltip: "Atur Pajak",
                        onPressed: _showTaxSettingDialog,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)), // Toska gelap
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
                          const PopupMenuItem(value: "Hari Ini", child: Text("Hari Ini", style: TextStyle(color: Colors.black87))),
                          const PopupMenuItem(value: "Minggu Ini", child: Text("Minggu Ini", style: TextStyle(color: Colors.black87))),
                          const PopupMenuItem(value: "Bulan Ini", child: Text("Bulan Ini", style: TextStyle(color: Colors.black87))),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text(filterWaktu, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)), // Hitam
                              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87)
                            ],
                          ),
                        ),
                      ),
                      Text("Last Update: Hari ini, $lastUpdate", style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
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
                            // Warna pakai standar AppColors
                            _buildMainStatCard("Omzet $filterWaktu", txtOmzet, "+12% tren naik", Icons.payments, AppColors.primary),
                            const SizedBox(height: 12),
                            _buildMainStatCard("Perlu Restock", "8 Produk", "Stok menipis", Icons.inventory_2, AppColors.error), // Warning pakai merah
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSmallStatCard("Transaksi", txtTransaksi, "Sukses diproses", Icons.receipt_long, AppColors.primary),
                            const SizedBox(height: 12),
                            _buildSmallStatCard("Kasir Aktif", "$jumlahKasirAktif Kasir", "Terdaftar di sistem", Icons.people, AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- GRAFIK PLACEHOLDER ---
                  const Text("Omzet Penjualan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.show_chart, size: 40, color: AppColors.primary), // Toska
                        SizedBox(height: 8),
                        Text("Grafik akan tampil setelah ada\ndata transaksi dari Kasir.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- QUICK ACTIONS ---
                  const Text(
                    "Quick Actions", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
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
                  const Text("Aktivitas Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                    ),
                    child: Column(
                      children: [
                        _buildActivityItem(Icons.local_shipping, "Incoming Goods #PO-0012", "12 Produk • 1 jam lalu", "Diterima", AppColors.primaryDark),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.receipt_long, "Transaksi #INV-0025", "Rp 350.000 • 2 jam lalu", "Selesai", AppColors.primary),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildActivityItem(Icons.warning_amber_rounded, "Stok 'Beras 5kg' menipis", "Tersisa 3 pcs • 3 jam lalu", "Restock", AppColors.error), // Error merah toska
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
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), // Value Hitam Tegas
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
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
      ),
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
                Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                const SizedBox(height: 4), 
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)), // Value hitam tegas
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
              decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)), // Toska muda
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2, color: Colors.black87), // Teks hitam
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
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)), // Teks hitam
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}