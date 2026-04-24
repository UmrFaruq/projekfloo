import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import '../theme/colors.dart'; // Menggunakan AppColors
import '../data/shift_data.dart'; 
import 'report_result_screen.dart';

// --- IMPORT FILE DRAWER KASIR YANG BARU ---
import 'cashier_drawer.dart';

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
      builder: (context, child) {
        // Menyesuaikan warna kalender dengan tema Toska
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PASANG DRAWER SENTRAL DI SINI ---
      drawer: const SizedBox(
        width: 250,
        child: CashierDrawer(activeMenu: "Reports"),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        title: const Text("Reports", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), // Teks Hitam
        iconTheme: const IconThemeData(color: Colors.black87), // Icon Hitam
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
            const Text("Select Report Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Teks Hitam
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
                      style: TextStyle(
                        color: startDate == null ? AppColors.textGrey : Colors.black87, // Hitam kalau udah diisi
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.primary) // Icon Toska
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
                      style: TextStyle(
                        color: endDate == null ? AppColors.textGrey : Colors.black87, // Hitam kalau udah diisi
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.primary) // Icon Toska
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
                  backgroundColor: AppColors.primary, // Tombol Toska
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pilih tanggal dulu bang!"), backgroundColor: AppColors.error)
                    );
                    return;
                  }

                  final filtered = getFilteredOrders();
                  
                  if (filtered.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tidak ada transaksi di tanggal tersebut."), backgroundColor: AppColors.error)
                    );
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
                child: const Text("Preview Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)), // Teks Putih
              ),
            )
          ],
        ),
      ),
    );
  }
}