import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: PastelColors.mint,

      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        title: const Text(
          "QRIS Payment",
          style: TextStyle(color: PastelColors.grey),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "Scan QR untuk membayar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: "POS_PAYMENT_$total",
                size: 220,
              ),
            ),

            const SizedBox(height: 20),

            Text("Total : Rp $total"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.sage,
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

                child: const Text("Konfirmasi Pembayaran"),
              ),
            )
          ],
        ),
      ),
    );
  }
}