import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; // Tambahan untuk format angka
import '../theme/colors.dart';
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
      backgroundColor: PastelColors.mint,
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "QRIS Payment",
          style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24), // Padding luar diperlebar biar nggak mepet
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
                  color: PastelColors.grey
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Arahkan kamera atau aplikasi e-wallet Anda ke QR Code di bawah ini untuk membayar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      color: Colors.black.withOpacity(0.08), // Bayangan lembut
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: QrImageView(
                  data: "POS_PAYMENT_$total",
                  size: 220,
                ),
              ),

              const SizedBox(height: 40),

              // --- TOTAL HARGA ---
              const Text(
                "Total Pembayaran",
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(total), // Diformat pakai titik (Rp)
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 32, 
                  color: PastelColors.emerald,
                ),
              ),

              const Spacer(),

              // --- TOMBOL KONFIRMASI ---
              SizedBox(
                width: double.infinity,
                height: 55, // Tinggi disamakan dengan halaman lain
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PastelColors.emerald, // Warna solid
                    foregroundColor: Colors.white,
                    elevation: 0,
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
                          // Note: Karena QRIS uangnya pasti pas, kita nggak usah kirim amountPaid
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Konfirmasi Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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