import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'login_screen.dart';
import 'order_detail_screen.dart';
import '../data/shift_data.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,

      /// DRAWER
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

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PastelColors.teal,
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
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search Order ID / Customer",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(child: FilterChipCustom("Semua")),
                  SizedBox(width: 8),
                  Expanded(child: FilterChipCustom("Cash")),
                  SizedBox(width: 8),
                  Expanded(child: FilterChipCustom("QRIS")),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// HEADER TABLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [

                    Expanded(
                      flex: 2,
                      child: Text(
                        "Order ID",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          "Date",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          "Total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// ORDER LIST
            Expanded(
              child: ValueListenableBuilder<List<Order>>(
                valueListenable: allOrders,
                builder: (context, orders, _) {

                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada transaksi",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {

                      final order = orders[index];

                      return OrderCard(order: order);
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

class FilterChipCustom extends StatelessWidget {
  final String title;

  const FilterChipCustom(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {

  final Order order;

  const OrderCard({
    super.key,
    required this.order,
  });

  String formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );

      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(
          children: [

            Expanded(
              flex: 2,
              child: Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formatDate(order.date),
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  "Rp ${order.total}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DRAWER
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [

          /// HEADER
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: PastelColors.sage,
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
                    color: PastelColors.sage,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Cashier1",
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

          Expanded(
            child: ListView(
              children: [

                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Dashboard"),
                  onTap: () {

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );

                  },
                ),

                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text("Sales"),
                  onTap: () {

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesScreen(),
                      ),
                      (route) => false,
                    );

                  },
                ),

                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text("Order History"),
                  onTap: () {

                    if (!shiftActive.value) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Start shift first"),
                        ),
                      );

                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {

                  if (shiftActive.value) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("End shift first before logout"),
                      ),
                    );

                    return;
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
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