import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

// --- IMPORT PATH (Sesuaikan dengan struktur folder proyek abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

class PurchaseIncomingScreen extends StatefulWidget {
  const PurchaseIncomingScreen({super.key});

  @override
  State<PurchaseIncomingScreen> createState() => _PurchaseIncomingScreenState();
}

class _PurchaseIncomingScreenState extends State<PurchaseIncomingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  // List Riwayat Asli (Narik dari Supabase)
  List<Map<String, dynamic>> incomingHistory = [];
  
  // List Riwayat Hasil Pencarian (Ini yang ditampilin ke layar)
  List<Map<String, dynamic>> filteredHistory = [];

  // Controller buat ambil inputan
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); 
  
  // Controller khusus buat Search Bar
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIncomingData(); 
  }

  // --- FUNGSI NARIK DATA DARI SUPABASE ---
  Future<void> _fetchIncomingData() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tr_purchase_details')
          .select('''
            qty,
            created_at,
            ms_product ( name_product ),
            tr_purchase (
              ms_supplier ( supplier_name, telephone_number ) 
            )
          ''')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> fetchedData = [];
      for (var row in response) {
        String productName = "Produk Tidak Diketahui";
        if (row['ms_product'] != null) {
          productName = row['ms_product']['name_product'] ?? productName;
        }

        String supplierName = "Supplier Umum";
        String phoneNum = "-"; 
        
        if (row['tr_purchase'] != null && row['tr_purchase']['ms_supplier'] != null) {
          supplierName = row['tr_purchase']['ms_supplier']['supplier_name'] ?? supplierName;
          phoneNum = row['tr_purchase']['ms_supplier']['telephone_number']?.toString() ?? "-";
        }

        String formattedDate = "";
        if (row['created_at'] != null) {
          DateTime dt = DateTime.parse(row['created_at']).toLocal();
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        }

        fetchedData.add({
          'date': formattedDate,
          'product': productName,
          'qty': row['qty'] ?? 0,
          'supplier': supplierName,
          'phone': phoneNum, 
        });
      }

      if (mounted) {
        setState(() {
          incomingHistory = fetchedData;
          filteredHistory = fetchedData; // Masukin juga ke list pencarian di awal
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Supabase Purchase: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menarik data dari database"), backgroundColor: AppColors.error), // Merah
        );
      }
    }
  }

  // --- FUNGSI SEARCH (PENCARIAN DATA) ---
  void _runFilter(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = incomingHistory; // Kalau kosong, balikin ke data awal
    } else {
      results = incomingHistory.where((item) {
        // Cari berdasarkan Nama Produk ATAU Nama Supplier
        final productTitle = item['product'].toString().toLowerCase();
        final supplierTitle = item['supplier'].toString().toLowerCase();
        final input = query.toLowerCase();

        return productTitle.contains(input) || supplierTitle.contains(input);
      }).toList();
    }

    setState(() {
      filteredHistory = results;
    });
  }

  // --- POPUP DETAIL SAAT ITEM DI-KLIK ---
  void _showDetailPopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Detail Barang Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), // Judul hitam
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rowDetail("Nama Produk", item['product']?.toString() ?? "-"),
            _rowDetail("Jumlah Masuk", "+${item['qty']} pcs"),
            _rowDetail("Tanggal/Jam", item['date']?.toString() ?? "-"),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
            const Text("Info Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            _rowDetail("Supplier", item['supplier']?.toString() ?? "-"),
            _rowDetail("No. Telepon", item['phone']?.toString() ?? "-"),
            const SizedBox(height: 20),
            
            // TOMBOL HUBUNGI VIA WHATSAPP / TELEPON
            SizedBox(
              width: double.infinity,
              height: 50, // Biar tinggi tombol seragam
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Toska solid
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.chat, size: 18), 
                label: const Text("Hubungi Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () async {
                  String phone = item['phone']?.toString() ?? "";
                  
                  if (phone == "-" || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nomor telepon tidak tersedia", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error)); // Merah
                    return;
                  }

                  // Rapihkan format nomor ke standar 628...
                  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanPhone.startsWith('0')) {
                    cleanPhone = '62${cleanPhone.substring(1)}';
                  }

                  final Uri waUrl = Uri.parse("https://wa.me/$cleanPhone");

                  try {
                    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
                      final Uri telUrl = Uri.parse("tel:$cleanPhone");
                      await launchUrl(telUrl);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka aplikasi", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error)); // Merah
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)), // Value hitam
        ],
      ),
    );
  }

  // --- POPUP INPUT BARANG MASUK ---
  void _showAddIncomingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Input Barang Masuk", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul hitam
              const SizedBox(height: 24),
              _buildTextField(_productController, "Nama Produk", Icons.inventory_2_outlined),
              const SizedBox(height: 16),
              _buildTextField(_qtyController, "Jumlah (Qty)", Icons.add_shopping_cart, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_supplierController, "Nama Supplier", Icons.local_shipping_outlined),
              const SizedBox(height: 16), 
              _buildTextField(_phoneController, "No. Telepon Supplier", Icons.phone, isNumber: true), 
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55, // Tinggi tombol seragam
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Toska
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () {
                    if (_productController.text.isEmpty || _qtyController.text.isEmpty) return;
                    
                    final newItem = {
                      'date': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                      'product': _productController.text,
                      'qty': int.tryParse(_qtyController.text) ?? 0,
                      'supplier': _supplierController.text.isNotEmpty ? _supplierController.text : 'Umum',
                      'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '-', 
                    };

                    setState(() {
                      incomingHistory.insert(0, newItem);
                      
                      // Bersihkan kolom search biar item baru langsung kelihatan
                      _searchController.clear();
                      _runFilter(""); 
                    });

                    _productController.clear(); 
                    _qtyController.clear(); 
                    _supplierController.clear(); 
                    _phoneController.clear(); 
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIcon: Icon(icon, color: AppColors.primary), // Icon toska
        filled: true, fillColor: Colors.grey.shade50,
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
        child: AdminDrawer(activeMenu: "Purchase / Incoming")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Purchase / Incoming", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary, // Toska
        onPressed: _showAddIncomingSheet,
        icon: const Icon(Icons.add_box, color: Colors.white),
        label: const Text("Input Barang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading warna toska
          : Column(
              children: [
                // 1. KOTAK HEADER
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), // Toska solid
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Riwayat Barang Masuk", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Klik item untuk melihat detail & kontak supplier", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                // 2. KOTAK PENCARIAN (SEARCH BAR)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _runFilter(value), // Fitur filter jalan tiap diketik
                      style: const TextStyle(color: Colors.black87), // Teks search hitam
                      decoration: InputDecoration(
                        hintText: "Cari nama barang / supplier...",
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary), // Icon toska
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. LIST RIWAYAT BARANG
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: filteredHistory.isEmpty // Pakai list hasil filter pencarian
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text("Data tidak ditemukan.", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];
                              return GestureDetector(
                                onTap: () => _showDetailPopup(item), // MUNCULIN POPUP
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.inventory_2, color: AppColors.primary), // Icon toska
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['product']?.toString() ?? "Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)), // Nama hitam
                                            const SizedBox(height: 4),
                                            Text("${item['supplier'] ?? 'Umum'} • ${item['date'] ?? '-'}", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text("+${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), // Qty toska
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}