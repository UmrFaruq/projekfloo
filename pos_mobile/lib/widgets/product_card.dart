import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../data/cart_data.dart';
import '../theme/colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // --- ANTI-VIRUS RUPIAH ---
  String formatRupiah(dynamic amount) {
    int finalAmount = 0; 
    if (amount != null) {
      if (amount is num) {
        finalAmount = amount.toInt(); 
      } else if (amount is String) {
        finalAmount = int.tryParse(amount) ?? 0;
      }
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(finalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        cart.add(
          CartItem(
            name: product.name,
            price: product.price,
            image: product.image,
          ),
        );

        updateCart();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
            duration: const Duration(seconds: 2),
            backgroundColor: PastelColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            elevation: 4,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: PastelColors.mint.withOpacity(0.3), borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: (product.image != null && product.image!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: Colors.red),
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 45, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // ==========================================
            // NAMA PRODUK
            // ==========================================
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15, // <-- GANTI UKURAN NAMA PRODUK DI SINI (Awalnya 14)
                color: PastelColors.grey
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ==========================================
                // TEKS STOK
                // ==========================================
                Text(
                  "Stok: ${product.qty}", 
                  style: const TextStyle(
                    fontSize: 12, // <-- GANTI UKURAN STOK DI SINI (Awalnya 11)
                    color: Colors.grey, 
                    fontWeight: FontWeight.w600
                  )
                ),
                
                // ==========================================
                // TEKS HARGA
                // ==========================================
                Text(
                  formatRupiah(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, // <-- GANTI UKURAN HARGA DI SINI (Awalnya 13)
                    color: PastelColors.emerald
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}