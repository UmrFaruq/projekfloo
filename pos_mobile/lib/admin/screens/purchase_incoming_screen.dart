import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/colors.dart'; 
import 'admin_drawer.dart'; 
import '../../services/session_service.dart';
import '../../services/audit_service.dart';

class PurchaseIncomingScreen extends StatefulWidget {
  const PurchaseIncomingScreen({super.key});

  @override
  State<PurchaseIncomingScreen> createState() => _PurchaseIncomingScreenState();
}

class _PurchaseIncomingScreenState extends State<PurchaseIncomingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  List<Map<String, dynamic>> dbCategories = [];
  List<Map<String, dynamic>> dbProducts = [];

  List<Map<String, dynamic>> incomingHistory = [];
  List<Map<String, dynamic>> filteredHistory = [];

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIncomingData();
  }

  Future<void> _fetchIncomingData() async {
    setState(() => isLoading = true);
    try {
      final categoryResponse = await supabase
          .from('ms_category_product')
          .select('id, category_name')
          .isFilter('deleted_at', null);

      final productResponse = await supabase
          .from('ms_product')
          .select('id, name_product, category_id')
          .eq('is_active', true);

      final response = await supabase
          .from('tr_purchase_details')
          .select('''
            qty,
            created_at,
            ms_product!fk_purchase_detail_product (
              name_product
            ),
            tr_purchase!fk_purchase_detail_purchase (
              ms_supplier!fk_purchase_supplier (
                id,
                supplier_name,
                telephone_number
              )
            )
          ''')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> fetchedData = [];
      for (var row in response) {
        String productName = "Produk Tidak Diketahui";
        if (row['ms_product'] != null) {
          productName = row['ms_product']['name_product'] ?? productName;
        }

        String supplierId = "";
        String supplierName = "Supplier Umum";
        String phoneNum = "-";

        if (row['tr_purchase'] != null &&
            row['tr_purchase']['ms_supplier'] != null) {
          supplierId = row['tr_purchase']['ms_supplier']['id']?.toString() ?? "";
          supplierName =
              row['tr_purchase']['ms_supplier']['supplier_name'] ?? supplierName;
          phoneNum =
              row['tr_purchase']['ms_supplier']['telephone_number']?.toString() ?? "-";
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
          'supplier_id': supplierId,
          'supplier': supplierName,
          'phone': phoneNum,
        });
      }

      if (mounted) {
        setState(() {
          dbCategories = List<Map<String, dynamic>>.from(categoryResponse);
          dbProducts = List<Map<String, dynamic>>.from(productResponse);
          incomingHistory = fetchedData;
          filteredHistory = fetchedData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Supabase Purchase: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menarik data dari database"),
            backgroundColor: AppColors.error,
          ), 
        );
      }
    }
  }

  void _runFilter(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = incomingHistory; 
    } else {
      results = incomingHistory.where((item) {
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

  // 🔥 FUNGSI EDIT SUPPLIER 🔥
  void _showEditSupplierDialog(Map<String, dynamic> item) {
    if (item['supplier_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data supplier ini tidak bisa diedit"), backgroundColor: AppColors.error));
      return;
    }

    final editNameController = TextEditingController(text: item['supplier']);
    final editPhoneController = TextEditingController(text: item['phone']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Info Supplier", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(labelText: "Nama Supplier", prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Nomor HP", prefixIcon: Icon(Icons.phone)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await supabase.from('ms_supplier').update({
                  'supplier_name': editNameController.text.trim(),
                  'telephone_number': editPhoneController.text.trim(),
                }).eq('id', item['supplier_id']);

                if(mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Tutup popup detail juga
                  _fetchIncomingData(); // Refresh data
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data supplier berhasil diupdate"), backgroundColor: AppColors.primary));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e"), backgroundColor: AppColors.error));
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showDetailPopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Detail Barang Masuk",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
              tooltip: "Edit Supplier",
              onPressed: () => _showEditSupplierDialog(item),
            )
          ],
        ), 
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rowDetail("Nama Produk", item['product']?.toString() ?? "-"),
            _rowDetail("Jumlah Masuk", "+${item['qty']} pcs"),
            _rowDetail("Tanggal/Jam", item['date']?.toString() ?? "-"),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            const Text(
              "Info Supplier",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            _rowDetail("Supplier", item['supplier']?.toString() ?? "-"),
            _rowDetail("No. Telepon", item['phone']?.toString() ?? "-"),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50, 
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text(
                  "Hubungi Supplier",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () async {
                  String phone = item['phone']?.toString() ?? "";

                  if (phone == "-" || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Nomor telepon tidak tersedia"), backgroundColor: AppColors.error),
                    ); 
                    return;
                  }

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal membuka aplikasi"), backgroundColor: AppColors.error),
                    ); 
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)), 
        ],
      ),
    );
  }

  void _showAddIncomingSheet() {
    dynamic selectedCategoryId;
    dynamic selectedProductId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    const Text("Input Barang Masuk (Ke Gudang)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<dynamic>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: "Pilih Kategori",
                        labelStyle: const TextStyle(color: AppColors.textGrey),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: dbCategories.map((category) {
                        return DropdownMenuItem(value: category['id'], child: Text(category['category_name']));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCategoryId = value;
                          selectedProductId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<dynamic>(
                      value: selectedProductId,
                      decoration: InputDecoration(
                        labelText: "Pilih Produk",
                        labelStyle: const TextStyle(color: AppColors.textGrey),
                        prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: dbProducts.where((product) => product['category_id'] == selectedCategoryId).map((product) {
                        return DropdownMenuItem(value: product['id'], child: Text(product['name_product']));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedProductId = value;
                          final selectedProduct = dbProducts.firstWhere((p) => p['id'] == value);
                          _productController.text = selectedProduct['name_product'];
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(_qtyController, "Jumlah (Qty)", Icons.add_shopping_cart, isNumber: true),
                    const SizedBox(height: 16),
                    _buildTextField(_supplierController, "Nama Supplier", Icons.local_shipping_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "No. Telepon Supplier", Icons.phone, isNumber: true),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveIncomingProduct,
                        child: const Text("Simpan Data ke Gudang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveIncomingProduct() async {
    try {
      final productName = _productController.text.trim();
      final supplierName = _supplierController.text.trim();
      final phone = _phoneController.text.trim();
      final qty = int.tryParse(_qtyController.text) ?? 0;

      if (productName.isEmpty || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk dan qty wajib diisi"), backgroundColor: AppColors.error));
        return;
      }

     final productResponse = await supabase.from('ms_product').select().eq('name_product', productName).limit(1).maybeSingle();

      if (productResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk tidak ditemukan"), backgroundColor: AppColors.error));
        return;
      }

      dynamic supplierId;
      final supplierResponse = await supabase.from('ms_supplier').select().eq('supplier_name', supplierName).maybeSingle();

      if (supplierResponse == null) {
        final newSupplier = await supabase.from('ms_supplier').insert({
          'supplier_name': supplierName.isEmpty ? 'Supplier Umum' : supplierName,
          'telephone_number': phone,
          'created_by': SessionService.userId,
        }).select().single();
        supplierId = newSupplier['id'];
      } else {
        supplierId = supplierResponse['id'];
      }

      final purchase = await supabase.from('tr_purchase').insert({'supplier_id': supplierId, 'user_id': SessionService.userId}).select().single();

      await supabase.from('tr_purchase_details').insert({
        'purchase_id': purchase['id'],
        'product_id': productResponse['id'],
        'qty': qty,
        'purchase_price': productResponse['purchase_price'] ?? 0,
        'subtotal': (productResponse['purchase_price'] ?? 0) * qty,
      });

      // 🔥 UPDATE STOCK GUDANG, BUKAN STOK TOKO 🔥
      final currentGudangQty = int.tryParse(productResponse['qty_gudang']?.toString() ?? '0') ?? 0;
      final newGudangQty = currentGudangQty + qty;

      await supabase.from('ms_product').update({
        'qty_gudang': newGudangQty, // <--- MASUK KE SINI
        'updated_by': SessionService.userId
      }).eq('id', productResponse['id']);

      await supabase.from('tr_stock').insert({
        'product_id': productResponse['id'],
        'user_id': SessionService.userId,
        'qty': qty,
        'tipe': 'in',
        'information': 'Purchase barang masuk $productName ke Gudang',
        'description': 'Penambahan stok gudang dari supplier',
        'type': 'purchase',
      });

      await AuditService.logActivity(
        action: 'PURCHASE INCOMING',
        detail: 'Menambahkan barang masuk $productName sebanyak $qty ke Gudang',
        type: 'create',
      );

      _productController.clear();
      _qtyController.clear();
      _supplierController.clear();
      _phoneController.clear();

      Navigator.pop(context);
      _fetchIncomingData();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang masuk ke gudang berhasil!"), backgroundColor: AppColors.primary));
    } catch (e) {
      debugPrint("ERROR SAVE PURCHASE: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal simpan barang: $e"), backgroundColor: AppColors.error));
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIcon: Icon(icon, color: AppColors.primary), 
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, 
      drawer: const SizedBox(width: 260, child: AdminDrawer(activeMenu: "Purchase / Incoming")),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), 
        title: const Text("Purchase / Incoming", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary, 
        onPressed: _showAddIncomingSheet,
        icon: const Icon(Icons.add_box, color: Colors.white),
        label: const Text("Input Barang (Gudang)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) 
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), 
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Riwayat Barang Masuk", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Klik item untuk melihat detail & edit kontak supplier", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _runFilter(value), 
                      style: const TextStyle(color: Colors.black87), 
                      decoration: InputDecoration(
                        hintText: "Cari nama barang / supplier...",
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: filteredHistory.isEmpty 
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
                                onTap: () => _showDetailPopup(item), 
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.inventory_2, color: AppColors.primary), 
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['product']?.toString() ?? "Tanpa Nama",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                            ), 
                                            const SizedBox(height: 4),
                                            Text(
                                              "${item['supplier'] ?? 'Umum'} • ${item['date'] ?? '-'}",
                                              style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "+${item['qty']}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ), 
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