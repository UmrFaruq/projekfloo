import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH DISESUAIKAN ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  
  // --- FITUR SEARCH ---
  String searchQuery = ""; // Penampung teks pencarian

  @override
  void initState() {
    super.initState();
    _fetchCategories(); 
  }

  // --- 1. READ ---
  Future<void> _fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('ms_category_product')
          .select('id, category_name')
          .order('category_name', ascending: true);

      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Error ambil kategori: $e");
      setState(() => isLoading = false);
      _showSnackBar("Gagal mengambil data kategori", isError: true);
    }
  }

  // --- 2. CREATE & UPDATE ---
  Future<void> _saveCategory(String name, {dynamic id}) async {
    try {
      if (id == null) {
        await supabase.from('ms_category_product').insert({'category_name': name});
        _showSnackBar("Kategori berhasil ditambahkan!");
      } else {
        await supabase.from('ms_category_product').update({'category_name': name}).eq('id', id);
        _showSnackBar("Kategori berhasil diupdate!");
      }
      _fetchCategories(); 
    } catch (e) {
      _showSnackBar("Gagal menyimpan kategori", isError: true);
    }
  }

  // --- 3. DELETE ---
  Future<void> _deleteCategory(dynamic id) async {
    try {
      await supabase.from('ms_category_product').delete().eq('id', id);
      _showSnackBar("Kategori berhasil dihapus!");
      _fetchCategories(); 
    } catch (e) {
      _showSnackBar("Gagal menghapus kategori. Mungkin sedang dipakai di produk.", isError: true);
    }
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

  IconData _getCategoryIcon(String name) {
    String lowerName = name.toLowerCase();
    if (lowerName.contains('makan')) return Icons.bakery_dining;
    if (lowerName.contains('minum')) return Icons.local_drink;
    if (lowerName.contains('snack')) return Icons.icecream;
    if (lowerName.contains('sembako')) return Icons.shopping_basket;
    return Icons.category; 
  }

  // --- FORM POPUP ---
  void _tampilFormKategori([Map<String, dynamic>? kategoriLama]) {
    final bool isEdit = kategoriLama != null;
    final TextEditingController nameController = TextEditingController(
      text: isEdit ? kategoriLama['category_name'] : ''
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? "Edit Kategori" : "Tambah Kategori Baru",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Judul hitam
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
              decoration: InputDecoration(
                hintText: "Contoh: Elektronik",
                hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary), // Icon toska
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55, // Tinggi tombol seragam
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Toska solid
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  Navigator.pop(context);
                  await _saveCategory(nameController.text, id: isEdit ? kategoriLama['id'] : null);
                },
                child: const Text("Simpan Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA SEARCH DI SINI ---
    final filteredCategories = categories.where((cat) {
      return cat['category_name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Manage Categories")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Manage Categories", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, // Tombol nambah data toska
        onPressed: () => _tampilFormKategori(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading warna toska
        : Column(
            children: [
              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: AppColors.textGrey),
                      hintText: "Search category...",
                      hintStyle: TextStyle(color: AppColors.textGrey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredCategories.isEmpty
                  ? const Center(child: Text("Kategori tidak ditemukan.", style: TextStyle(color: AppColors.textGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final cat = filteredCategories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_getCategoryIcon(cat['category_name'] ?? ''), color: AppColors.primary), // Icon dinamis toska
                            ),
                            title: Text(cat['category_name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)), // Nama kategori hitam
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
                              onSelected: (val) {
                                if (val == 'edit') _tampilFormKategori(cat);
                                if (val == 'delete') _showDeleteDialog(cat);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text("Edit", style: TextStyle(color: Colors.black87))),
                                const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))), // Teks hapus merah
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Kategori?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text("Yakin mau menghapus '${cat['category_name']}'?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteCategory(cat['id']); }, child: const Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))), // Teks hapus merah toska-theme
        ],
      ),
    );
  }
}