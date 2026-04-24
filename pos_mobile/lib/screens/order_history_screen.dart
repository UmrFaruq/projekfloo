import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../theme/colors.dart'; // MENGGUNAKAN AppColors
import '../data/order_data.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';

// --- IMPORT FILE DRAWER KASIR ---
import 'cashier_drawer.dart'; 

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // --- VARIABEL UNTUK MENYIMPAN STATUS PENCARIAN & FILTER ---
  String searchQuery = "";
  String selectedFilter = "Semua"; 

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PANGGIL DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 250,
        child: CashierDrawer(activeMenu: "Order History"),
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
                      icon: const Icon(Icons.menu, size: 28, color: Colors.black87), // Icon hitam
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const Text(
                    "Order History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Teks Hitam
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary, // Toska solid
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
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: AppColors.textGrey), // Icon abu-abu toska
                    hintText: "Search Order ID / Customer",
                    hintStyle: TextStyle(color: AppColors.textGrey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// FILTER CHIPS
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

            /// HEADER TABLE (TEKS DIHITAMKAN)
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
                      child: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12))),
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
                    bool matchFilter = selectedFilter == "Semua" || 
                                     order.paymentMethod.toLowerCase() == selectedFilter.toLowerCase();
                    
                    bool matchSearch = searchQuery.isEmpty || 
                                     order.id.toLowerCase().contains(searchQuery) || 
                                     order.customer.toLowerCase().contains(searchQuery);

                    return matchFilter && matchSearch;
                  }).toList();

                  // Di-reverse biar transaksi terbaru ada di paling atas
                  filteredOrders = filteredOrders.reversed.toList();

                  if (filteredOrders.isEmpty) {
                    return const Center(child: Text("Transaksi tidak ditemukan", style: TextStyle(fontSize: 16, color: AppColors.textGrey)));
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

// CLASS FILTER CHIP CUSTOM
class FilterChipCustom extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap; 

  const FilterChipCustom(this.title, {super.key, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white, // Warna toska jika dipilih
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textGrey, // Teks abu-abu toska kalau ga dipilih
          ),
        ),
      ),
    );
  }
}

// CLASS ORDER CARD
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
              child: Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)), // ID Hitam Tegas
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text(formatDate(order.date), style: const TextStyle(fontSize: 13, color: Colors.black87))), // Tanggal Hitam Tegas
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formatRupiah(order.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark), // Harga toska gelap (teal)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}