import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';
import 'admin_drawer.dart';
import '../../services/audit_service.dart';
import '../../services/session_service.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final newText = newValue.text.replaceAll('.', '');

    final number = int.tryParse(newText);

    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat.decimalPattern('id').format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final catResponse = await supabase
          .from('ms_category_product')
          .select('id, category_name')
          .isFilter('deleted_at', null);

      // 🔥 KODINGAN BERSIH TANPA KOMENTAR DI DALAM SELECT 🔥
      final prodResponse = await supabase
          .from('ms_product')
          .select('''
            id, 
            name_product, 
            qty, 
            qty_gudang, 
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
        _showSnackBar("Gagal mengambil data dari server: $e", isError: true);
      }
    }
  }

  // 🔥 UPDATE STOK DARI GUDANG KE TOKO 🔥
  Future<void> _updateStock(
    String id,
    int currentTokoQty,
    int currentGudangQty,
    int pindahQty,
  ) async {
    try {
      final newTokoQty = currentTokoQty + pindahQty;
      final newGudangQty = currentGudangQty - pindahQty;

      await supabase
          .from('ms_product')
          .update({'qty': newTokoQty, 'qty_gudang': newGudangQty})
          .eq('id', id);

      final product = products.firstWhere((e) => e['id'].toString() == id);

      await supabase.from('tr_stock').insert({
        'product_id': id,
        'user_id': SessionService.userId,
        'qty': pindahQty,
        'tipe': 'in',
        'information':
            'Pindah stok Gudang ke Toko: ${product['name_product']} sebanyak $pindahQty',
        'description': 'Stock ditambahkan dari gudang utama',
        'type': 'stock_in',
      });

      await AuditService.logActivity(
        action: 'MOVE STOCK',
        detail:
            'Memindahkan stok ${product['name_product']} sebanyak $pindahQty ke etalase Toko',
        type: 'update',
      );

      if (mounted) {
        _showSnackBar("Stok Toko berhasil ditambah dari Gudang!");
        _fetchData();
      }
    } catch (e) {
      _showSnackBar("Gagal memindahkan stok", isError: true);
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
      SnackBar(
        content: Text(m),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  void _showAddStockDialog(Map<String, dynamic> product) {
    final TextEditingController qtyController = TextEditingController();
    final int currentTokoQty = _safeInt(product['qty']);
    final int currentGudangQty = _safeInt(
      product['qty_gudang'],
    ); // Stok Gudang Asli
    final String unit = product['unit'] ?? 'pcs';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Pindah Stok ke Toko",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Produk: ${product['name_product']}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // 🔥 INFO STOK GUDANG 🔥
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warehouse,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Sisa di Gudang: $currentGudangQty $unit",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              autofocus: true,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Jumlah yang dipindah...",
                hintStyle: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.normal,
                ),
                suffixText: unit,
                suffixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final int pindahQty =
                  int.tryParse(qtyController.text.replaceAll('.', '')) ?? 0;

              // 🔥 VALIDASI: GAK BOLEH LEBIH DARI STOK GUDANG 🔥
              if (pindahQty > currentGudangQty) {
                _showSnackBar(
                  "Gagal: Stok di Gudang tidak mencukupi!",
                  isError: true,
                );
                return;
              }

              if (pindahQty > 0) {
                Navigator.pop(ctx);
                _updateStock(
                  product['id'].toString(),
                  currentTokoQty,
                  currentGudangQty,
                  pindahQty,
                );
              }
            },
            child: const Text(
              "Pindah Stok",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) {
      String catName = p['ms_category_product']?['category_name'] ?? 'Lainnya';
      bool matchesFilter =
          (selectedFilter == "Semua" || catName == selectedFilter);
      bool matchesSearch = p['name_product'].toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchesFilter && matchesSearch;
    }).toList();

    List<String> filterList = ["Semua"];
    filterList.addAll(categories.map((c) => c['category_name'].toString()));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      drawer: const SizedBox(
        width: 260,
        child: AdminDrawer(activeMenu: "Manage Stock"),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Manage Stock",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: AppColors.textGrey),
                        hintText: "Cari nama produk...",
                        hintStyle: TextStyle(color: AppColors.textGrey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: filterList
                        .map((k) => _buildFilterChip(k))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            "Produk tidak ditemukan.",
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio:
                                    0.65, // <-- Diperpanjang dikit biar teks gudang muat
                              ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = filteredProducts[index];
                            final int qtyToko = _safeInt(p['qty']);
                            final int qtyGudang = _safeInt(
                              p['qty_gudang'],
                            ); // Ambil stok gudang
                            final String unit = p['unit'] ?? 'pcs';
                            final bool isLowStock = qtyToko < 10;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: isLowStock
                                    ? Border.all(
                                        color: AppColors.error.withOpacity(0.6),
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child:
                                          (p['image_url'] != null &&
                                              p['image_url']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                p['image_url'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      color: AppColors.textGrey,
                                                    ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.textGrey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p['name_product'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // 🔥 INFO STOK GUDANG DI GRID 🔥
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warehouse,
                                        size: 10,
                                        color: AppColors.textGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Gudang: $qtyGudang",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isLowStock ? "Menipis!" : "Toko",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isLowStock
                                                  ? AppColors.error
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "$qtyToko $unit",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isLowStock
                                                  ? AppColors.error
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _showAddStockDialog(p),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
