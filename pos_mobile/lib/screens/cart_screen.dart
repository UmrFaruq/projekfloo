import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../data/cart_data.dart';
import '../theme/colors.dart'; // Menggunakan AppColors
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Fungsi format Rupiah (titik otomatis)
  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

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
      backgroundColor: AppColors.bgLight, // Tema background toska muda
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        title: const Text(
          "Keranjang",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Teks Hitam Tegas
        ),
        iconTheme: const IconThemeData(color: Colors.black87), // Icon kembali warna hitam
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                "Keranjang masih kosong",
                style: TextStyle(color: AppColors.textGrey, fontSize: 16),
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
                                color: AppColors.bgLight.withOpacity(0.5), // Background image toska muda
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87, // Teks nama produk Hitam
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(item.price), 
                                    style: const TextStyle(
                                      color: AppColors.textGrey, // Teks harga abu-abu toska
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// QTY CONTROLLER
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.bgLight, // Background kotak QTY toska muda
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  /// MINUS
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
                                  Text(
                                    "${item.qty}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  /// PLUS
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
                              icon: const Icon(Icons.delete_outline, color: AppColors.error), // Icon hapus warna error
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                    ]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontSize: 16, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatRupiah(getTotal()), 
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // Total harga warna hitam tegas
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// CHECKOUT BUTTON (TOSKA SOLID)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, // Warna utama Toska
                            foregroundColor: Colors.white, 
                            elevation: 2, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Checkout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2, 
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