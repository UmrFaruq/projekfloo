import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/colors.dart';

class ReportResultScreen extends StatelessWidget {

  final List<Order> orders;

  const ReportResultScreen({
    super.key,
    required this.orders,
  });

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
        title: const Text(
          "Report Result",
          style: TextStyle(color: PastelColors.grey),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            _card("Total Revenue", "Rp ${getRevenue()}"),
            _card("Transactions", getTransactions().toString()),
            _card("Items Sold", getItemsSold().toString()),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {

                  final order = orders[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              order.customer,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              order.paymentMethod,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          "Rp ${order.total}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }
}