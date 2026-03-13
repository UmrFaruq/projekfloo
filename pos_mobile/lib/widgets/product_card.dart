import 'package:flutter/material.dart';
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product.name} ditambahkan"),
            duration: const Duration(milliseconds: 400),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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

            const SizedBox(height: 10),

            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "Stock : ${product.stock}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                Text(
                  "Rp ${product.price}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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