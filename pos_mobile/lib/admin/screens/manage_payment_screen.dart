import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH (Sesuaikan dengan struktur folder abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

class ManagePaymentScreen extends StatefulWidget {
  const ManagePaymentScreen({super.key});

  @override
  State<ManagePaymentScreen> createState() => _ManagePaymentScreenState();
}

class _ManagePaymentScreenState extends State<ManagePaymentScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('ms_payment_method')
          .select('id, method_name')
          .filter('deleted_at', 'is', null)
          .order('method_name', ascending: true);

      setState(() {
        payments = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal mengambil data metode pembayaran", isError: true);
    }
  }

  Future<void> _savePayment(String name, {String? id}) async {
    try {
      if (id == null) {
        await supabase.from('ms_payment_method').insert({'method_name': name});
        _showSnackBar("Metode pembayaran berhasil ditambah!");
      } else {
        await supabase.from('ms_payment_method').update({'method_name': name}).eq('id', id);
        _showSnackBar("Metode pembayaran berhasil diupdate!");
      }
      _fetchPayments();
    } catch (e) {
      _showSnackBar("Gagal menyimpan data", isError: true);
    }
  }

  Future<void> _deletePayment(String id) async {
    try {
      await supabase.from('ms_payment_method').update({
        'deleted_at': DateTime.now().toIso8601String()
      }).eq('id', id);
      
      _showSnackBar("Metode pembayaran dihapus!");
      _fetchPayments();
    } catch (e) {
      _showSnackBar("Gagal menghapus data", isError: true);
    }
  }

  void _showSnackBar(String m, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m), 
        backgroundColor: isError ? AppColors.error : AppColors.primary // Merah untuk error, Toska untuk sukses
      )
    );
  }

  void _tampilForm([Map<String, dynamic>? data]) {
    final bool isEdit = data != null;
    final TextEditingController nameController = TextEditingController(text: isEdit ? data['method_name'] : '');

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
            Text(isEdit ? "Edit Metode Pembayaran" : "Tambah Metode Pembayaran", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul hitam
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
              decoration: InputDecoration(
                hintText: "Contoh: Tunai / QRIS",
                hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary), // Icon toska
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
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  Navigator.pop(context);
                  _savePayment(nameController.text, id: isEdit ? data['id'] : null);
                },
                child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
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
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Payment Methods")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight, 
        elevation: 0, 
        centerTitle: true, 
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Payment Methods", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, // Tombol nambah data toska
        onPressed: () => _tampilForm(), 
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading warna toska
        : payments.isEmpty 
          ? const Center(child: Text("Belum ada metode pembayaran", style: TextStyle(color: AppColors.textGrey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, i) {
                final p = payments[i];
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
                      child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary), // Icon toska
                    ),
                    title: Text(p['method_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Nama metode hitam
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _tampilForm(p)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error), // Icon hapus merah
                          onPressed: () => _showDeleteDialog(p['id'], p['method_name'])
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Metode?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text("Yakin mau menghapus '$name'?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deletePayment(id); }, 
            child: const Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)) // Teks hapus merah
          ),
        ],
      ),
    );
  }
}