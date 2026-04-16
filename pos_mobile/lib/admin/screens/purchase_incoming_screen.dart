import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

// --- IMPORT PATH (Sesuaikan dengan struktur folder proyek abang) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class PurchaseIncomingScreen extends StatefulWidget {
  const PurchaseIncomingScreen({super.key});

  @override
  State<PurchaseIncomingScreen> createState() => _PurchaseIncomingScreenState();
}

class _PurchaseIncomingScreenState extends State<PurchaseIncomingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  // List Riwayat Asli (Narik dari Supabase)
  List<Map<String, dynamic>> incomingHistory = [];
  
  // List Riwayat Hasil Pencarian (Ini yang ditampilin ke layar)
  List<Map<String, dynamic>> filteredHistory = [];

  // Controller buat ambil inputan
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); 
  
  // Controller khusus buat Search Bar
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIncomingData(); 
  }

  // --- FUNGSI NARIK DATA DARI SUPABASE ---
  Future<void> _fetchIncomingData() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tr_purchase_details')
          .select('''
            qty,
            created_at,
            ms_product ( name_product ),
            tr_purchase (
              ms_supplier ( supplier_name, telephone_number ) 
            )
          ''')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> fetchedData = [];
      for (var row in response) {
        String productName = "Produk Tidak Diketahui";
        if (row['ms_product'] != null) {
          productName = row['ms_product']['name_product'] ?? productName;
        }

        String supplierName = "Supplier Umum";
        String phoneNum = "-"; 
        
        if (row['tr_purchase'] != null && row['tr_purchase']['ms_supplier'] != null) {
          supplierName = row['tr_purchase']['ms_supplier']['supplier_name'] ?? supplierName;
          phoneNum = row['tr_purchase']['ms_supplier']['telephone_number']?.toString() ?? "-";
        }

        String formattedDate = "";
        if (row['created_at'] != null) {
          DateTime dt = DateTime.parse(row['created_at']).toLocal();
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        }

        fetchedData.add({
          'date': formattedDate,
          'product': productName,
          'qty': row['qty'] ?? 0,
          'supplier': supplierName,
          'phone': phoneNum, 
        });
      }

      if (mounted) {
        setState(() {
          incomingHistory = fetchedData;
          filteredHistory = fetchedData; // Masukin juga ke list pencarian di awal
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Supabase Purchase: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menarik data dari database"), backgroundColor: PastelColors.rose),
        );
      }
    }
  }

  // --- FUNGSI SEARCH (PENCARIAN DATA) ---
  void _runFilter(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = incomingHistory; // Kalau kosong, balikin ke data awal
    } else {
      results = incomingHistory.where((item) {
        // Cari berdasarkan Nama Produk ATAU Nama Supplier
        final productTitle = item['product'].toString().toLowerCase();
        final supplierTitle = item['supplier'].toString().toLowerCase();
        final input = query.toLowerCase();

        return productTitle.contains(input) || supplierTitle.contains(input);
      }).toList();
    }

    setState(() {
      filteredHistory = results;
    });
  }

  // --- POPUP DETAIL SAAT ITEM DI-KLIK ---
  void _showDetailPopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Detail Barang Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rowDetail("Nama Produk", item['product']?.toString() ?? "-"),
            _rowDetail("Jumlah Masuk", "+${item['qty']} pcs"),
            _rowDetail("Tanggal/Jam", item['date']?.toString() ?? "-"),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
            const Text("Info Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            _rowDetail("Supplier", item['supplier']?.toString() ?? "-"),
            _rowDetail("No. Telepon", item['phone']?.toString() ?? "-"),
            const SizedBox(height: 20),
            
            // TOMBOL HUBUNGI VIA WHATSAPP / TELEPON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat, color: Colors.white, size: 18), // Pake icon chat biar aman gak error merah
                label: const Text("Hubungi Supplier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  String phone = item['phone']?.toString() ?? "";
                  
                  if (phone == "-" || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon tidak tersedia", style: TextStyle(color: Colors.white)), backgroundColor: PastelColors.rose));
                    return;
                  }

                  // Rapihkan format nomor ke standar 628...
                  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanPhone.startsWith('0')) {
                    cleanPhone = '62${cleanPhone.substring(1)}';
                  }

                  final Uri waUrl = Uri.parse("https://wa.me/$cleanPhone");

                  try {
                    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
                      final Uri telUrl = Uri.parse("tel:$cleanPhone");
                      await launchUrl(telUrl);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka aplikasi", style: TextStyle(color: Colors.white)), backgroundColor: PastelColors.rose));
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  // --- POPUP INPUT BARANG MASUK ---
  void _showAddIncomingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Input Barang Masuk", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField(_productController, "Nama Produk", Icons.inventory_2_outlined),
              const SizedBox(height: 16),
              _buildTextField(_qtyController, "Jumlah (Qty)", Icons.add_shopping_cart, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_supplierController, "Nama Supplier", Icons.local_shipping_outlined),
              const SizedBox(height: 16), 
              _buildTextField(_phoneController, "No. Telepon Supplier", Icons.phone, isNumber: true), 
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: PastelColors.emerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    if (_productController.text.isEmpty || _qtyController.text.isEmpty) return;
                    
                    final newItem = {
                      'date': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                      'product': _productController.text,
                      'qty': int.tryParse(_qtyController.text) ?? 0,
                      'supplier': _supplierController.text.isNotEmpty ? _supplierController.text : 'Umum',
                      'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '-', 
                    };

                    setState(() {
                      incomingHistory.insert(0, newItem);
                      
                      // Bersihkan kolom search biar item baru langsung kelihatan
                      _searchController.clear();
                      _runFilter(""); 
                    });

                    _productController.clear(); 
                    _qtyController.clear(); 
                    _supplierController.clear(); 
                    _phoneController.clear(); 
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: PastelColors.emerald),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Purchase / Incoming")),
      appBar: AppBar(
        backgroundColor: PastelColors.mint, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Purchase / Incoming", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PastelColors.emerald,
        onPressed: _showAddIncomingSheet,
        icon: const Icon(Icons.add_box, color: Colors.white),
        label: const Text("Input Barang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald))
          : Column(
              children: [
                // 1. KOTAK HIJAU HEADER
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: PastelColors.emerald, borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Riwayat Barang Masuk", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Klik item untuk melihat detail & kontak supplier", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                // 2. KOTAK PENCARIAN (SEARCH BAR)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _runFilter(value), // Fitur filter jalan tiap diketik
                      decoration: InputDecoration(
                        hintText: "Cari nama barang / supplier...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: PastelColors.emerald),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. LIST RIWAYAT BARANG
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: filteredHistory.isEmpty // Pakai list hasil filter pencarian
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text("Data tidak ditemukan.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];
                              return GestureDetector(
                                onTap: () => _showDetailPopup(item), // MUNCULIN POPUP
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: PastelColors.mint.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.inventory_2, color: PastelColors.emerald),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['product']?.toString() ?? "Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            Text("${item['supplier'] ?? 'Umum'} • ${item['date'] ?? '-'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: PastelColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text("+${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.emerald)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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