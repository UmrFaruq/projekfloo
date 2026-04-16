import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../data/cart_data.dart';
import 'dashboard_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import '../data/shift_data.dart';

// --- WARNA SOLID MENYESUAIKAN REFERENSI ORDER HISTORY ---
const Color solidGreen = Color(0xFF00897B); // Hijau Tegas
const Color bgKusam = Color(0xFFF4F7F4); // Background abu-abu kehijauan

void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: PastelColors.rose),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("OK", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String selectedCategory = "Semua";
  String searchQuery = "";

  bool isLoading = true;
  List<Product> databaseProducts = [];
  List<String> databaseCategories = ["Semua"];

  @override
  void initState() {
    super.initState();
    _fetchDataFromSupabase();
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  Future<void> _fetchDataFromSupabase() async {
    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final categoryResponse = await supabase.from('ms_category_product').select('category_name');
      List<String> fetchedCategories = ["Semua"];
      for (var cat in categoryResponse) {
        if (cat['category_name'] != null) {
          fetchedCategories.add(cat['category_name'].toString());
        }
      }

      final productResponse = await supabase
          .from('ms_product')
          .select('id, name_product, selling_price, qty, unit, image_url, ms_category_product (category_name)')
          .eq('is_active', true);

      List<Product> fetchedProducts = [];
      for (var prod in productResponse) {
        String catName = "Lainnya";
        if (prod['ms_category_product'] != null && prod['ms_category_product']['category_name'] != null) {
          catName = prod['ms_category_product']['category_name'];
        }

        fetchedProducts.add(
          Product(
            id: prod['id']?.toString() ?? '', 
            name: prod['name_product']?.toString() ?? 'Tanpa Nama', 
            price: _safeInt(prod['selling_price']), 
            category: catName, 
            image: prod['image_url']?.toString(), 
            qty: _safeInt(prod['qty']),
            unit: prod['unit']?.toString() ?? 'pcs',
          ),
        );
      }

      setState(() {
        databaseCategories = fetchedCategories;
        databaseProducts = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data dari server."), backgroundColor: PastelColors.rose),
        );
      }
    }
  }

  List<Product> getFilteredProducts() {
    return databaseProducts.where((product) {
      bool matchCategory = selectedCategory == "Semua" || product.category == selectedCategory;
      bool matchSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  // --- WIDGET CHIPS KATEGORI (SOLID SEPERTI ORDER HISTORY) ---
  Widget _buildFilterChip(String label) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? solidGreen : Colors.white,
          borderRadius: BorderRadius.circular(30), // Oval penuh
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87, 
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return Scaffold(
      backgroundColor: bgKusam, // Background persis Order History
      drawer: const SizedBox(width: 280, child: AppDrawer()),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER APP BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28, color: Colors.black87), 
                      onPressed: () => Scaffold.of(context).openDrawer()
                    ),
                  ),
                  const Text("Sales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, size: 28, color: Colors.black87),
                            onPressed: () async => await Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
                          ),
                          Positioned(
                            right: 4, top: 4,
                            child: ValueListenableBuilder(
                              valueListenable: cartNotifier,
                              builder: (context, value, child) {
                                if (value == 0) return const SizedBox();
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: PastelColors.rose, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // --- ICON PROFILE KANAN ATAS (SOLID GREEN) ---
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: solidGreen, borderRadius: BorderRadius.circular(12)), 
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey), 
                    hintText: "Cari produk...", 
                    border: InputBorder.none
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: solidGreen)))
            else ...[
              // --- KATEGORI CHIPS ---
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: databaseCategories.map((catName) => _buildFilterChip(catName)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- GRID PRODUK ---
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text("Produk tidak ditemukan.", style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 14, 
                          mainAxisSpacing: 14, 
                          childAspectRatio: 0.72
                        ),
                        itemBuilder: (context, index) => ProductCard(product: filteredProducts[index]),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// APP DRAWER (IDENTIK ORDER HISTORY)
// ============================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // --- HEADER DRAWER SOLID GREEN ---
          Container(
            height: 170,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
            decoration: const BoxDecoration(color: solidGreen),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.person, color: solidGreen, size: 32),
                ),
                const SizedBox(width: 16),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NaWa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                    SizedBox(height: 4),
                    Text("Cashier", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, Icons.dashboard, "Dashboard", false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
                _buildMenuItem(context, Icons.point_of_sale, "Sales", true, () => Navigator.pop(context)),
                _buildMenuItem(context, Icons.receipt_long, "Order History", false, () {
                  if (!shiftActive.value) {
                    showWarningPopup(context, "Akses Ditolak", "Kamu harus memulai shift (Start Shift) terlebih dahulu.");
                    return;
                  }
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                }),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.logout, color: PastelColors.rose, size: 26),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () {
                    if (shiftActive.value) {
                      showWarningPopup(context, "Gagal Logout", "Tolong akhiri shift (End Shift) terlebih dahulu sebelum logout.");
                      return;
                    }
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MENU ITEM TANPA BACKGROUND HIGHLIGHT (SESUAI REFERENSI) ---
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: isSelected ? solidGreen : Colors.grey.shade600, size: 26),
      title: Text(
        title, 
        style: TextStyle(
          color: isSelected ? solidGreen : Colors.grey.shade700, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 16
        )
      ),
      onTap: onTap,
    );
  }
}