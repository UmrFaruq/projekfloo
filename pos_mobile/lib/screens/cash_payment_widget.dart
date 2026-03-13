import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'receipt_screen.dart';

class CashPaymentWidget extends StatefulWidget {

  final int total;
  final TextEditingController customerController;
  final String paymentMethod;

  const CashPaymentWidget({
    super.key,
    required this.total,
    required this.customerController,
    required this.paymentMethod,
  });

  @override
  State<CashPaymentWidget> createState() => _CashPaymentWidgetState();
}

class _CashPaymentWidgetState extends State<CashPaymentWidget> {

  final TextEditingController cashController = TextEditingController();

  int getChange() {
    int paid = int.tryParse(cashController.text) ?? 0;
    return paid - widget.total;
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        TextField(
          controller: cashController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Uang dibayar",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            setState(() {});
          },
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Kembalian"),
            Text(
              "Rp ${getChange()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,

          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PastelColors.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            onPressed: () {

              String customer = widget.customerController.text.trim();

              if (customer.isEmpty) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nama customer wajib diisi"),
                  ),
                );

                return;
              }

              if (cashController.text.isEmpty) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Uang yang dibayar wajib diisi"),
                  ),
                );

                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceiptScreen(
                    customer: customer,
                    paymentMethod: widget.paymentMethod,
                  ),
                ),
              );
            },

            child: const Text(
              "Selesaikan Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        )
      ],
    );
  }
}