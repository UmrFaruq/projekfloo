import 'package:flutter/material.dart';

// --- IMPORT PATH DISESUAIKAN BIAR MANJAT 4 FOLDER ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart'; 
import 'manage_product_screen.dart'; 

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  // Data Dummy Kategori
  List<Map<String, dynamic>> categories = [
    {"name": "Makanan Instan", "icon": Icons.bakery_dining},
    {"name": "Minuman", "icon": Icons.local_drink},
    {"name": "Snack", "icon": Icons.icecream},
    {"name": "Sembako", "icon": Icons.shopping_basket},
    {"name": "Kebutuhan Rumah Tangga", "icon": Icons.home_work},
  ];

  void _tampilFormKategori([Map<String, dynamic>? kategoriLama, int? index]) {
    final bool isEdit = kategoriLama != null;
    final TextEditingController nameController = TextEditingController(text: isEdit ? kategoriLama['name'] : '');

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Contoh: Elektronik",
                prefixIcon: const Icon(Icons.category_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  setState(() {
                    if (isEdit) {
                      categories[index!] = {"name": nameController.text, "icon": Icons.category};
                    } else {
                      categories.add({"name": nameController.text, "icon": Icons.category});
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text("Simpan Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: CategoryAdminDrawer()),
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Manage Categories", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PastelColors.sage,
        onPressed: () => _tampilFormKategori(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
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
                decoration: BoxDecoration(color: PastelColors.mint.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                child: Icon(cat['icon'] as IconData, color: PastelColors.emerald),
              ),
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') _tampilFormKategori(cat, index);
                  if (val == 'delete') {
                    setState(() => categories.removeAt(index));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryAdminDrawer extends StatelessWidget {
  const CategoryAdminDrawer({super.key});

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Super Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Owner", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTitle("MAIN MENU"),
                _buildMenuItem(context, Icons.dashboard, "Dashboard", false, () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
                }),
                _buildMenuItem(context, Icons.receipt_long, "Sales Report", false, () {}),
                
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(context, Icons.inventory_2_outlined, "Manage Products", false, () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                }),
                _buildMenuItem(context, Icons.category_outlined, "Manage Categories", true, () {
                  Navigator.pop(context); 
                }),
                _buildMenuItem(context, Icons.people_outline, "Manage Cashiers", false, () {}),
                _buildMenuItem(context, Icons.payments_outlined, "Payment Methods", false, () {}),
                
                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(context, Icons.warehouse_outlined, "Manage Stock", false, () {}),
                _buildMenuItem(context, Icons.local_shipping_outlined, "Purchase / Incoming", false, () {}),
                _buildMenuItem(context, Icons.schedule, "Manage Shifts", false, () {}),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(context, Icons.history, "Audit Trail", false, () {}),
                
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? PastelColors.emerald : PastelColors.grey),
      title: Text(
        title, 
        style: TextStyle(
          color: isSelected ? PastelColors.emerald : PastelColors.grey, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
        )
      ),
      selected: isSelected,
      selectedTileColor: PastelColors.mint.withOpacity(0.3),
      onTap: onTap,
    );
  }
}