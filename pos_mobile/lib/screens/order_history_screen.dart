import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahan untuk format angka
import '../theme/colors.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'login_screen.dart';
import 'order_detail_screen.dart';
import '../data/shift_data.dart';

// UBAH JADI STATEFUL WIDGET BIAR BISA NGERESPON KLIK & KETIKAN
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // --- VARIABEL UNTUK MENYIMPAN STATUS PENCARIAN & FILTER ---
  String searchQuery = "";
  String selectedFilter = "Semua"; // Default ke "Semua"

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(
        width: 250,
        child: AppDrawer(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// NAVBAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
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
                    "Order History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PastelColors.grey),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PastelColors.emerald, // Dibuat emerald solid
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: TextField(
                  // --- TAMBAHAN ONCHANGED BIAR BISA NYARI ---
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Search Order ID / Customer",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// FILTER (Udah dipasangin fungsi OnTap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilterChipCustom(
                      "Semua", 
                      isSelected: selectedFilter == "Semua",
                      onTap: () => setState(() => selectedFilter = "Semua"),
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipCustom(
                      "Cash", 
                      isSelected: selectedFilter == "Cash",
                      onTap: () => setState(() => selectedFilter = "Cash"),
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipCustom(
                      "QRIS", 
                      isSelected: selectedFilter == "QRIS",
                      onTap: () => setState(() => selectedFilter = "QRIS"),
                    )
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// HEADER TABLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                    ),
                  ],
                ),
              ),
            ),

            /// ORDER LIST DENGAN LOGIKA FILTERING
            Expanded(
              child: ValueListenableBuilder<List<Order>>(
                valueListenable: allOrders,
                builder: (context, orders, _) {
                  
                  // --- PROSES PENYARINGAN DATA ---
                  List<Order> filteredOrders = orders.where((order) {
                    // 1. Cek Metode Pembayaran
                    bool matchFilter = selectedFilter == "Semua" || 
                                     order.paymentMethod.toLowerCase() == selectedFilter.toLowerCase();
                    
                    // 2. Cek Kolom Pencarian (Order ID atau Nama)
                    bool matchSearch = searchQuery.isEmpty || 
                                     order.id.toLowerCase().contains(searchQuery) || 
                                     order.customer.toLowerCase().contains(searchQuery);

                    return matchFilter && matchSearch;
                  }).toList();

                  // Di-reverse biar transaksi terbaru ada di paling atas
                  filteredOrders = filteredOrders.reversed.toList();

                  if (filteredOrders.isEmpty) {
                    return const Center(child: Text("Transaksi tidak ditemukan", style: TextStyle(fontSize: 16, color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(order: filteredOrders[index], formatRupiah: formatRupiah);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// CLASS FILTER CHIP DIUBAH BIAR BISA DIKLIK (GestureDetector)
class FilterChipCustom extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap; // Tambahan fungsi klik

  const FilterChipCustom(this.title, {super.key, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Pasang fungsinya di sini
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? PastelColors.emerald : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : PastelColors.grey,
          ),
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final String Function(int) formatRupiah;

  const OrderCard({super.key, required this.order, required this.formatRupiah});

  String formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PastelColors.grey)),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text(formatDate(order.date), style: const TextStyle(fontSize: 13, color: Colors.grey))),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formatRupiah(order.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PastelColors.emerald),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: PastelColors.emerald),
                  title: const Text("Order History", style: TextStyle(color: PastelColors.emerald, fontWeight: FontWeight.bold)),
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