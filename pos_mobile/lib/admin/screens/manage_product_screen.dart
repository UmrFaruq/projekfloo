import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

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
        backgroundColor: isError ? AppColors.error : AppColors.primary, // Merah untuk error, Toska untuk sukses
      ),
    );
  }

  // --- FORM INPUT ---
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
                    Text(isEdit ? "Edit Produk" : "Tambah Produk Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul Hitam
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
                        Expanded(child: _buildTextField("Satuan", Icons.straighten, unitController, TextInputType.text)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField("URL Gambar", Icons.image_outlined, imageController, TextInputType.url),
                    const SizedBox(height: 12),
                    const Text("Pilih Kategori", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: selectedCategoryId,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks dropdown hitam
                          items: dbCategories.map((cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['category_name'] ?? 'Unknown'))).toList(),
                          onChanged: (newValue) => setModalState(() => selectedCategoryId = newValue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55, // Tinggi seragam
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Toska solid
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
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
                        child: const Text("SIMPAN PRODUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20), // Icon Toska
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(vertical: 14)
            ),
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
      backgroundColor: AppColors.bgLight, // Background toska muda
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Manage Products") // DRAWER SENTRAL
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight, 
        elevation: 0, 
        centerTitle: true, 
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Manage Products", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, // Toska
        onPressed: () => _tampilFormProduk(), 
        child: const Icon(Icons.add, color: Colors.white)
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: AppColors.textGrey), 
                      hintText: "Search product...", 
                      hintStyle: TextStyle(color: AppColors.textGrey),
                      border: InputBorder.none
                    ),
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
                  ? const Center(child: Text("Tidak ada produk.", style: TextStyle(color: AppColors.textGrey)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 16, 
                        mainAxisSpacing: 16, 
                        childAspectRatio: 0.72
                      ),
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
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
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
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(p['image_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: AppColors.textGrey)))
                    : const Icon(Icons.inventory_2_outlined, color: AppColors.textGrey),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    onSelected: (val) {
                      if (val == 'edit') _tampilFormProduk(p);
                      if (val == 'delete') _konfirmasiHapus(p['id'], p['name_product']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit", style: TextStyle(color: Colors.black87))),
                      const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))), // Merah
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(p['name_product'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis), // Nama produk hitam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(p['qty'] as num?)?.toInt() ?? 0} ${p['unit'] ?? 'pcs'}", style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
              Text(formatRupiah(p['selling_price']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)), // Harga toska gelap
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
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white, // Toska jika dipilih
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200)
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

  void _konfirmasiHapus(id, name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Produk?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text("Yakin mau menghapus '$name'?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () { Navigator.pop(ctx); _hapusProdukAman(id, name); }, child: const Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))), // Tombol hapus merah
        ],
      ),
    );
  }
}