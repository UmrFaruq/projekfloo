import 'package:flutter/material.dart';

class AppColors {
  // Warna Utama Aplikasi (#0691A6 - Toska/Teal)
  static const Color primary = Color(0xFF0691A6);

  // Warna Background / Latar Belakang Terang
  static const Color bgLight = Color(0xFFE5F5F7);

  // Warna Sekunder / Aksen (Turunan primary)
  static const Color accent = Color(0xFF4CB8C8);

  // Warna Utama versi Gelap (Untuk teks/kontras)
  static const Color primaryDark = Color(0xFF046B7A);

  // Warna Teks Abu-abu / Icon Non-aktif
  static const Color textGrey = Color(0xFF8A9CA6);

  static const Color warning = Color(0xFFF59E0B);
  
  // Merah yang lama mungkin kurang jreng, kita ganti atau tambah ini:
  static const Color error = Color(0xFFFF3B30); // Merah solid untuk error
  static const Color badgeRed = Color(0xFFFF3B30); // Merah super paten untuk notif keranjang
}