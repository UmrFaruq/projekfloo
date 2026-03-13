import 'package:flutter/material.dart';
import '../data/cart_data.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import '../theme/colors.dart';
import 'sales_screen.dart';

class ReceiptScreen extends StatelessWidget {

  final String customer;
  final String paymentMethod;

  const ReceiptScreen({
    super.key,
    required this.customer,
    required this.paymentMethod,
  });

  String generateTransactionId() {
    return "TXN${DateTime.now().millisecondsSinceEpoch}";
  }

  String getDate() {
    DateTime now = DateTime.now();
    return "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
  }

  int getSubtotal() {
    int subtotal = 0;

    for (var item in cart) {
      subtotal += item.price * item.qty;
    }

    return subtotal;
  }

  int getTax() {
    return (getSubtotal() * 0.12).round();
  }

  int getTotal() {
    return getSubtotal() + getTax();
  }

  Map<String, Map<String, int>> getMergedItems() {

    Map<String, Map<String, int>> items = {};

    for (var item in cart) {

      if (items.containsKey(item.name)) {

        items[item.name]!['qty'] =
            items[item.name]!['qty']! + item.qty;

      } else {

        items[item.name] = {
          'qty': item.qty,
          'price': item.price,
        };

      }
    }

    return items;
  }

  void saveOrder() {

    List<Map<String, dynamic>> orderItems = [];

    for (var item in cart) {

      orderItems.add({
        "name": item.name,
        "qty": item.qty,
        "price": item.price,
        "total": item.qty * item.price,
      });

    }

    final order = Order(
      id: generateTransactionId(),
      customer: customer,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      items: orderItems,
      subtotal: getSubtotal(),
      tax: getTax(),
      total: getTotal(),
    );

    allOrders.value = [
  ...allOrders.value,
  order
  ];

  shiftOrders.value = [
    ...shiftOrders.value,
    order
  ];
  }

  @override
  Widget build(BuildContext context) {

    saveOrder();

    final mergedItems = getMergedItems();

    return Scaffold(
      backgroundColor: PastelColors.mint,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [

              const Text(
                "Payment Successful",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Payment Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Transaction ID"),
                        Text(generateTransactionId()),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Customer"),
                        Text(customer.isEmpty ? "-" : customer),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Date"),
                        Text(getDate()),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Payment Method"),
                        Text(paymentMethod.toUpperCase()),
                      ],
                    ),

                    const SizedBox(height: 20),

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
                          int qty = entry.value['qty']!;
                          int price = entry.value['price']!;
                          int total = qty * price;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                Text("$name x$qty"),

                                Text("Rp $total"),
                              ],
                            ),
                          );

                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text("Rp ${getSubtotal()}"),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tax"),
                        Text("Rp ${getTax()}"),
                      ],
                    ),

                    const SizedBox(height: 6),

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
                          "Rp ${getTotal()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PastelColors.sage,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  onPressed: () {

                    cart.clear();
                    updateCart();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesScreen(),
                      ),
                      (route) => false,
                    );
                  },

                  child: const Text("Selesai"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}