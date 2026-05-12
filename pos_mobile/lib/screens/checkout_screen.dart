import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cart_data.dart';
import '../theme/colors.dart';
import 'qris_screen.dart';
import 'receipt_screen.dart';

void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error), 
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("OK", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController customerController = TextEditingController();
  final TextEditingController cashController = TextEditingController(); 
  
  String paymentMethod = "cash";
  int _kembalian = 0;
  bool _isLoading = false; 

  bool _isLoadingMethods = true; 
  List<String> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  // 🔥 FUNGSI FETCH DENGAN FILTER SOFT DELETE 🔥
  Future<void> _fetchPaymentMethods() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('ms_payment_method')
          .select('method_name') // Sesuai kolom di admin
          .filter('deleted_at', 'is', null); // Biar 'Kredit' yg dihapus gak muncul

      if (mounted) {
        setState(() {
          _paymentMethods = (response as List).map((e) => e['method_name'].toString()).toList();
          
          if (_paymentMethods.isNotEmpty) {
            bool hasCash = _paymentMethods.any((m) => m.toLowerCase() == 'cash' || m.toLowerCase() == 'tunai');
            paymentMethod = hasCash ? 'cash' : _paymentMethods.first.toLowerCase();
          }
          _isLoadingMethods = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal narik metode pembayaran: $e");
      if (mounted) {
        setState(() {
          _paymentMethods = ['Cash', 'QRIS'];
          paymentMethod = 'cash';
          _isLoadingMethods = false;
        });
      }
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int getSubtotal() {
    int subtotal = 0;
    for (var item in cart) {
      subtotal += (item.price * item.qty).toInt();
    }
    return subtotal;
  }

  int getTax() => (getSubtotal() * 0.12).round();
  int getTotal() => getSubtotal() + getTax();

  Map<String, Map<String, int>> getMergedItems() {
    Map<String, Map<String, int>> items = {};
    for (var item in cart) {
      if (items.containsKey(item.name)) {
        items[item.name]!['qty'] = items[item.name]!['qty']! + item.qty;
      } else {
        items[item.name] = {
          'qty': item.qty,
          'price': item.price.toInt(),
        };
      }
    }
    return items;
  }

  Future<void> _prosesTransaksiSupabase() async {
    int totalBayar = getTotal();
    int uangTunai = int.tryParse(cashController.text) ?? 0;

    if (uangTunai < totalBayar) {
      showWarningPopup(context, "Uang Kurang", "Nominal uang tunai tidak cukup bosku!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final shiftData = await supabase.from('tr_shift').select('id, user_id').eq('status', 'open').maybeSingle();
      if (shiftData == null) {
        throw Exception("Shift belum dibuka! Buka shift dulu di dashboard.");
      }
      final String shiftId = shiftData['id'];
      final String userId = shiftData['user_id'];

      String? customerId;
      final String custName = customerController.text.trim();
      if (custName.isNotEmpty) {
        final existingCust = await supabase.from('ms_customer').select('id').eq('name', custName).maybeSingle();
        if (existingCust != null) {
          customerId = existingCust['id'];
        } else {
          final newCust = await supabase.from('ms_customer').insert({'name': custName}).select('id').single();
          customerId = newCust['id'];
        }
      }

      final String invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final salesRes = await supabase.from('tr_sales').insert({
        'no_invoice': invoiceNo,
        'user_id': userId,
        'customer_id': customerId,
        'shift_id': shiftId,
        'subtotal': getSubtotal(),
        'tax': getTax(),
        'total': totalBayar,
        'payment_method': paymentMethod, 
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final String salesId = salesRes['id'];

      List<Map<String, dynamic>> details = [];
      for (var item in cart) {
        details.add({
          'sales_id': salesId,
          'product_id': item.id, 
          'qty': item.qty,
          'price': item.price,
          'subtotal': item.price * item.qty,
        });

        final productData = await supabase.from('ms_product').select('qty').eq('id', item.id).single();
        int currentStock = productData['qty'] ?? 0;
        
        await supabase.from('ms_product').update({
          'qty': currentStock - item.qty
        }).eq('id', item.id);

        await supabase.from('tr_stock').insert({
          'user_id': userId,          
          'product_id': item.id,
          'type': 'out',              
          'qty': item.qty,
          'description': 'Penjualan Kasir (${paymentMethod.toUpperCase()}) - Invoice: $invoiceNo',
        });
      }
      
      await supabase.from('tr_sales_details').insert(details);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              amountPaid: uangTunai,
              paymentMethod: paymentMethod, 
              customer: custName.isEmpty ? 'Pelanggan Umum' : custName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showWarningPopup(context, "Transaksi Gagal", "Pesan Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = getMergedItems();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        title: const Text("Checkout", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Customer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: customerController,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Nama customer",
              hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              children: mergedItems.entries.map((entry) {
                String name = entry.key;
                int qty = entry.value['qty']!;
                int price = entry.value['price']!;
                int total = qty * price;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$name  x$qty", style: const TextStyle(color: Colors.black87)),
                      Text(formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(color: Colors.black87)),
                    Text(formatRupiah(getSubtotal()), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tax (12%)", style: TextStyle(color: Colors.black87)),
                    Text(formatRupiah(getTax()), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    Text(formatRupiah(getTotal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: _isLoadingMethods 
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              : Column(
                  children: _paymentMethods.map((method) {
                    String methodLower = method.toLowerCase();
                    IconData iconData = Icons.account_balance_wallet;
                    
                    if (methodLower == 'cash' || methodLower == 'tunai') iconData = Icons.payments_outlined;
                    if (methodLower == 'qris') iconData = Icons.qr_code_2;

                    return RadioListTile<String>(
                      value: methodLower,
                      groupValue: paymentMethod.toLowerCase(),
                      activeColor: AppColors.primary,
                      title: Text(method.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      secondary: Icon(iconData, color: AppColors.primary),
                      onChanged: (value) => setState(() => paymentMethod = value!),
                    );
                  }).toList(),
                ),
          ),
          const SizedBox(height: 24),

          if (paymentMethod.toLowerCase() == "cash" || paymentMethod.toLowerCase() == "tunai")
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nominal Uang Tunai", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        int bayar = int.tryParse(val) ?? 0;
                        _kembalian = bayar - getTotal();
                      });
                    },
                    decoration: InputDecoration(
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Kembalian:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text(
                        _kembalian < 0 ? "Rp 0" : formatRupiah(_kembalian),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: _kembalian < 0 ? AppColors.error : AppColors.primaryDark
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _prosesTransaksiSupabase,
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Selesaikan Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            
          if (paymentMethod.toLowerCase() != "cash" && paymentMethod.toLowerCase() != "tunai")
            SizedBox(
              width: double.infinity,
              height: 55, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (customerController.text.trim().isEmpty) {
                    showWarningPopup(context, "Data Belum Lengkap", "Silakan masukkan nama customer terlebih dahulu sebelum memproses pembayaran.");
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRISScreen(
                        total: getTotal(),
                        customer: customerController.text,
                        paymentMethod: paymentMethod.toUpperCase(),
                      ),
                    ),
                  );
                },
                child: Text("Bayar dengan ${paymentMethod.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}