import 'package:flutter/material.dart';
import '../models/cart_item.dart';

List<CartItem> cart = [];

ValueNotifier<int> cartNotifier = ValueNotifier(0);

void updateCart() {
  int total = 0;

  for (var item in cart) {
    total += item.qty;
  }

  cartNotifier.value = total;
}