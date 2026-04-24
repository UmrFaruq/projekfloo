import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../models/order.dart';
import '../theme/colors.dart'; // MENGGUNAKAN AppColors

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final Map<String, Map<String, int>> mergedItems = {};

    for (var item in items) {
      String name = item["name"];
      int qty = item["qty"];
      int price = item["price"];

      if (mergedItems.containsKey(name)) {
        mergedItems[name]!["qty"] = mergedItems[name]!["qty"]! + qty;
      } else {
        mergedItems[name] = {"qty": qty, "price": price};
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight, // Tema Background toska muda
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back jadi hitam
        title: const Text(
          "Payment Details", 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold) // Judul Halaman Tetap Tegas (UI Navigation)
        ),
      ),
      // --- PAKE SINGLECHILDSCROLLVIEW BIAR BISA DI-SCROLL ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transaction Info", 
                    style: TextStyle(fontSize: 16, color: Colors.black87) // Teks hitam, hapus bold
                  ),
                  const SizedBox(height: 16),
                  _row("Transaction ID", order.id),
                  _row("Date", formatDate(order.date)),
                  _row("Customer", order.customer.isEmpty ? "Umum" : order.customer),
                  _row("Payment", order.paymentMethod.toUpperCase()),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  const Text(
                    "Items Purchased", 
                    style: TextStyle(fontSize: 14, color: Colors.black87) // Teks hitam, hapus bold
                  ),
                  const SizedBox(height: 12),

                  // DAFTAR ITEM (Model Bertingkat)
                  ...mergedItems.entries.map((entry) {
                    String name = entry.key;
                    int qty = entry.value["qty"]!;
                    int price = entry.value["price"]!;
                    int total = qty * price;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris 1: Nama Produk (Kiri Banget)
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87, // Teks produk hitam, hapus bold
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Baris 2: Detail Angka (x3      3.000      9.000)
                          Row(
                            children: [
                              // Qty
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "x$qty",
                                  style: const TextStyle(
                                    color: Colors.black87, // Qty jadi hitam, hapus bold
                                  ),
                                ),
                              ),
                              // Harga Satuan
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formatRupiah(price),
                                  style: const TextStyle(color: Colors.black87, fontSize: 13), // Harga satuan jadi hitam
                                ),
                              ),
                              // Total Harga per Item (Kanan Banget)
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formatRupiah(total),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.black87, // Harga sub-total per item hitam, hapus bold
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 32),

                  _rowSummary("Subtotal", formatRupiah(order.subtotal)),
                  const SizedBox(height: 6),
                  _rowSummary("Tax (12%)", formatRupiah(order.tax)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87) // Teks Total hitam, hapus bold
                      ),
                      Text(
                        formatRupiah(order.total), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87) // Nominal Total hitam, hapus bold
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40), 
            
            // FOOTER INFO
            Text("Order Ref: #${order.id.substring(0,8)}", style: const TextStyle(color: Colors.black87, fontSize: 12)), // Footer hitam
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black87, fontSize: 13)), // Label kiri jadi hitam
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)), // Value kanan hitam, hapus bold
        ],
      ),
    );
  }

  Widget _rowSummary(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14)), // Label kiri jadi hitam
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)), // Value kanan hitam, hapus bold
      ],
    );
  }
}