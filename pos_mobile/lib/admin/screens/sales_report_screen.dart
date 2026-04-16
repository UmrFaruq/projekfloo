import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORT UNTUK EXCEL (.xlsx) ---
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool isLoading = true;

  int totalPendapatan = 0;
  int totalTransaksi = 0;
  List<Map<String, dynamic>> riwayatTransaksi = [];

  String filterWaktu = "Hari Ini"; 

  @override
  void initState() {
    super.initState();
    _fetchLaporanDummy();
  }

  // --- AMBIL DATA DUMMY ---
  Future<void> _fetchLaporanDummy() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); 

    final dummyData = [
      {"id_transaksi": "TRX-1001", "waktu": "14 Apr 2026, 09:15", "kasir": "NaWa", "total": 125000},
      {"id_transaksi": "TRX-1002", "waktu": "14 Apr 2026, 10:30", "kasir": "NaWa", "total": 45000},
      {"id_transaksi": "TRX-1003", "waktu": "14 Apr 2026, 11:45", "kasir": "Budi", "total": 210000},
      {"id_transaksi": "TRX-1004", "waktu": "14 Apr 2026, 13:20", "kasir": "NaWa", "total": 75000},
      {"id_transaksi": "TRX-1005", "waktu": "14 Apr 2026, 14:10", "kasir": "Siti", "total": 350000},
    ];

    int hitungPendapatan = 0;
    for (var trx in dummyData) {
      hitungPendapatan += trx['total'] as int;
    }

    if (mounted) {
      setState(() {
        riwayatTransaksi = dummyData;
        totalTransaksi = dummyData.length;
        totalPendapatan = hitungPendapatan;
        isLoading = false;
      });
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // =========================================================
  // --- FUNGSI EXCEL YANG SUDAH DIPERBAIKI (BEBAS ERROR MERAH) ---
  // =========================================================
  Future<void> _exportKeExcelReal() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan Penjualan'];
      
      // Hapus Sheet1 bawaan biar rapi
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1'); 
      }

      // 3. Tambahkan Judul (Pake TextCellValue karena strict type)
      sheetObject.appendRow([TextCellValue("LAPORAN PENJUALAN - $filterWaktu")]);
      sheetObject.appendRow([TextCellValue("Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}")]);
      sheetObject.appendRow([TextCellValue("")]); // Baris kosong

      // 4. Bikin Header Kolom
      sheetObject.appendRow([
        TextCellValue("ID Transaksi"),
        TextCellValue("Waktu"),
        TextCellValue("Kasir"),
        TextCellValue("Total Pendapatan"),
      ]);

      // 5. Masukin Data Transaksi
      for (var trx in riwayatTransaksi) {
        sheetObject.appendRow([
          TextCellValue(trx['id_transaksi'].toString()),
          TextCellValue(trx['waktu'].toString()),
          TextCellValue(trx['kasir'].toString()),
          IntCellValue(trx['total'] as int), // Ini biar jadi format Angka di Excel
        ]);
      }

      // 6. Baris Total di paling bawah
      sheetObject.appendRow([TextCellValue("")]);
      sheetObject.appendRow([
        TextCellValue("TOTAL PENDAPATAN"),
        TextCellValue(""),
        TextCellValue(""),
        IntCellValue(totalPendapatan),
      ]);

      // 7. Simpan ke File
      var fileBytes = excel.save();
      if (fileBytes == null) return; // Jaga-jaga kalau gagal generate

      final directory = await getTemporaryDirectory();
      String fileName = "Laporan_${filterWaktu.replaceAll(" ", "_")}.xlsx";
      final File file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(fileBytes);

      // 8. Share/Save
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Penjualan $filterWaktu');
      
    } catch (e) {
      debugPrint("Error Excel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal export .xlsx: $e"), backgroundColor: PastelColors.rose)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4), 
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Sales Report")),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F4),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Sales Report", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: PastelColors.emerald), 
            onPressed: () async {
              if (riwayatTransaksi.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data"), backgroundColor: PastelColors.rose));
                return;
              }
              await _exportKeExcelReal();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald))
          : Column(
              children: [
                // --- 1. FILTER WAKTU (CHIPS DI TENGAH) ---
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF4F7F4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((filter) {
                      bool isSelected = filterWaktu == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => filterWaktu = filter);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PastelColors.emerald : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // --- 2. SUMMARY CARDS ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: PastelColors.emerald, 
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: PastelColors.emerald.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text("Pendapatan", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                formatRupiah(totalPendapatan), 
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, color: Colors.grey, size: 22),
                                  SizedBox(width: 8),
                                  Text("Transaksi", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "$totalTransaksi", 
                                style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 3. LIST RIWAYAT TRANSAKSI ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text("Riwayat Transaksi Terbaru", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        Expanded(
                          child: riwayatTransaksi.isEmpty
                              ? const Center(child: Text("Belum ada transaksi hari ini.", style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: riwayatTransaksi.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final trx = riwayatTransaksi[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: PastelColors.mint.withOpacity(0.4), shape: BoxShape.circle),
                                        child: const Icon(Icons.check_circle, color: PastelColors.emerald, size: 24),
                                      ),
                                      title: Text(trx['id_transaksi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text("Kasir: ${trx['kasir']} • ${trx['waktu']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      trailing: Text(
                                        formatRupiah(trx['total']),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.emerald, fontSize: 14),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ==========================================
// DRAWER FULL ADMIN
// ==========================================
class FullAdminDrawer extends StatelessWidget {
  final String activeMenu;
  const FullAdminDrawer({super.key, required this.activeMenu});

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
                _buildMenuItem(context, Icons.dashboard, "Dashboard", activeMenu == "Dashboard", () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
                }),
                _buildMenuItem(context, Icons.receipt_long, "Sales Report", activeMenu == "Sales Report", () {
                  if (activeMenu != "Sales Report") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesReportScreen()));
                  else Navigator.pop(context);
                }),
                
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(context, Icons.inventory_2_outlined, "Manage Products", activeMenu == "Manage Products", () {
                  if (activeMenu != "Manage Products") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.category_outlined, "Manage Categories", activeMenu == "Manage Categories", () {
                  if (activeMenu != "Manage Categories") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageCategoryScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.people_outline, "Manage Cashiers", activeMenu == "Manage Cashiers", () {
                  if (activeMenu != "Manage Cashiers") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageCashierScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.payments_outlined, "Payment Methods", activeMenu == "Payment Methods", () {
                  if (activeMenu != "Payment Methods") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagePaymentScreen()));
                  else Navigator.pop(context);
                }),

                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(context, Icons.warehouse_outlined, "Manage Stock", activeMenu == "Manage Stock", () {
                  if (activeMenu != "Manage Stock") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageStockScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.local_shipping_outlined, "Purchase / Incoming", activeMenu == "Purchase / Incoming", () {
                  if (activeMenu != "Purchase / Incoming") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PurchaseIncomingScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.schedule, "Manage Shifts", activeMenu == "Manage Shifts", () {
                  if (activeMenu != "Manage Shifts") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageShiftsScreen()));
                  else Navigator.pop(context);
                }),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(context, Icons.history, "Audit Trail", activeMenu == "Audit Trail", () {
                  if (activeMenu != "Audit Trail") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuditTrailScreen()));
                  else Navigator.pop(context);
                }),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                ),
                const SizedBox(height: 20),
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

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: isSelected ? PastelColors.emerald : PastelColors.grey),
    title: Text(title, style: TextStyle(color: isSelected ? PastelColors.emerald : PastelColors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
    selected: isSelected, selectedTileColor: PastelColors.mint.withOpacity(0.3), onTap: onTap,
  );
}