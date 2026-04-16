import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT (Manjat 4 folder sesuai struktur lib/admin/screens) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class ManageProductScreen extends StatefulWidget {
  const ManageProductScreen({super.key});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final supabase = Supabase.instance.client;

  String selectedFilter = "Semua";
  String searchQuery = ""; 
  bool isLoading = true;

  List<Map<String, dynamic>> dbProducts = [];
  List<Map<String, dynamic>> dbCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  // --- 1. AMBIL DATA LENGKAP ---
  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final catResponse = await supabase
          .from('ms_category_product')
          .select('id, category_name');
      
      final prodResponse = await supabase
          .from('ms_product')
          .select('''
            id, 
            name_product, 
            purchase_price,
            selling_price, 
            qty, 
            unit,
            image_url,
            category_id, 
            ms_category_product (category_name)
          ''')
          .eq('is_active', true)
          .order('name_product', ascending: true);

      setState(() {
        dbCategories = List<Map<String, dynamic>>.from(catResponse);
        dbProducts = List<Map<String, dynamic>>.from(prodResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal mengambil data: $e", isError: true);
    }
  }

  // --- 2. SIMPAN / UPDATE DATA ---
  Future<void> _saveProduct(Map<String, dynamic> data, {dynamic id}) async {
    try {
      if (id == null) {
        data['is_active'] = true;
        await supabase.from('ms_product').insert(data);
        _showSnackBar("Produk berhasil ditambahkan!");
      } else {
        await supabase.from('ms_product').update(data).eq('id', id);
        _showSnackBar("Produk berhasil diupdate!");
      }
      _fetchData(); 
    } catch (e) {
      _showSnackBar("Gagal menyimpan data.", isError: true);
    }
  }

  // --- 3. SOFT DELETE ---
  Future<void> _hapusProdukAman(dynamic id, String namaProduk) async {
    try {
      await supabase.from('ms_product').update({'is_active': false}).eq('id', id);
      _showSnackBar("$namaProduk berhasil dihapus!");
      _fetchData(); 
    } catch (e) {
      _showSnackBar("Gagal menghapus produk.", isError: true);
    }
  }

  String formatRupiah(dynamic amount) {
    int finalAmount = (amount is num) ? amount.toInt() : 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(finalAmount);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? PastelColors.rose : PastelColors.emerald,
      ),
    );
  }

  // --- FORM INPUT ANTI NULL ---
  void _tampilFormProduk([Map<String, dynamic>? produkYangDiedit]) {
    if (dbCategories.isEmpty) {
      _showSnackBar("Buat kategori dulu!", isError: true);
      return;
    }

    final bool isEdit = produkYangDiedit != null;
    final TextEditingController nameController = TextEditingController(text: isEdit ? produkYangDiedit['name_product'] : '');
    final TextEditingController purchasePriceController = TextEditingController(
      text: isEdit ? (produkYangDiedit['purchase_price'] as num?)?.toInt().toString() ?? '0' : ''
    );
    final TextEditingController sellingPriceController = TextEditingController(
      text: isEdit ? (produkYangDiedit['selling_price'] as num?)?.toInt().toString() ?? '0' : ''
    );
    final TextEditingController qtyController = TextEditingController(
      text: isEdit ? (produkYangDiedit['qty'] as num?)?.toInt().toString() ?? '0' : '0'
    );
    final TextEditingController unitController = TextEditingController(
      text: isEdit ? (produkYangDiedit['unit'] ?? 'pcs') : 'pcs'
    );
    final TextEditingController imageController = TextEditingController(
      text: isEdit ? (produkYangDiedit['image_url'] ?? '') : ''
    );

    dynamic selectedCategoryId = isEdit ? produkYangDiedit['category_id'] : dbCategories.first['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? "Edit Produk" : "Tambah Produk Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField("Nama Produk", Icons.inventory_2_outlined, nameController, TextInputType.text),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Harga Beli", Icons.shopping_bag_outlined, purchasePriceController, TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField("Harga Jual", Icons.payments_outlined, sellingPriceController, TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Stok", Icons.numbers, qtyController, TextInputType.number)),
                        const SizedBox(width: 12),
                        // PERBAIKAN IKON: Icons.straighten (huruf kecil)
                        Expanded(child: _buildTextField("Satuan", Icons.straighten, unitController, TextInputType.text)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField("URL Gambar", Icons.image_outlined, imageController, TextInputType.url),
                    const SizedBox(height: 12),
                    const Text("Pilih Kategori", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: selectedCategoryId,
                          items: dbCategories.map((cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['category_name'] ?? 'Unknown'))).toList(),
                          onChanged: (newValue) => setModalState(() => selectedCategoryId = newValue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: PastelColors.emerald, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () {
                          if (nameController.text.isEmpty) return;
                          Map<String, dynamic> data = {
                            'name_product': nameController.text,
                            'purchase_price': int.tryParse(purchasePriceController.text) ?? 0,
                            'selling_price': int.tryParse(sellingPriceController.text) ?? 0,
                            'qty': int.tryParse(qtyController.text) ?? 0,
                            'unit': unitController.text,
                            'category_id': selectedCategoryId,
                            'image_url': imageController.text.isEmpty ? null : imageController.text,
                          };
                          _saveProduct(data, id: isEdit ? produkYangDiedit['id'] : null);
                          Navigator.pop(context);
                        },
                        child: const Text("SIMPAN PRODUK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            keyboardType: type,
            decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.grey, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logika Filter & Search
    final filteredProducts = dbProducts.where((p) {
      String catName = p['ms_category_product']?['category_name'] ?? 'Lainnya';
      bool matchesFilter = (selectedFilter == "Semua" || catName == selectedFilter);
      bool matchesSearch = p['name_product'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    List<String> filterList = ["Semua"];
    filterList.addAll(dbCategories.map((c) => c['category_name'].toString()));

    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Manage Products")),
      appBar: AppBar(
        backgroundColor: PastelColors.mint, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Manage Products", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: PastelColors.sage, onPressed: () => _tampilFormProduk(), child: const Icon(Icons.add, color: Colors.white)),
      body: isLoading
        ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald))
        : Column(
            children: [
              // 1. SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: const InputDecoration(icon: Icon(Icons.search, color: Colors.grey), hintText: "Search product...", border: InputBorder.none),
                  ),
                ),
              ),
              // 2. KATEGORI FILTER (CHIPS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: filterList.map((k) => _buildFilterChip(k)).toList()),
              ),
              const SizedBox(height: 12),
              // 3. LIST PRODUK
              Expanded(
                child: filteredProducts.isEmpty
                  ? const Center(child: Text("Tidak ada produk."))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: (p['image_url'] != null && p['image_url'].toString().isNotEmpty)
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(p['image_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)))
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _tampilFormProduk(p);
                      if (val == 'delete') _konfirmasiHapus(p['id'], p['name_product']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(p['name_product'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(p['qty'] as num?)?.toInt() ?? 0} ${p['unit'] ?? 'pcs'}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(formatRupiah(p['selling_price']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: PastelColors.emerald)),
            ],
          )
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
        decoration: BoxDecoration(color: isSelected ? PastelColors.sage : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
      ),
    );
  }

  void _konfirmasiHapus(id, name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Produk?"),
        content: Text("Yakin mau menghapus '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(onPressed: () { Navigator.pop(ctx); _hapusProdukAman(id, name); }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
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