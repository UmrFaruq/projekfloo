import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../data/cart_data.dart';
import '../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'cash_payment_widget.dart';
import 'qris_screen.dart';

// --- FUNGSI GLOBAL UNTUK POP-UP WARNING ---
void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error), // Icon merah toska-theme
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold),
          ),
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
  String paymentMethod = "cash";

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int getSubtotal() {
    int subtotal = 0;
    for (var item in cart) {
      subtotal += item.price * item.qty;
    }
    return subtotal;
  }

  int getTax() {
    return (getSubtotal() * 0.12).round();
  }

  int getTotal() {
    return getSubtotal() + getTax();
  }

  /// MERGE ITEM YANG SAMA
  Map<String, Map<String, int>> getMergedItems() {
    Map<String, Map<String, int>> items = {};
    for (var item in cart) {
      if (items.containsKey(item.name)) {
        items[item.name]!['qty'] = items[item.name]!['qty']! + item.qty;
      } else {
        items[item.name] = {
          'qty': item.qty,
          'price': item.price,
        };
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = getMergedItems();

    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Judul hitam tegas
        ),
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Customer",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), // Teks Hitam
          ),
          const SizedBox(height: 8),
          TextField(
            controller: customerController,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Nama customer",
              hintStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary), // Icon toska
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Order Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), // Teks Hitam
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ]
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
                      Text("$name  x$qty", style: const TextStyle(color: Colors.black87)), // Nama item Hitam
                      Text(formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Harga Hitam
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
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(color: Colors.black87)),
                    Text(formatRupiah(getSubtotal()), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Angka Hitam
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tax (12%)", style: TextStyle(color: Colors.black87)),
                    Text(formatRupiah(getTax()), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Angka Hitam
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), // Label Total Hitam
                    ),
                    Text(
                      formatRupiah(getTotal()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark), // Total Bayar Toska Gelap (Teal)
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), // Teks Hitam
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              children: [
                RadioListTile(
                  value: "cash",
                  groupValue: paymentMethod,
                  activeColor: AppColors.primary, // Toska
                  title: const Text("Cash", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  secondary: const Icon(Icons.payments_outlined, color: AppColors.primary), // Icon Toska
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),
                RadioListTile(
                  value: "qris",
                  groupValue: paymentMethod,
                  activeColor: AppColors.primary, // Toska
                  title: const Text("QRIS", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  secondary: const Icon(Icons.qr_code_2, color: AppColors.primary), // Icon Toska
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (paymentMethod == "cash")
            CashPaymentWidget(
              total: getTotal(),
              customerController: customerController,
              paymentMethod: paymentMethod,
            ),
            
          if (paymentMethod == "qris")
            SizedBox(
              width: double.infinity,
              height: 55, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Dibuat toska solid
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // LOGIKA WARNING POP-UP UNTUK QRIS
                  if (customerController.text.trim().isEmpty) {
                    showWarningPopup(context, "Data Belum Lengkap", "Silakan masukkan nama customer terlebih dahulu sebelum membayar dengan QRIS.");
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRISScreen(
                        total: getTotal(),
                        customer: customerController.text,
                        paymentMethod: paymentMethod,
                      ),
                    ),
                  );
                },
                child: const Text("Bayar dengan QRIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}