import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../screens/receipt_screen.dart'; // Sesuaikan path jika receipt_screen ada di dalam folder screens

// Fungsi pop-up peringatan biar seragam dengan halaman lain
void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: PastelColors.rose),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(color: PastelColors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

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

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: cashController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Nominal Uang Diterima",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.payments_outlined, color: PastelColors.emerald),
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
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PastelColors.mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kembalian", style: TextStyle(color: PastelColors.grey)),
              Text(
                formatRupiah(getChange() < 0 ? 0 : getChange()), // Biar kalau kurang nggak minus di UI
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: getChange() < 0 ? PastelColors.rose : PastelColors.emerald,
                  fontSize: 16
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PastelColors.emerald,
              foregroundColor: Colors.white, // warna teks tombol
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              String customer = widget.customerController.text.trim();
              int paidAmount = int.tryParse(cashController.text) ?? 0;

              if (customer.isEmpty) {
                showWarningPopup(context, "Data Belum Lengkap", "Silakan masukkan nama customer terlebih dahulu.");
                return;
              }

              if (cashController.text.isEmpty) {
                showWarningPopup(context, "Nominal Kosong", "Silakan masukkan nominal uang yang dibayarkan oleh customer.");
                return;
              }

              if (paidAmount < widget.total) {
                showWarningPopup(context, "Uang Kurang", "Nominal uang yang dibayarkan kurang dari total belanja.");
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceiptScreen(
                    customer: customer,
                    paymentMethod: widget.paymentMethod,
                    amountPaid: paidAmount, // ---> INI DATA BARU YANG KITA LEMPAR!
                  ),
                ),
              );
            },
            child: const Text(
              "Selesaikan Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        )
      ],
    );
  }
}