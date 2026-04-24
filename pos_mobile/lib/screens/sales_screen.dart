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

// --- IMPORT FILE DRAWER KASIR YANG BARU ---
import 'cashier_drawer.dart'; 

void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error), // Pakai warna error toska-theme
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("OK", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
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
          const SnackBar(content: Text("Gagal mengambil data dari server."), backgroundColor: AppColors.error),
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

  // --- WIDGET CHIPS KATEGORI (MENGGUNAKAN APPCOLORS) ---
  Widget _buildFilterChip(String label) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white, // Toska jika dipilih
          borderRadius: BorderRadius.circular(30), 
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
      backgroundColor: AppColors.bgLight, // Background abu-abu toska
      drawer: const SizedBox(
        width: 250, 
        child: CashierDrawer(activeMenu: "Sales") // MANGGIL DRAWER BARU
      ),
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
                                  decoration: const BoxDecoration(color: AppColors.badgeRed, shape: BoxShape.circle),
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
                      // --- ICON PROFILE KANAN ATAS (MENGGUNAKAN APPCOLORS) ---
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), 
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
                    icon: Icon(Icons.search, color: AppColors.textGrey), 
                    hintText: "Cari produk...", 
                    hintStyle: TextStyle(color: AppColors.textGrey),
                    border: InputBorder.none
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
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
                    ? const Center(child: Text("Produk tidak ditemukan.", style: TextStyle(color: AppColors.textGrey)))
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