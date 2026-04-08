import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- IMPORT BARU UNTUK FORMATTER
import 'package:intl/intl.dart'; // Tambahan untuk format angka bertitik
import '../theme/colors.dart';
import '../data/order_data.dart';
import '../data/shift_data.dart';
import '../data/report_helper.dart'; // <-- IMPORT PABRIK LAPORAN (BARU)
import 'sales_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

// --- FUNGSI GLOBAL UNTUK POP-UP WARNING ---
void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: PastelColors.rose),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.bold),
          ),
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
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(
        width: 250,
        child: AppDrawer(),
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
                icon: const Icon(Icons.menu, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: PastelColors.emerald, // Dibuat lebih solid
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Hello, NaWa! 👋", // Disesuaikan dengan nickname kamu!
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: PastelColors.grey,
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
  DateTime? _shiftStartTime; // Variabel untuk menyimpan waktu start shift

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
    _shiftStartTime = DateTime.now(); // Catat waktu mulai

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
        title: const Text("Akhiri Shift?"),
        content: const Text("Apakah kamu yakin ingin mengakhiri shift ini?"),
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
              _shiftStartTime = null; // Reset waktu
              Navigator.pop(ctx);
            },
            child: const Text("Akhiri", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold)),
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
                          color: PastelColors.grey,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? PastelColors.emerald.withOpacity(0.15)
                          : PastelColors.rose.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? "ACTIVE" : "INACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? PastelColors.emerald : PastelColors.rose,
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
                  decoration: InputDecoration(
                    labelText: "Opening Balance",
                    labelStyle: const TextStyle(color: PastelColors.grey),
                    prefixText: "Rp ", 
                    filled: true,
                    fillColor: PastelColors.mint,
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
                        backgroundColor: active ? PastelColors.rose : PastelColors.emerald,
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
                      // --- INI FUNGSI BARUNYA BANG! (LANGSUNG DOWNLOAD) ---
                      onPressed: () async {
                        final today = DateTime.now();
                        
                        // Cari transaksi yang tanggalnya sama kayak hari ini
                        final todaysOrders = allOrders.value.where((o) =>
                            o.date.year == today.year &&
                            o.date.month == today.month &&
                            o.date.day == today.day
                        ).toList();

                        if (todaysOrders.isEmpty) {
                          showWarningPopup(context, "Data Kosong", "Belum ada penjualan di hari ini.");
                          return;
                        }

                        // Cetak Laporan!
                        String fileName = "Laporan_Hari_Ini_${DateFormat('dd-MM-yyyy').format(today)}";
                        await ReportHelper.downloadExcel(todaysOrders, fileName);
                      },
                      // ---------------------------------------------------
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PastelColors.teal, 
                        foregroundColor: PastelColors.grey, 
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
        color: PastelColors.mint,
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
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.bold,
              color: PastelColors.grey, 
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
                  color: PastelColors.grey,
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
                          color: PastelColors.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, size: 20, color: PastelColors.emerald),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.grey)),
                            Text(order.paymentMethod.toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600))
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(order.total), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: PastelColors.emerald),
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

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          /// HEADER
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: PastelColors.emerald, 
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: PastelColors.emerald,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NaWa",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Cashier",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          /// MENU
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard, color: PastelColors.grey),
                  title: const Text("Dashboard", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale, color: PastelColors.grey),
                  title: const Text("Sales", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (!shiftActive.value) {
                      showWarningPopup(context, "Akses Ditolak", "Kamu harus memulai shift (Start Shift) terlebih dahulu.");
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: PastelColors.grey),
                  title: const Text("Order History", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (!shiftActive.value) {
                      showWarningPopup(context, "Akses Ditolak", "Kamu harus memulai shift (Start Shift) terlebih dahulu.");
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: PastelColors.grey),
                  title: const Text("Reports", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (shiftActive.value) {
                      showWarningPopup(context, "Gagal Logout", "Tolong akhiri shift (End Shift) terlebih dahulu sebelum logout.");
                      return;
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
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