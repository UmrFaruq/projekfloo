import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import '../theme/colors.dart';
import '../data/shift_data.dart'; // Import shift_data untuk cek status shift di drawer
import 'report_result_screen.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? startDate;
  DateTime? endDate;

  Future pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && picked.isAfter(endDate!)) endDate = null;
      });
    }
  }

  Future pickEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Start Date dulu!")));
      return;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate!,
      firstDate: startDate!,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  List<Order> getFilteredOrders() {
    if (startDate == null || endDate == null) return [];

    final start = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);

    return allOrders.value.where((order) {
      return order.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             order.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      // --- PASANG DRAWER DI SINI ---
      drawer: const SizedBox(
        width: 250,
        child: AppDrawer(),
      ),
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        title: const Text("Reports", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: PastelColors.grey),
        // Tombol menu untuk buka drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Report Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PastelColors.grey)),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: pickStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      startDate == null ? "Start Date" : DateFormat('dd MMM yyyy').format(startDate!),
                      style: TextStyle(color: startDate == null ? Colors.grey : PastelColors.grey, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.calendar_today, color: PastelColors.emerald)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: pickEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      endDate == null ? "End Date" : DateFormat('dd MMM yyyy').format(endDate!),
                      style: TextStyle(color: endDate == null ? Colors.grey : PastelColors.grey, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.calendar_today, color: PastelColors.emerald)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih tanggal dulu bang!")));
                    return;
                  }

                  final filtered = getFilteredOrders();
                  
                  if (filtered.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada transaksi di tanggal tersebut.")));
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportResultScreen(
                        orders: filtered,
                        titleStr: "${DateFormat('dd-MM-yyyy').format(startDate!)}_sd_${DateFormat('dd-MM-yyyy').format(endDate!)}",
                      ),
                    ),
                  );
                },
                child: const Text("Preview Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PastelColors.grey)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET APP DRAWER (SAMA DENGAN HALAMAN LAIN) ---
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(color: PastelColors.emerald),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person, color: PastelColors.emerald, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NaWa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Cashier", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard, color: PastelColors.grey),
                  title: const Text("Dashboard", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale, color: PastelColors.grey),
                  title: const Text("Sales", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (!shiftActive.value) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start shift first")));
                      return;
                    }
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: PastelColors.grey),
                  title: const Text("Order History", style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (!shiftActive.value) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start shift first")));
                      return;
                    }
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: PastelColors.emerald),
                  title: const Text("Reports", style: TextStyle(color: PastelColors.emerald, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (shiftActive.value) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("End shift first")));
                      return;
                    }
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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