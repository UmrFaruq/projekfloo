import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/cart_data.dart';
import '../data/order_data.dart';
import '../data/shift_data.dart';
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
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black87), 
                ),
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

  String getDate() {
    return DateFormat('dd/MM/yyyy HH:mm').format(transactionDate);
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int getSubtotal() {
    int subtotal = 0;
    for (var item in cart) {
      subtotal += item.price * item.qty;
    }
    return subtotal;
  }

  int getTax() {
    return (getSubtotal() * 0.12).round();
  }

  int getTotal() {
    return getSubtotal() + getTax();
  }

  Map<String, Map<String, int>> getMergedItems() {
    Map<String, Map<String, int>> items = {};
    for (var item in cart) {
      if (items.containsKey(item.name)) {
        items[item.name]!['qty'] = items[item.name]!['qty']! + item.qty;
      } else {
        items[item.name] = {
          'qty': item.qty,
          'price': item.price,
        };
      }
    }
    return items;
  }

  void saveOrder() {
    List<Map<String, dynamic>> orderItems = [];
    for (var item in cart) {
      orderItems.add({
        "name": item.name,
        "qty": item.qty,
        "price": item.price,
        "total": item.qty * item.price,
      });
    }

    final order = Order(
      id: transactionId,
      customer: widget.customer,
      paymentMethod: widget.paymentMethod,
      date: transactionDate,
      items: orderItems,
      subtotal: getSubtotal(),
      tax: getTax(),
      total: getTotal(),
    );

    allOrders.value = [...allOrders.value, order];
    shiftOrders.value = [...shiftOrders.value, order];
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = getMergedItems();

    return Scaffold(
      backgroundColor: AppColors.bgLight, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Payment Successful",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary, 
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "FLOO ID",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Jl. Raya Kasir No. 123",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const DashedDivider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("No. Nota:", style: TextStyle(fontSize: 12, color: Colors.black87)),
                            Text(transactionId, style: const TextStyle(fontSize: 12, color: Colors.black87)), // Hapus bold
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tanggal:", style: TextStyle(fontSize: 12, color: Colors.black87)),
                            Text(getDate(), style: const TextStyle(fontSize: 12, color: Colors.black87)), // Hapus w600
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Pelanggan:", style: TextStyle(fontSize: 12, color: Colors.black87)),
                            Text(widget.customer.isEmpty ? "Umum" : widget.customer, style: const TextStyle(fontSize: 12, color: Colors.black87)), // Hapus w600
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Pembayaran:", style: TextStyle(fontSize: 12, color: Colors.black87)),
                            Text(widget.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.black87)), // Hapus bold
                          ],
                        ),
                        
                        const DashedDivider(),

                        ...mergedItems.entries.map((entry) {
                          String name = entry.key;
                          int qty = entry.value['qty']!;
                          int price = entry.value['price']!;
                          int total = qty * price;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(name, style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w500
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text("x$qty", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(formatRupiah(total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w500
                                ),
                              ],
                            ),
                          );
                        }),
                        
                        const DashedDivider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal", style: TextStyle(fontSize: 13, color: Colors.black87)),
                            Text(formatRupiah(getSubtotal()), style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w600
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tax (12%)", style: TextStyle(fontSize: 13, color: Colors.black87)),
                            Text(formatRupiah(getTax()), style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w600
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "TOTAL",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), // Tetap Bold
                            ),
                            Text(
                              formatRupiah(getTotal()),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), // Tetap Bold
                            ),
                          ],
                        ),

                        if (widget.paymentMethod == "cash" && widget.amountPaid != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tunai", style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(formatRupiah(widget.amountPaid!), style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w600
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Kembalian", style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(formatRupiah(widget.amountPaid! - getTotal()), style: const TextStyle(fontSize: 13, color: Colors.black87)), // Hapus w600
                            ],
                          ),
                        ],

                        const SizedBox(height: 30),
                        const Text(
                          "Terima kasih atas kunjungan Anda!",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                        const Text(
                          "Barang yang sudah dibeli tidak dapat ditukar.",
                          style: TextStyle(fontSize: 10, color: Colors.black87),
                        )
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.print, color: Colors.white),
                                SizedBox(width: 10),
                                Text("Mencetak struk...", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: AppColors.primary, 
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        cart.clear();
                        updateCart();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalesScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}