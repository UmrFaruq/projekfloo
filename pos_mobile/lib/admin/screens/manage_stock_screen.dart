import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class ManageStockScreen extends StatefulWidget {
  const ManageStockScreen({super.key});

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  
  String searchQuery = "";
  String selectedFilter = "Semua";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- AMBIL DATA PRODUK & KATEGORI ---
  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      // Ambil Kategori untuk Chips
      final catResponse = await supabase.from('ms_category_product').select('id, category_name');
      
      // Ambil Produk Lengkap dengan Nama Kategori
      final prodResponse = await supabase
          .from('ms_product')
          .select('''
            id, 
            name_product, 
            qty, 
            unit, 
            image_url, 
            category_id, 
            ms_category_product (category_name)
          ''')
          .eq('is_active', true)
          .order('name_product', ascending: true);

      if (mounted) {
        setState(() {
          categories = List<Map<String, dynamic>>.from(catResponse);
          products = List<Map<String, dynamic>>.from(prodResponse);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar("Gagal mengambil data dari server", isError: true);
      }
    }
  }

  Future<void> _updateStock(String id, int currentQty, int addedQty) async {
    try {
      final newQty = currentQty + addedQty;
      await supabase.from('ms_product').update({'qty': newQty}).eq('id', id);
      
      if (mounted) {
        _showSnackBar("Stok berhasil ditambahkan!");
        _fetchData(); 
      }
    } catch (e) {
      _showSnackBar("Gagal update stok", isError: true);
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  void _showSnackBar(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: isError ? PastelColors.rose : PastelColors.emerald)
    );
  }

  void _showAddStockDialog(Map<String, dynamic> product) {
    final TextEditingController qtyController = TextEditingController();
    final int currentQty = _safeInt(product['qty']);
    final String unit = product['unit'] ?? 'pcs';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tambah Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Produk: ${product['name_product']}", style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Jumlah barang masuk...",
                suffixText: unit,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PastelColors.emerald),
            onPressed: () {
              final int addedQty = int.tryParse(qtyController.text) ?? 0;
              if (addedQty > 0) {
                Navigator.pop(ctx);
                _updateStock(product['id'].toString(), currentQty, addedQty);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA FILTER KATEGORI & SEARCH ---
    final filteredProducts = products.where((p) {
      String catName = p['ms_category_product']?['category_name'] ?? 'Lainnya';
      bool matchesFilter = (selectedFilter == "Semua" || catName == selectedFilter);
      bool matchesSearch = p['name_product'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    List<String> filterList = ["Semua"];
    filterList.addAll(categories.map((c) => c['category_name'].toString()));

    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Manage Stock")),
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Manage Stock", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald))
          : Column(
              children: [
                // 1. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: "Cari nama produk...", border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // 2. CHIPS KATEGORI (SAMA SEPERTI MANAGE PRODUCT)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: filterList.map((k) => _buildFilterChip(k)).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. GRID VIEW PRODUK
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text("Produk tidak ditemukan.", style: TextStyle(color: Colors.grey)))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72 
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = filteredProducts[index];
                            final int qty = _safeInt(p['qty']);
                            final String unit = p['unit'] ?? 'pcs';
                            final bool isLowStock = qty < 10;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(20),
                                border: isLowStock ? Border.all(color: PastelColors.rose.withOpacity(0.6), width: 1.5) : null,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                      child: (p['image_url'] != null && p['image_url'].toString().isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16), 
                                            child: Image.network(p['image_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                                          )
                                        : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(p['name_product'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isLowStock ? "Menipis!" : "Aman", style: TextStyle(fontSize: 9, color: isLowStock ? PastelColors.rose : Colors.grey, fontWeight: FontWeight.bold)),
                                          Text("$qty $unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isLowStock ? PastelColors.rose : PastelColors.emerald)),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _showAddStockDialog(p),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: PastelColors.emerald, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PastelColors.sage : Colors.white, 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
      ),
    );
  }
}

/// DRAWER UNIVERSAL UNTUK SEMUA HALAMAN ADMIN (KECUALI DASHBOARD)
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