import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../data/cart_data.dart';
import 'receipt_screen.dart';

void showWarningPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "OK",
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class QRISScreen extends StatefulWidget {
  final int total; // Ini udah total yang dibulatkan dari Checkout
  final String customer;
  final String paymentMethod;

  const QRISScreen({
    super.key,
    required this.total,
    required this.customer,
    required this.paymentMethod,
  });

  @override
  State<QRISScreen> createState() => _QRISScreenState();
}

class _QRISScreenState extends State<QRISScreen> {
  bool _isLoading = false;

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _prosesTransaksiQris() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final shiftData = await supabase
          .from('tr_shift')
          .select('id, user_id')
          .eq('status', 'open')
          .limit(1)
          .maybeSingle();
      if (shiftData == null) throw Exception("Shift belum dibuka!");

      final String shiftId = shiftData['id'];
      final String userId = shiftData['user_id'];

      String? customerId;
      if (widget.customer.isNotEmpty) {
        final existingCust = await supabase
            .from('ms_customer')
            .select('id')
            .eq('name', widget.customer)
            .limit(1)
            .maybeSingle();
        if (existingCust != null) {
          customerId = existingCust['id'];
        } else {
          final newCust = await supabase
              .from('ms_customer')
              .insert({'name': widget.customer})
              .select('id')
              .single();
          customerId = newCust['id'];
        }
      }

      // 🔥 HITUNG ULANG PAKAI MESIN SAKTI BIAR PAJAKNYA PRESISI 🔥
      int subtotal = 0;
      for (var item in cart) {
        subtotal += (item.price * item.qty).toInt();
      }
      final kalkulasi = hitungFinal(subtotal);

      final String invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      final salesRes = await supabase
          .from('tr_sales')
          .insert({
            'no_invoice': invoiceNo,
            'user_id': userId,
            'customer_id': customerId,
            'shift_id': shiftId,
            'subtotal': subtotal,
            'tax': kalkulasi['tax']!, // Pake pajak dari mesin sakti
            'total': kalkulasi['total']!, // Pake total bulat dari mesin sakti
            'payment_method': widget.paymentMethod.toLowerCase(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final String salesId = salesRes['id'];

      List<Map<String, dynamic>> details = [];
      for (var item in cart) {
        details.add({
          'sales_id': salesId,
          'product_id': item.id,
          'qty': item.qty,
          'price': item.price,
          'subtotal': item.price * item.qty,
        });

        final pData = await supabase
            .from('ms_product')
            .select('qty')
            .eq('id', item.id)
            .limit(1)
            .single();
        int currentStock = pData['qty'] ?? 0;
        await supabase
            .from('ms_product')
            .update({'qty': currentStock - item.qty})
            .eq('id', item.id);

        await supabase.from('tr_stock').insert({
          'user_id': userId,
          'product_id': item.id,
          'type': 'out',
          'qty': item.qty,
          'description':
              'Penjualan ${widget.paymentMethod.toUpperCase()} - Invoice: $invoiceNo',
        });
      }

      await supabase.from('tr_sales_details').insert(details);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              amountPaid: kalkulasi['total']!,
              customer: widget.customer,
              paymentMethod: widget.paymentMethod,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showWarningPopup(context, "Transaksi Gagal", "Pesan Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "${widget.paymentMethod.toUpperCase()} Payment",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                "Scan Barcode ${widget.paymentMethod.toUpperCase()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Arahkan kamera atau aplikasi e-wallet Anda ke Barcode di bawah ini untuk membayar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 40),

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
                    ),
                  ],
                ),
                child: QrImageView(
                  data: "POS_PAYMENT_${widget.total}_${widget.paymentMethod}",
                  size: 220,
                  foregroundColor: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "Total Pembayaran",
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(widget.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: AppColors.primaryDark,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _prosesTransaksiQris,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Konfirmasi Pembayaran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
