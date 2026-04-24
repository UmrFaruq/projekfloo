import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

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
      SnackBar(content: Text(m), backgroundColor: isError ? AppColors.error : AppColors.primary) // Error merah, success toska
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
            Text(isEdit ? "Edit Data Kasir" : "Tambah Kasir Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul hitam
            const SizedBox(height: 16),
            _buildField("Nama Lengkap", Icons.person_outline, nameController),
            const SizedBox(height: 12),
            _buildField("Username", Icons.alternate_email, userController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55, // Biar tinggi tombol seragam
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Toska solid
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () {
                  if (nameController.text.isEmpty || userController.text.isEmpty) return;
                  Navigator.pop(context);
                  _saveCashier(nameController.text, userController.text, id: isEdit ? data['id'] : null);
                },
                child: const Text("SIMPAN KASIR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
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
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: AppColors.primary), // Icon toska
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Manage Cashiers")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight, 
        elevation: 0, 
        centerTitle: true, 
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Manage Cashiers", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, // Tombol nambah data toska
        onPressed: () => _tampilForm(),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading warna toska
        : Column(
            children: [
              Expanded(
                child: cashiers.isEmpty 
                  ? const Center(child: Text("Belum ada kasir terdaftar", style: TextStyle(color: AppColors.textGrey)))
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
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.person, color: AppColors.primary), // Icon toska
                            ),
                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Nama hitam
                            subtitle: Text("@${c['username']}", style: const TextStyle(color: AppColors.textGrey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _tampilForm(c)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => _showDeleteDialog(c['id'], c['name'])), // Tombol hapus merah toska-theme
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
        title: const Text("Hapus Kasir?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text("Yakin mau menghapus kasir '$name'?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deleteCashier(id); }, 
            child: const Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)) // Teks hapus merah toska-theme
          ),
        ],
      ),
    );
  }
}