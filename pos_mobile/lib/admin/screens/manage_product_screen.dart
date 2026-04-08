import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORT (Manjat 4 folder) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import '../../../../models/product.dart';
import '../../../../data/product_data.dart';
import 'admin_dashboard_screen.dart';
import 'manage_category_screen.dart';

class ManageProductScreen extends StatefulWidget {
  const ManageProductScreen({super.key});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  String selectedFilter = "Semua";

  final List<String> _kategoriList = [
    "Makanan Instan",
    "Minuman",
    "Snack",
    "Sembako",
    "Kebutuhan Rumah Tangga",
  ];

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _hapusProduk(String namaProduk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Hapus Produk",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Apakah kamu yakin ingin menghapus '$namaProduk' dari daftar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelColors.rose,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  products.removeWhere((p) => p.name == namaProduk);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$namaProduk berhasil dihapus!"),
                    backgroundColor: PastelColors.rose,
                  ),
                );
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _tampilFormProduk([Product? produkYangDiedit]) {
    final bool isEdit = produkYangDiedit != null;

    final TextEditingController nameController = TextEditingController(
      text: isEdit ? produkYangDiedit.name : '',
    );
    final TextEditingController priceController = TextEditingController(
      text: isEdit ? produkYangDiedit.price.toString() : '',
    );
    final TextEditingController stockController = TextEditingController(
      text: isEdit ? produkYangDiedit.stock.toString() : '',
    );
    final TextEditingController imageController = TextEditingController(
      text: isEdit ? (produkYangDiedit.image ?? '') : '',
    );

    String selectedKategoriDropdown = isEdit
        ? produkYangDiedit.category
        : _kategoriList.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "Edit Produk" : "Tambah Produk Baru",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "URL Gambar Produk",
                      Icons.image_outlined,
                      imageController,
                      TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      "Nama Produk",
                      Icons.inventory_2_outlined,
                      nameController,
                      TextInputType.text,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Harga (Rp)",
                            Icons.payments_outlined,
                            priceController,
                            TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            "Stok Awal",
                            Icons.numbers,
                            stockController,
                            TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedKategoriDropdown,
                          items: _kategoriList
                              .map(
                                (kategori) => DropdownMenuItem(
                                  value: kategori,
                                  child: Text(kategori),
                                ),
                              )
                              .toList(),
                          onChanged: (newValue) {
                            if (newValue != null)
                              setModalState(
                                () => selectedKategoriDropdown = newValue,
                              );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PastelColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              priceController.text.isEmpty)
                            return;
                          setState(() {
                            // --- INI YANG DIBENERIN: DITAMBAHIN ID BIA GAK ERROR ---
                            final produkBaru = Product(
                              id: isEdit
                                  ? produkYangDiedit.id
                                  : DateTime.now().millisecondsSinceEpoch
                                        .toString(), // Kasih ID sementara
                              name: nameController.text,
                              price: int.parse(priceController.text),
                              stock: stockController.text.isEmpty
                                  ? 0
                                  : int.parse(stockController.text),
                              category: selectedKategoriDropdown,
                              image: imageController.text.isEmpty
                                  ? null
                                  : imageController.text,
                            );
                            if (isEdit) {
                              final index = products.indexWhere(
                                (p) => p.name == produkYangDiedit.name,
                              );
                              if (index != -1) products[index] = produkBaru;
                            } else {
                              products.add(produkBaru);
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEdit ? "Simpan Perubahan" : "Simpan Produk",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    TextInputType type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = selectedFilter == "Semua"
        ? products
        : products.where((p) => p.category == selectedFilter).toList();

    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: ProductAdminDrawer()),
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Manage Products",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PastelColors.sage,
        elevation: 4,
        onPressed: () => _tampilFormProduk(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search product...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Semua"),
                ..._kategoriList.map((k) => _buildFilterChip(k)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child:
                                    (product.image != null &&
                                        product.image!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          product.image!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (c, e, s) => const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit')
                                    _tampilFormProduk(product);
                                  if (value == 'delete')
                                    _hapusProduk(product.name);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: PastelColors.sage,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Edit"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: PastelColors.rose,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Hapus"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Stock : ${product.stock}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            formatRupiah(product.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
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
          color: isSelected ? PastelColors.sage.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class ProductAdminDrawer extends StatelessWidget {
  const ProductAdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: PastelColors.sage),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: PastelColors.sage,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Super Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Owner",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
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
                _buildMenuItem(
                  context,
                  Icons.dashboard,
                  "Dashboard",
                  false,
                  () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(
                  context,
                  Icons.inventory_2_outlined,
                  "Manage Products",
                  true,
                  () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context,
                  Icons.category_outlined,
                  "Manage Categories",
                  false,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoryScreen(),
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
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    ),
  );
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(
      icon,
      color: isSelected ? PastelColors.emerald : PastelColors.grey,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: isSelected ? PastelColors.emerald : PastelColors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
      ),
    ),
    selected: isSelected,
    selectedTileColor: PastelColors.mint.withOpacity(0.3),
    onTap: onTap,
  );
}
