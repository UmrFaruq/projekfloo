import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahan untuk format harga
import '../models/product.dart';
import '../models/cart_item.dart';
import '../data/cart_data.dart';
import '../theme/colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  // Fungsi format Rupiah
  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        cart.add(
          CartItem(
            name: product.name,
            price: product.price,
          ),
        );

        updateCart();

        // Menyembunyikan snackbar sebelumnya agar tidak numpuk jika diklik cepat
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Memunculkan SnackBar baru yang lebih jelas dan melayang
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${product.name} masuk keranjang",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2), // Diperlambat menjadi 2 detik
            backgroundColor: PastelColors.emerald, // Warna lebih kontras
            behavior: SnackBarBehavior.floating, // Dibuat melayang
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            elevation: 4,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12), // Padding di dalam card ditambah
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: PastelColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 45,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: PastelColors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stok: ${product.stock}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatRupiah(product.price), // Harga sudah diformat pakai titik!
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: PastelColors.emerald,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}