import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../data/cart_data.dart';
import '../theme/colors.dart'; 
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int getSubtotal() {
    int total = 0;
    for (var item in cart) {
      total += item.price * item.qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        title: const Text("Keranjang", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87), 
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text("Keranjang masih kosong", style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
            )
          : Column(
              children: [
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
                                color: AppColors.bgLight.withOpacity(0.5), 
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (item.image != null && item.image!.isNotEmpty)
                                    ? Image.network(
                                        item.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported_outlined, color: AppColors.error),
                                      )
                                    : const Icon(Icons.fastfood, color: AppColors.textGrey),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(item.price), 
                                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),

                            /// QTY CONTROLLER
                            Container(
                              decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18, color: Colors.black87),
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
                                  Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18, color: Colors.black87),
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
                              icon: const Icon(Icons.delete_outline, color: AppColors.error), 
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

                /// SUBTOTAL + CHECKOUT
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal", style: TextStyle(fontSize: 16, color: AppColors.textGrey, fontWeight: FontWeight.bold)), // 🔥 UDAH DIGANTI JADI SUBTOTAL
                          Text(
                            formatRupiah(getSubtotal()), 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, 
                            foregroundColor: Colors.white, 
                            elevation: 2, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                          },
                          child: const Text("Checkout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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