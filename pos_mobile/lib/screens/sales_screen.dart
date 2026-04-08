import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../data/cart_data.dart';
import 'dashboard_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import '../data/shift_data.dart';

void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: PastelColors.rose),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(
              color: PastelColors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  // --- FUNGSI NARIK DATA (SUDAH DISESUAIKAN DENGAN SKEMA ASLIMU) ---
  Future<void> _fetchDataFromSupabase() async {
    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Ambil data dari tabel ms_category_product
      final categoryResponse = await supabase
          .from('ms_category_product')
          .select('category_name');
      List<String> fetchedCategories = ["Semua"];
      for (var cat in categoryResponse) {
        if (cat['category_name'] != null) {
          fetchedCategories.add(cat['category_name'].toString());
        }
      }

      // 2. Ambil data dari tabel ms_product (Pake JOIN ke ms_category_product)
      // Kita juga filter cuma ngambil yang is_active = true
      final productResponse = await supabase
          .from('ms_product')
          .select('''
        id,
        name_product,
        selling_price,
        image_url,
        ms_category_product (
          category_name
        )
      ''')
          .eq('is_active', true);

      List<Product> fetchedProducts = [];
      for (var prod in productResponse) {
        // Cek kategori dari hasil relasi/join
        String catName = "Lainnya";
        if (prod['ms_category_product'] != null &&
            prod['ms_category_product']['category_name'] != null) {
          catName = prod['ms_category_product']['category_name'];
        }

        fetchedProducts.add(
          Product(
            id: prod['id'].toString(), // Pake ID aslimu yang UUID
            name: prod['name_product'] ?? 'Tanpa Nama', // Kolom name_product
            price: double.parse(
              prod['selling_price'].toString(),
            ).toInt(), // Kolom selling_price
            category: catName, // Hasil Join
            image: prod['image_url'], // Kolom image_url
          ),
        );
      }

      setState(() {
        databaseCategories = fetchedCategories;
        databaseProducts = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      print("Error Supabase: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengambil data dari server."),
            backgroundColor: PastelColors.rose,
          ),
        );
      }
    }
  }

  List<Product> getFilteredProducts() {
    return databaseProducts.where((product) {
      bool matchCategory =
          selectedCategory == "Semua" || product.category == selectedCategory;
      bool matchSearch = product.name.toLowerCase().contains(searchQuery);
      return matchCategory && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 250, child: AppDrawer()),
      body: SafeArea(
        child: Column(
          children: [
            /// NAVBAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Row(
                    children: [
                      /// CART ICON
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart, size: 28),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: ValueListenableBuilder(
                              valueListenable: cartNotifier,
                              builder: (context, value, child) {
                                if (value == 0) return const SizedBox();
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: PastelColors.rose,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      /// PROFILE ICON
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PastelColors.emerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Search product...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // KONDISI LOADING: Munculin muter-muter pas narik data
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: PastelColors.emerald),
                ),
              )
            else ...[
              /// CATEGORY (OTOMATIS DARI SUPABASE)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: databaseCategories.length,
                  itemBuilder: (context, index) {
                    String catName = databaseCategories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        title: catName,
                        isSelected: selectedCategory == catName,
                        onTap: () {
                          setState(() {
                            selectedCategory = catName;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// PRODUCT GRID (OTOMATIS DARI SUPABASE)
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada produk, coba isi database ges!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.75,
                            ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: filteredProducts[index]);
                        },
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
// APP DRAWER (Tetap Sama)
// ============================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
            decoration: const BoxDecoration(color: PastelColors.emerald),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: PastelColors.emerald,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NaWa",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Cashier",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.dashboard,
                    color: PastelColors.grey,
                  ),
                  title: const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: PastelColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.point_of_sale,
                    color: PastelColors.emerald,
                  ),
                  title: const Text(
                    "Sales",
                    style: TextStyle(
                      color: PastelColors.emerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: PastelColors.grey,
                  ),
                  title: const Text(
                    "Order History",
                    style: TextStyle(
                      color: PastelColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    if (!shiftActive.value) {
                      showWarningPopup(
                        context,
                        "Akses Ditolak",
                        "Kamu harus memulai shift (Start Shift) terlebih dahulu.",
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: PastelColors.rose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    if (shiftActive.value) {
                      showWarningPopup(
                        context,
                        "Gagal Logout",
                        "Tolong akhiri shift (End Shift) terlebih dahulu sebelum logout.",
                      );
                      return;
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
