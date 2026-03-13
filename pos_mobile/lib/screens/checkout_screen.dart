import 'package:flutter/material.dart';
import '../data/cart_data.dart';
import '../theme/colors.dart';
import 'cash_payment_widget.dart';
import 'qris_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  final TextEditingController customerController = TextEditingController();

  String paymentMethod = "cash";

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

  /// MERGE ITEM YANG SAMA
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

  @override
  Widget build(BuildContext context) {

    final mergedItems = getMergedItems();

    return Scaffold(
      backgroundColor: PastelColors.mint,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: PastelColors.mint,
        title: const Text(
          "Checkout",
          style: TextStyle(color: PastelColors.grey),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Customer",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: customerController,
            decoration: InputDecoration(
              hintText: "Nama customer",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Order Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal"),
                    Text("Rp ${getSubtotal()}"),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tax (12%)"),
                    Text("Rp ${getTax()}"),
                  ],
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Text(
                      "Rp ${getTotal()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              children: [

                RadioListTile(
                  value: "cash",
                  groupValue: paymentMethod,
                  title: const Text("Cash"),
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),

                RadioListTile(
                  value: "qris",
                  groupValue: paymentMethod,
                  title: const Text("QRIS"),
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (paymentMethod == "cash")
            CashPaymentWidget(
              total: getTotal(),
              customerController: customerController,
              paymentMethod: paymentMethod,
            ),

          if (paymentMethod == "qris")
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.sage,
                ),
                onPressed: () {

                  if (customerController.text.trim().isEmpty) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nama customer wajib diisi"),
                        backgroundColor: Colors.red,
                      ),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRISScreen(
                        total: getTotal(),
                        customer: customerController.text,
                        paymentMethod: paymentMethod,
                      ),
                    ),
                  );

                },
                child: const Text("Bayar dengan QRIS"),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}