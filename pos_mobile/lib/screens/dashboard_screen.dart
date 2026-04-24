import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart'; 
import '../theme/colors.dart';
import '../data/order_data.dart';
import '../data/shift_data.dart';
import '../data/report_helper.dart'; 
import 'sales_screen.dart';

// --- IMPORT FILE DRAWER KASIR YANG BARU DIBIKIN ---
import 'cashier_drawer.dart'; 

// --- FUNGSI GLOBAL UNTUK POP-UP WARNING ---
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

// --- FUNGSI GLOBAL UNTUK FORMAT RUPIAH ---
String formatRupiah(int amount) {
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      drawer: const SizedBox(
        width: 250,
        child: CashierDrawer(activeMenu: "Dashboard"), // Panggil drawer baru
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardHeader(),
              SizedBox(height: 24),
              ShiftSummaryCard(),
              SizedBox(height: 20),
              RecentTransactionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 28, color: Colors.black87),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Teks Hitam
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary, 
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Hello, NaWa! 👋", 
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Teks Hitam tegas
          ),
        ),
      ],
    );
  }
}

class ShiftSummaryCard extends StatefulWidget {
  const ShiftSummaryCard({super.key});

  @override
  State<ShiftSummaryCard> createState() => _ShiftSummaryCardState();
}

class _ShiftSummaryCardState extends State<ShiftSummaryCard> {
  final TextEditingController openingController = TextEditingController();
  DateTime? _shiftStartTime; 

  int getRevenue() {
    int total = 0;
    for (var order in shiftOrders.value) {
      total += order.total;
    }
    return total;
  }

  int getCashSales() {
    int total = 0;
    for (var order in shiftOrders.value) {
      if (order.paymentMethod == "cash") {
        total += order.total;
      }
    }
    return total;
  }

  int getQrisSales() {
    int total = 0;
    for (var order in shiftOrders.value) {
      if (order.paymentMethod == "qris") {
        total += order.total;
      }
    }
    return total;
  }

  int getItemsSold() {
    int total = 0;
    for (var order in shiftOrders.value) {
      for (var item in order.items) {
        int qty = item["qty"] ?? 0;
        total += qty;
      }
    }
    return total;
  }

  void startShift(BuildContext context) {
    if (openingController.text.trim().isEmpty) {
      showWarningPopup(context, "Perhatian", "Opening balance wajib diisi.");
      return;
    }

    String cleanText = openingController.text.replaceAll('.', '');
    int balance = int.tryParse(cleanText) ?? 0;

    if (balance <= 0) {
      showWarningPopup(context, "Perhatian", "Opening balance harus lebih dari 0.");
      return;
    }

    openingBalance.value = balance;
    shiftActive.value = true;
    _shiftStartTime = DateTime.now(); 

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SalesScreen(),
      ),
    );
  }

  void endShift(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Akhiri Shift?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text("Apakah kamu yakin ingin mengakhiri shift ini?", style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              shiftActive.value = false;
              openingBalance.value = 0;
              shiftOrders.value = [];
              _shiftStartTime = null; 
              Navigator.pop(ctx);
            },
            child: const Text("Akhiri", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: shiftActive,
      builder: (context, active, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Shift Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Teks Hitam
                        ),
                      ),
                      if (active && _shiftStartTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Started at: ${DateFormat('HH:mm').format(_shiftStartTime!)}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ]
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? "ACTIVE" : "INACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? AppColors.primary : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (!active)
                TextField(
                  controller: openingController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyFormatInputFormatter(), 
                  ],
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Opening Balance",
                    labelStyle: const TextStyle(color: AppColors.textGrey),
                    prefixText: "Rp ", 
                    prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _stat("Opening Balance", formatRupiah(openingBalance.value)),
                  _stat("Total Revenue", formatRupiah(getRevenue())),
                  _stat("Cash Sales", formatRupiah(getCashSales())),
                  _stat("QRIS Sales", formatRupiah(getQrisSales())),
                  _stat("Transactions", "${shiftOrders.value.length}"),
                  _stat("Items Sold", "${getItemsSold()}"),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!active) {
                          startShift(context);
                        } else {
                          endShift(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        active ? "End Shift" : "Start Shift",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final today = DateTime.now();
                        
                        final todaysOrders = allOrders.value.where((o) =>
                            o.date.year == today.year &&
                            o.date.month == today.month &&
                            o.date.day == today.day
                        ).toList();

                        if (todaysOrders.isEmpty) {
                          showWarningPopup(context, "Data Kosong", "Belum ada penjualan di hari ini.");
                          return;
                        }

                        String fileName = "Laporan_Hari_Ini_${DateFormat('dd-MM-yyyy').format(today)}";
                        await ReportHelper.downloadExcel(todaysOrders, fileName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, 
                        foregroundColor: Colors.white, 
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Download Report",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Teks Angka jadi hitam tegas
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: shiftOrders,
      builder: (context, orders, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Teks Hitam
                ),
              ),
              const SizedBox(height: 20),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No transactions yet", style: TextStyle(color: Colors.grey))),
                ),
              ...orders.reversed.take(5).map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, size: 20, color: AppColors.primary), // Icon Toska
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Nama Hitam
                            Text(order.paymentMethod.toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600))
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(order.total), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark), // Harga lebih tegas
                      )
                    ],
                  ),
                );
              }).toList(), 
            ],
          ),
        );
      },
    );
  }
}

// --- MESIN AUTO TITIK RUPIAH ---
class CurrencyFormatInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    final int value = int.parse(cleanText);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}