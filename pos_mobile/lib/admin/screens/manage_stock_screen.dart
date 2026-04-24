import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

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
      SnackBar(content: Text(m), backgroundColor: isError ? AppColors.error : AppColors.primary) // Merah untuk error, Toska untuk sukses
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
        title: const Text("Tambah Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), // Judul hitam
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Produk: ${product['name_product']}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Nama produk hitam
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Teks input hitam tebal
              decoration: InputDecoration(
                hintText: "Jumlah barang masuk...",
                hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
                suffixText: unit,
                suffixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold), // Suffix toska
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Toska
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              final int addedQty = int.tryParse(qtyController.text) ?? 0;
              if (addedQty > 0) {
                Navigator.pop(ctx);
                _updateStock(product['id'].toString(), currentQty, addedQty);
              }
            },
            child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Manage Stock")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Manage Stock", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading warna toska
          : Column(
              children: [
                // 1. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: const TextStyle(color: Colors.black87), // Teks input pencarian hitam
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: AppColors.textGrey),
                        hintText: "Cari nama produk...", 
                        hintStyle: TextStyle(color: AppColors.textGrey),
                        border: InputBorder.none,
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
                      ? const Center(child: Text("Produk tidak ditemukan.", style: TextStyle(color: AppColors.textGrey)))
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
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(20),
                                border: isLowStock ? Border.all(color: AppColors.error.withOpacity(0.6), width: 1.5) : null, // Border merah transparan kalau stok tipis
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                                            child: Image.network(p['image_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: AppColors.textGrey))
                                          )
                                        : const Icon(Icons.inventory_2_outlined, color: AppColors.textGrey),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(p['name_product'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis), // Nama produk hitam
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isLowStock ? "Menipis!" : "Aman", style: TextStyle(fontSize: 9, color: isLowStock ? AppColors.error : AppColors.textGrey, fontWeight: FontWeight.bold)), // Peringatan merah
                                          Text("$qty $unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isLowStock ? AppColors.error : AppColors.primary)), // Stok merah atau toska
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _showAddStockDialog(p),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), // Tombol (+) toska
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
          color: isSelected ? AppColors.primary : Colors.white, // Toska kalau dipilih
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200), // Kasih border tipis kalau gak dipilih
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87, // Teks putih atau hitam
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }
}