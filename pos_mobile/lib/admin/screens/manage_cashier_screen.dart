import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'manage_shifts_screen.dart';
import 'audit_trail_screen.dart';

class ManageCashierScreen extends StatefulWidget {
  const ManageCashierScreen({super.key});

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cashiers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCashiers();
  }

  Future<void> _fetchCashiers() async {
    setState(() => isLoading = true);
    try {
      // HANYA SELECT KOLOM YANG ADA DI DATABASE
      final response = await supabase
          .from('ms_user')
          .select('id, username, name, role') 
          .eq('role', 'kasir') 
          .order('name', ascending: true);

      setState(() {
        cashiers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal mengambil data kasir: $e", isError: true);
    }
  }

  Future<void> _saveCashier(String name, String username, {String? id}) async {
    try {
      final data = {
        'name': name,
        'username': username,
        'role': 'kasir',
        // auth_users_id dibiarkan kosong (null) dulu karena belum pakai Supabase Auth
      };

      if (id == null) {
        await supabase.from('ms_user').insert(data);
        _showSnackBar("Kasir berhasil ditambahkan!");
      } else {
        await supabase.from('ms_user').update(data).eq('id', id);
        _showSnackBar("Data kasir berhasil diperbarui!");
      }
      _fetchCashiers();
    } catch (e) {
      _showSnackBar("Gagal menyimpan data", isError: true);
    }
  }

  Future<void> _deleteCashier(String id) async {
    try {
      await supabase.from('ms_user').delete().eq('id', id);
      _showSnackBar("Kasir berhasil dihapus!");
      _fetchCashiers();
    } catch (e) {
      _showSnackBar("Gagal menghapus kasir", isError: true);
    }
  }

  void _showSnackBar(String m, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: isError ? PastelColors.rose : PastelColors.emerald)
    );
  }

  void _tampilForm([Map<String, dynamic>? data]) {
    final bool isEdit = data != null;
    final TextEditingController nameController = TextEditingController(text: isEdit ? data['name'] : '');
    final TextEditingController userController = TextEditingController(text: isEdit ? data['username'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? "Edit Data Kasir" : "Tambah Kasir Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildField("Nama Lengkap", Icons.person_outline, nameController),
            const SizedBox(height: 12),
            _buildField("Username", Icons.alternate_email, userController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.emerald, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: () {
                  if (nameController.text.isEmpty || userController.text.isEmpty) return;
                  Navigator.pop(context);
                  _saveCashier(nameController.text, userController.text, id: isEdit ? data['id'] : null);
                },
                child: const Text("SIMPAN KASIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint, 
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Manage Cashiers")),
      appBar: AppBar(
        backgroundColor: PastelColors.mint, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Manage Cashiers", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PastelColors.sage,
        onPressed: () => _tampilForm(),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald)) 
        : Column(
            children: [
              Expanded(
                child: cashiers.isEmpty 
                  ? const Center(child: Text("Belum ada kasir terdaftar", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cashiers.length,
                      itemBuilder: (context, i) {
                        final c = cashiers[i];
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
                              child: const Icon(Icons.person, color: PastelColors.emerald),
                            ),
                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("@${c['username']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _tampilForm(c)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: PastelColors.rose), onPressed: () => _showDeleteDialog(c['id'], c['name'])),
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

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Kasir?"),
        content: Text("Yakin mau menghapus kasir '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deleteCashier(id); }, 
            child: const Text("Hapus", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold))
          ),
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