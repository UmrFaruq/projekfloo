import 'package:flutter/material.dart';
import '../data/cart_data.dart';
import '../theme/colors.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  int getTotal() {
    int total = 0;
    for (var item in cart) {
      total += item.price * item.qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: PastelColors.mint,
        title: const Text(
          "Keranjang",
          style: TextStyle(color: PastelColors.grey),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),

      body: cart.isEmpty
          ? const Center(
              child: Text(
                "Keranjang masih kosong",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              children: [

                /// CART LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {

                      final item = cart[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [

                            /// PRODUCT IMAGE
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: PastelColors.mint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// PRODUCT INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: PastelColors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    "Rp ${item.price}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// QTY CONTROLLER
                            Container(
                              decoration: BoxDecoration(
                                color: PastelColors.mint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [

                                  /// MINUS
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        if (item.qty > 1) {
                                          item.qty--;
                                        } else {
                                          cart.removeAt(index);
                                        }

                                        updateCart();
                                      });
                                    },
                                  ),

                                  Text(
                                    "${item.qty}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  /// PLUS
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        item.qty++;
                                        updateCart();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            /// DELETE
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: PastelColors.rose,
                              ),
                              onPressed: () {
                                setState(() {
                                  cart.removeAt(index);
                                  updateCart();
                                });
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                /// TOTAL + CHECKOUT
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),

                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),

                          Text(
                            "Rp ${getTotal()}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: PastelColors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// CHECKOUT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelColors.sage,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CheckoutScreen(),
                              ),
                            );

                          },
                          child: const Text(
                            "Checkout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}