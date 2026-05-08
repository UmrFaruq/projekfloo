import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- IMPORT SUPABASE
import '../services/session_service.dart';

import '../theme/colors.dart';
import '../data/order_data.dart';
import '../data/shift_data.dart';
import '../data/report_helper.dart';
import 'sales_screen.dart';
import 'cashier_drawer.dart';

// --- NOTIFIER BARU KHUSUS UNTUK DATA TRANSAKSI DARI SUPABASE ---
final ValueNotifier<List<Map<String, dynamic>>> supabaseRecentOrders =
    ValueNotifier([]);

// --- FUNGSI GLOBAL UNTUK POP-UP WARNING ---
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

// --- FUNGSI GLOBAL UNTUK FORMAT RUPIAH ---
String formatRupiah(int amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      drawer: const SizedBox(
        width: 250,
        child: CashierDrawer(activeMenu: "Dashboard"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardHeader(),
              SizedBox(height: 24),
              ShiftSummaryCard(),
              SizedBox(height: 20),
              RecentTransactionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 28, color: Colors.black87),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Hello, ${SessionService.username ?? 'Kasir'} 👋",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ShiftSummaryCard extends StatefulWidget {
  const ShiftSummaryCard({super.key});

  @override
  State<ShiftSummaryCard> createState() => _ShiftSummaryCardState();
}

class _ShiftSummaryCardState extends State<ShiftSummaryCard> {
  final TextEditingController openingController = TextEditingController();
  DateTime? _shiftStartTime;

  // Variabel untuk nyimpen omzet asli dari Supabase
  int totalRevenue = 0;
  int cashSales = 0;
  int qrisSales = 0;
  int totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    // Otomatis tarik data omzet pas halaman Dashboard dibuka
    _loadShiftSummary();
  }

  // 🔥 FUNGSI NARIK OMZET ASLI DARI SUPABASE 🔥
  Future<void> _loadShiftSummary() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Cari shift yang lagi buka
      final shiftData = await supabase
          .from('tr_shift')
          .select('id, shift_start, initial_capital')
          .eq('status', 'open')
          .maybeSingle();

      if (shiftData != null) {
        shiftActive.value = true;
        openingBalance.value = shiftData['initial_capital'] ?? 0;
        _shiftStartTime = DateTime.parse(shiftData['shift_start']);

        // 2. Tarik semua data penjualan di shift ini
        final sales = await supabase
            .from('tr_sales')
            .select('total, payment_method, ms_customer(name)')
            .eq('shift_id', shiftData['id'])
            .order('created_at', ascending: false);

        int tempRev = 0;
        int tempCash = 0;
        int tempQris = 0;
        List<Map<String, dynamic>> tempOrders = [];

        for (var s in sales) {
          int t = s['total'] ?? 0;
          tempRev += t;

          String method = s['payment_method'] ?? 'cash';
          if (method == 'cash') tempCash += t;
          if (method == 'qris') tempQris += t;

          tempOrders.add({
            'customer': s['ms_customer'] != null
                ? s['ms_customer']['name']
                : 'Pelanggan Umum',
            'payment_method': method,
            'total': t,
          });
        }

        // 3. Update tampilan Dashboard
        setState(() {
          totalRevenue = tempRev;
          cashSales = tempCash;
          qrisSales = tempQris;
          totalTransactions = sales.length;
        });

        // 4. Update data list transaksi terbaru
        supabaseRecentOrders.value = tempOrders;
      } else {
        shiftActive.value = false;
        openingBalance.value = 0;
        setState(() {
          totalRevenue = 0;
          cashSales = 0;
          qrisSales = 0;
          totalTransactions = 0;
        });
        supabaseRecentOrders.value = [];
      }
    } catch (e) {
      debugPrint("Gagal narik summary shift: $e");
    }
  }

  // 🔥 FUNGSI START SHIFT OTOMATIS KE SUPABASE 🔥
  Future<void> startShift(BuildContext context) async {
    if (openingController.text.trim().isEmpty) {
      showWarningPopup(context, "Perhatian", "Opening balance wajib diisi.");
      return;
    }

    String cleanText = openingController.text.replaceAll('.', '');
    int balance = int.tryParse(cleanText) ?? 0;

    if (balance <= 0) {
      showWarningPopup(
        context,
        "Perhatian",
        "Opening balance harus lebih dari 0.",
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final supabase = Supabase.instance.client;

      final user = {
        'id': SessionService.userId,
        'username': SessionService.username,
        'role': SessionService.role,
      };

      final existingShift = await supabase
          .from('tr_shift')
          .select('id')
          .eq('user_id', SessionService.userId!)
          .eq('status', 'open')
          .maybeSingle();

      if (existingShift != null) {
        if (mounted) Navigator.pop(context);

        showWarningPopup(
          context,
          "Shift Masih Aktif",
          "Kasir ini masih memiliki shift yang belum ditutup.",
        );
        return;
      }

      await supabase.from('tr_shift').insert({
        'user_id': user['id'],
        'initial_capital': balance,
        'status': 'open',
        'shift_start': DateTime.now().toIso8601String(),
      });

      await supabase.from('audit_trail').insert({
        'user_id': user['id'],
        'action': 'Start Shift',
        'detail': 'Kasir membuka shift baru',
        'type': 'shift',
      });

      if (mounted) Navigator.pop(context);

      // Reload ulang datanya biar refresh
      await _loadShiftSummary();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SalesScreen()),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showWarningPopup(context, "Gagal Buka Shift", "Pesan Error: $e");
    }
  }

  // 🔥 FUNGSI END SHIFT OTOMATIS KE SUPABASE 🔥
  void endShift(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Akhiri Shift?",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Apakah kamu yakin ingin mengakhiri shift ini dan menyimpan laporannya?",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(color: AppColors.error),
                ),
              );

              try {
                final supabase = Supabase.instance.client;

                final shiftData = await supabase
                    .from('tr_shift')
                    .select('id')
                    .eq('status', 'open')
                    .maybeSingle();

                if (shiftData != null) {
                  await supabase
                      .from('tr_shift')
                      .update({
                        'status': 'closed',
                        'shift_end': DateTime.now().toIso8601String(),
                        'total_sales':
                            totalRevenue, // SIMPAN OMZET ASLI SAAT TUTUP SHIFT
                      })
                      .eq('id', shiftData['id']);
                }

                if (mounted) Navigator.pop(context);

                setState(() {
                  shiftActive.value = false;
                  openingBalance.value = 0;
                  _shiftStartTime = null;
                  totalRevenue = 0;
                  cashSales = 0;
                  qrisSales = 0;
                  totalTransactions = 0;
                });

                shiftOrders.value = [];
                supabaseRecentOrders.value = [];
              } catch (e) {
                if (mounted) Navigator.pop(context);
                showWarningPopup(
                  context,
                  "Gagal Tutup Shift",
                  "Pesan Error: $e",
                );
              }
            },
            child: const Text(
              "Akhiri",
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: shiftActive,
      builder: (context, active, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Shift Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (active && _shiftStartTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Started at: ${DateFormat('HH:mm').format(_shiftStartTime!)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? "ACTIVE" : "INACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? AppColors.primary : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!active)
                TextField(
                  controller: openingController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyFormatInputFormatter(),
                  ],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: "Opening Balance",
                    labelStyle: const TextStyle(color: AppColors.textGrey),
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _stat("Opening Balance", formatRupiah(openingBalance.value)),
                  _stat(
                    "Total Revenue",
                    formatRupiah(totalRevenue),
                  ), // <-- DARI SUPABASE
                  _stat(
                    "Cash Sales",
                    formatRupiah(cashSales),
                  ), // <-- DARI SUPABASE
                  _stat(
                    "QRIS Sales",
                    formatRupiah(qrisSales),
                  ), // <-- DARI SUPABASE
                  _stat(
                    "Transactions",
                    "$totalTransactions",
                  ), // <-- DARI SUPABASE
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!active) {
                          startShift(context);
                        } else {
                          endShift(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        active ? "End Shift" : "Start Shift",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Fitur Laporan Excel bisa di-update nanti setelah tabel lengkap
                        showWarningPopup(
                          context,
                          "Info",
                          "Fitur Excel sedang disinkronisasi dengan Supabase.",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Download Report",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: supabaseRecentOrders,
      builder: (context, orders, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No transactions yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ...orders.take(5).map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['customer'] ?? 'Pelanggan',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              (order['payment_method'] ?? 'CASH')
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(order['total'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// --- MESIN AUTO TITIK RUPIAH ---
class CurrencyFormatInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    final int value = int.parse(cleanText);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
