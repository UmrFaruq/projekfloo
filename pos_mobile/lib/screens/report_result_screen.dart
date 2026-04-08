import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/colors.dart';
import '../data/report_helper.dart'; 

class ReportResultScreen extends StatelessWidget {
  final List<Order> orders;
  final String titleStr; 

  const ReportResultScreen({
    super.key,
    required this.orders,
    required this.titleStr,
  });

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int getRevenue() {
    int total = 0;
    for (var order in orders) {
      total += order.total;
    }
    return total;
  }

  int getTransactions() {
    return orders.length;
  }

  int getItemsSold() {
    int total = 0;
    for (var order in orders) {
      for (var item in order.items) {
        total += item["qty"] as int;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        title: const Text("Report Summary", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Bikin semua child jadi panjang (full width)
          children: [
            
            // --- KOTAK TOTAL REVENUE (Panjang & Besar) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text("TOTAL REVENUE", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(getRevenue()),
                    // Angkanya dibesarin banget dan dikasih warna ijo!
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: PastelColors.emerald),
                  ),
                ],
              ),
            ),
            // ----------------------------------------------

            const SizedBox(height: 16),

            // --- KOTAK TRANSACTIONS & ITEMS (Tengah) ---
            Row(
              children: [
                Expanded(child: _statCard("Transactions", getTransactions().toString())),
                const SizedBox(width: 12),
                Expanded(child: _statCard("Items Sold", getItemsSold().toString())),
              ],
            ),
            // ---------------------------------------------

            const SizedBox(height: 24),
            const Text("Transaction Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PastelColors.grey)),
            const SizedBox(height: 12),
            
            // DAFTAR TRANSAKSI
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer.isEmpty ? "Umum" : order.customer, style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.grey)),
                            const SizedBox(height: 4),
                            Text(order.paymentMethod.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(formatRupiah(order.total), style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.emerald))
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 10),
            
            // TOMBOL DOWNLOAD EXCEL
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  String fileName = "Laporan_Custom_$titleStr";
                  await ReportHelper.downloadExcel(orders, fileName);
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Excel (CSV)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET KHUSUS KOTAK BAWAH BIAR CENTER
  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // <-- INI BIAR RATA TENGAH
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: PastelColors.grey)), // Angka sedikit digedein
        ],
      ),
    );
  }
}