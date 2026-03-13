import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/colors.dart';

class OrderDetailScreen extends StatelessWidget {

  final Order order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {

    final items = order.items;

    /// MERGE ITEM YANG SAMA
    final Map<String, Map<String, int>> mergedItems = {};

    for (var item in items) {

      String name = item["name"];
      int qty = item["qty"];
      int price = item["price"];

      if (mergedItems.containsKey(name)) {

        mergedItems[name]!["qty"] =
            mergedItems[name]!["qty"]! + qty;

      } else {

        mergedItems[name] = {
          "qty": qty,
          "price": price,
        };

      }
    }

    return Scaffold(
      backgroundColor: PastelColors.mint,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: PastelColors.mint,
        iconTheme: const IconThemeData(color: PastelColors.grey),
        title: const Text(
          "Payment Details",
          style: TextStyle(color: PastelColors.grey),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// PAYMENT DETAILS
              const Text(
                "Payment Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              _row("Transaction ID", order.id),
              _row("Date", formatDate(order.date)),
              _row(
                "Customer",
                order.customer.isEmpty ? "-" : order.customer,
              ),
              _row("Status", "Accept"),
              _row("Payment Method", order.paymentMethod.toUpperCase()),

              const Divider(height: 30),

              /// TRANSACTION BREAKDOWN
              const Text(
                "Transaction Breakdown",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Column(

                  children: mergedItems.entries.map((entry) {

                    String name = entry.key;
                    int qty = entry.value["qty"]!;
                    int price = entry.value["price"]!;
                    int total = qty * price;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          /// NAMA PRODUK
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// QTY PRICE TOTAL
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,

                            children: [

                              Text("$qty"),

                              Text("$price"),

                              Text(
                                "$total",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );

                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              /// SUBTOTAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal"),
                  Text("Rp ${order.subtotal}"),
                ],
              ),

              const SizedBox(height: 6),

              /// TAX
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tax"),
                  Text("Rp ${order.tax}"),
                ],
              ),

              const Divider(height: 24),

              /// TOTAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Total",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  Text(
                    "Rp ${order.total}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              /// FOOTER
              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      "Order : #${order.id}",
                      style: const TextStyle(fontSize: 12),
                    ),

                    const Text(
                      "POS : 012",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}