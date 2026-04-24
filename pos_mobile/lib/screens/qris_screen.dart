import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; 
import '../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'receipt_screen.dart';

class QRISScreen extends StatelessWidget {
  final int total;
  final String customer;
  final String paymentMethod;

  const QRISScreen({
    super.key,
    required this.total,
    required this.customer,
    required this.paymentMethod,
  });

  // Fungsi untuk memformat angka jadi Rupiah bertitik
  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "QRIS Payment",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Teks judul hitam
        ),
        iconTheme: const IconThemeData(color: Colors.black87), // Icon hitam
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // --- HEADER TEXT ---
              const Text(
                "Scan QR Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 24, 
                  color: Colors.black87 // Teks hitam
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Arahkan kamera atau aplikasi e-wallet Anda ke QR Code di bawah ini untuk membayar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 14), // Teks abu-abu toska
              ),
              
              const SizedBox(height: 40),

              // --- QR CODE CONTAINER DENGAN SHADOW ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), 
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: QrImageView(
                  // NANTI DATA INI YANG DIGANTI DENGAN RESPONSE DARI MIDTRANS/XENDIT
                  data: "POS_PAYMENT_$total", 
                  size: 220,
                  foregroundColor: AppColors.primaryDark, // Warna QR Code jadi Toska Gelap biar premium
                ),
              ),

              const SizedBox(height: 40),

              // --- TOTAL HARGA ---
              const Text(
                "Total Pembayaran",
                style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(total), 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 32, 
                  color: AppColors.primaryDark, // Total pembayaran jadi Toska Gelap
                ),
              ),

              const Spacer(),

              // --- TOMBOL KONFIRMASI (SEMENTARA SEBELUM ADA WEBHOOK) ---
              SizedBox(
                width: double.infinity,
                height: 55, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Warna solid toska
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          customer: customer,
                          paymentMethod: paymentMethod,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Konfirmasi Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}