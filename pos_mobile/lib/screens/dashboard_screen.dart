import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/order_data.dart';
import '../data/shift_data.dart';
import 'sales_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

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
                color: PastelColors.teal,
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
          "Hello, Cashier1! 👋",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening balance wajib diisi"),
        backgroundColor: Colors.red,
      ),
    );

    return;
  }

  int balance = int.parse(openingController.text);

  if (balance <= 0) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening balance harus lebih dari 0"),
        backgroundColor: Colors.red,
      ),
    );

    return;
  }

  openingBalance.value = balance;
  shiftActive.value = true;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const SalesScreen(),
    ),
  );
}

  void endShift() {

    shiftActive.value = false;

    openingBalance.value = 0;
    shiftOrders.value = [];
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
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Current Shift Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.green.withOpacity(0.2)
                          : PastelColors.rose.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? "ACTIVE" : "INACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? Colors.green : PastelColors.rose,
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
                  decoration: const InputDecoration(
                    labelText: "Opening Balance",
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

                  _stat("Opening Balance", "Rp ${openingBalance.value}"),
                  _stat("Total Revenue", "Rp ${getRevenue()}"),
                  _stat("Cash Sales", "Rp ${getCashSales()}"),
                  _stat("QRIS Sales", "Rp ${getQrisSales()}"),
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
                          endShift();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active
                            ? PastelColors.rose
                            : PastelColors.sage,
                      ),
                      child: Text(active ? "End Shift" : "Start Shift"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PastelColors.teal,
                      ),
                      child: const Text("Download Report"),
                    )
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              if (orders.isEmpty)
                const Text("No transactions yet"),

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
                        child: const Icon(Icons.receipt_long, size: 20),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(order.paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12))
                          ],
                        ),
                      ),

                      Text(
                        "Rp ${order.total}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                );
              })
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

          /// MENU
          Expanded(
            child: ListView(
              children: [

                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Dashboard"),

                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text("Sales"),

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
                        builder: (_) => const SalesScreen(),
                      ),
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
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),

                /// MENU BARU
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text("Reports"),

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
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),

                  onTap: () {

                    if (shiftActive.value) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("End shift first"),
                        ),
                      );

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