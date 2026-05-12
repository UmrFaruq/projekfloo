import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart'; 
import '../data/cart_data.dart';
import '../data/order_data.dart';
  import '../models/order.dart';
import '../theme/colors.dart';
import 'sales_screen.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth, height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.black87)),
              );
            }),
          );
        },
      ),
    );
  }
}

class ReceiptScreen extends StatefulWidget {
  final String customer;
  final String paymentMethod;
  final int? amountPaid;

  const ReceiptScreen({
    super.key,
    required this.customer,
    required this.paymentMethod,
    this.amountPaid,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late String transactionId;
  late DateTime transactionDate;

  @override
  void initState() {
    super.initState();
    transactionDate = DateTime.now();
    transactionId = "TXN${transactionDate.millisecondsSinceEpoch}";
    saveOrder(); 
  }

  String getDate() => DateFormat('dd/MM/yyyy HH:mm').format(transactionDate);
  String formatRupiah(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  int getSubtotal() {
    int subtotal = 0;
    for (var item in cart) {
      subtotal += item.price * item.qty;
    }
    return subtotal;
  }

  Map<String, Map<String, int>> getMergedItems() {
    Map<String, Map<String, int>> items = {};
    for (var item in cart) {
      if (items.containsKey(item.name)) {
        items[item.name]!['qty'] = items[item.name]!['qty']! + item.qty;
      } else {
        items[item.name] = {'qty': item.qty, 'price': item.price};
      }
    }
    return items;
  }

  // 🔥 KALKULASI LOKAL SAKTI: CEK PAYMENT METHOD 🔥
  Map<String, int> _kalkulasiBiaya(int subtotal, String currentMethod) {
    int tax = (subtotal * globalTaxRate).toInt();
    int total = subtotal + tax;
    int rounding = 0;

    bool isCash = currentMethod.toLowerCase() == 'cash' || currentMethod.toLowerCase() == 'tunai';

    if (globalIsRounding && isCash) {
      int sisa = total % 100;
      if (sisa > 0) {
        rounding = sisa;
        total -= rounding;
      }
    }

    return {'tax': tax, 'rounding': rounding, 'total': total};
  }

  void saveOrder() {
    final kalkulasi = _kalkulasiBiaya(getSubtotal(), widget.paymentMethod);
    
    List<Map<String, dynamic>> orderItems = [];
    for (var item in cart) {
      orderItems.add({"name": item.name, "qty": item.qty, "price": item.price, "total": item.qty * item.price});
    }
    
    final order = Order(
      id: transactionId,
      customer: widget.customer,
      paymentMethod: widget.paymentMethod,
      date: transactionDate,
      items: orderItems,
      subtotal: getSubtotal(),
      tax: kalkulasi['tax']!, 
      total: kalkulasi['total']!, 
    );
    allOrders.value = [...allOrders.value, order];
    shiftOrders.value = [...shiftOrders.value, order];
  }

  Future<void> _printReceipt() async {
    final pdf = pw.Document();
    final mergedItems = getMergedItems();
    final kalkulasi = _kalkulasiBiaya(getSubtotal(), widget.paymentMethod);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, 
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("FLOO ID", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text("Jl. Raya Kasir No. 123", style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("No:", style: const pw.TextStyle(fontSize: 10)), pw.Text(transactionId, style: const pw.TextStyle(fontSize: 10))]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Tgl:", style: const pw.TextStyle(fontSize: 10)), pw.Text(getDate(), style: const pw.TextStyle(fontSize: 10))]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Plg:", style: const pw.TextStyle(fontSize: 10)), pw.Text(widget.customer.isEmpty ? "Umum" : widget.customer, style: const pw.TextStyle(fontSize: 10))]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Byr:", style: const pw.TextStyle(fontSize: 10)), pw.Text(widget.paymentMethod.toUpperCase(), style: const pw.TextStyle(fontSize: 10))]),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              ...mergedItems.entries.map((entry) {
                return pw.Column(
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(flex: 1, child: pw.Text("x${entry.value['qty']}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(flex: 3, child: pw.Text(formatRupiah(entry.value['qty']! * entry.value['price']!), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                  ],
                );
              }),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Subtotal", style: const pw.TextStyle(fontSize: 10)), pw.Text(formatRupiah(getSubtotal()), style: const pw.TextStyle(fontSize: 10))]),
              
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("$globalTaxName (${(globalTaxRate * 100).toInt()}%)", style: const pw.TextStyle(fontSize: 10)), pw.Text(formatRupiah(kalkulasi['tax']!), style: const pw.TextStyle(fontSize: 10))]),
              
              if (globalIsRounding && kalkulasi['rounding']! > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Pembulatan", style: const pw.TextStyle(fontSize: 10)), pw.Text("-${formatRupiah(kalkulasi['rounding']!)}", style: const pw.TextStyle(fontSize: 10))]),
              ],

              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatRupiah(kalkulasi['total']!), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              if ((widget.paymentMethod.toLowerCase() == "cash" || widget.paymentMethod.toLowerCase() == "tunai") && widget.amountPaid != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Tunai", style: const pw.TextStyle(fontSize: 10)), pw.Text(formatRupiah(widget.amountPaid!), style: const pw.TextStyle(fontSize: 10))]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Kembalian", style: const pw.TextStyle(fontSize: 10)), pw.Text(formatRupiah(widget.amountPaid! - kalkulasi['total']!), style: const pw.TextStyle(fontSize: 10))]),
              ],

              pw.SizedBox(height: 15),
              pw.Center(child: pw.Text("Terima kasih atas kunjungan Anda!", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic))),
              pw.Center(child: pw.Text("Barang yang sudah dibeli tidak dapat ditukar.", style: const pw.TextStyle(fontSize: 8))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk_$transactionId', 
    );
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = getMergedItems();
    final kalkulasi = _kalkulasiBiaya(getSubtotal(), widget.paymentMethod); 

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Payment Successful", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("FLOO ID", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black87)),
                        const SizedBox(height: 4),
                        const Text("Jl. Raya Kasir No. 123", style: TextStyle(fontSize: 12, color: Colors.black87)),
                        const DashedDivider(),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("No. Nota:", style: TextStyle(fontSize: 12, color: Colors.black87)), Text(transactionId, style: const TextStyle(fontSize: 12, color: Colors.black87))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tanggal:", style: TextStyle(fontSize: 12, color: Colors.black87)), Text(getDate(), style: const TextStyle(fontSize: 12, color: Colors.black87))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Pelanggan:", style: TextStyle(fontSize: 12, color: Colors.black87)), Text(widget.customer.isEmpty ? "Umum" : widget.customer, style: const TextStyle(fontSize: 12, color: Colors.black87))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Pembayaran:", style: TextStyle(fontSize: 12, color: Colors.black87)), Text(widget.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.black87))]),

                        const DashedDivider(),

                        ...mergedItems.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: Text(entry.key, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                Expanded(flex: 1, child: Text("x${entry.value['qty']}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                Expanded(flex: 3, child: Text(formatRupiah(entry.value['qty']! * entry.value['price']!), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              ],
                            ),
                          );
                        }),

                        const DashedDivider(),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal", style: TextStyle(fontSize: 13, color: Colors.black87)), Text(formatRupiah(getSubtotal()), style: const TextStyle(fontSize: 13, color: Colors.black87))]),
                        const SizedBox(height: 6),
                        
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("$globalTaxName (${(globalTaxRate * 100).toInt()}%)", style: const TextStyle(fontSize: 13, color: Colors.black87)), Text(formatRupiah(kalkulasi['tax']!), style: const TextStyle(fontSize: 13, color: Colors.black87))]),
                        
                        if (globalIsRounding && kalkulasi['rounding']! > 0) ...[
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Pembulatan", style: TextStyle(fontSize: 13, color: Colors.black87)), Text("- ${formatRupiah(kalkulasi['rounding']!)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))]),
                        ],

                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), Text(formatRupiah(kalkulasi['total']!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))]),

                        if ((widget.paymentMethod.toLowerCase() == "cash" || widget.paymentMethod.toLowerCase() == "tunai") && widget.amountPaid != null) ...[
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tunai", style: TextStyle(fontSize: 13, color: Colors.black87)), Text(formatRupiah(widget.amountPaid!), style: const TextStyle(fontSize: 13, color: Colors.black87))]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Kembalian", style: TextStyle(fontSize: 13, color: Colors.black87)), Text(formatRupiah(widget.amountPaid! - kalkulasi['total']!), style: const TextStyle(fontSize: 13, color: Colors.black87))]),
                        ],

                        const SizedBox(height: 30),
                        const Text("Terima kasih atas kunjungan Anda!", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                        const Text("Barang yang sudah dibeli tidak dapat ditukar.", style: TextStyle(fontSize: 10, color: Colors.black87))
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.print, color: AppColors.primary),
                      onPressed: _printReceipt, 
                      label: const Text("Print Struk", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        cart.clear();
                        updateCart();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SalesScreen()), (route) => false);
                      },
                      child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}