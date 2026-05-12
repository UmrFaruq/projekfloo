import 'package:flutter/material.dart';
import '../models/cart_item.dart';

List<CartItem> cart = [];
ValueNotifier<int> cartNotifier = ValueNotifier(0);

// --- VARIABEL SETTING PAJAK (Dari Database) ---
String globalTaxName = "Tax";
double globalTaxRate = 0.12; 
bool globalIsRounding = false; // Default mati, nanti nyala kalau diset dari DB

void updateCart() {
  int total = 0;
  for (var item in cart) {
    total += item.qty;
  }
  cartNotifier.value = total;
}

// 🔥 MESIN HITUNG SAKTI (PAJAK + PEMBULATAN) 🔥
Map<String, int> hitungFinal(int subtotal) {
  // 1. Hitung Pajak
  double taxDouble = subtotal * globalTaxRate;
  int taxAmount = taxDouble.round();
  
  int totalSementara = subtotal + taxAmount;
  int totalFinal = totalSementara;

  // 2. Hitung Pembulatan (Jika Aktif)
  // Ngebuang sisa di bawah 100 perak. Misal 13.440 -> 13.400
  if (globalIsRounding) {
    totalFinal = (totalSementara / 100).floor() * 100;
  }

  return {
    'tax': taxAmount,
    'total': totalFinal,
    'rounding': totalSementara - totalFinal // Nyari selisih pembulatan
  };
}