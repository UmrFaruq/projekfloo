import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORT UNTUK EXCEL (.xlsx) ---
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool isLoading = true;

  int totalPendapatan = 0;
  int totalTransaksi = 0;
  List<Map<String, dynamic>> riwayatTransaksi = [];

  String filterWaktu = "Hari Ini"; 

  @override
  void initState() {
    super.initState();
    _fetchLaporanDummy();
  }

  // --- AMBIL DATA DUMMY ---
  Future<void> _fetchLaporanDummy() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); 

    final dummyData = [
      {"id_transaksi": "TRX-1001", "waktu": "14 Apr 2026, 09:15", "kasir": "NaWa", "total": 125000},
      {"id_transaksi": "TRX-1002", "waktu": "14 Apr 2026, 10:30", "kasir": "NaWa", "total": 45000},
      {"id_transaksi": "TRX-1003", "waktu": "14 Apr 2026, 11:45", "kasir": "Budi", "total": 210000},
      {"id_transaksi": "TRX-1004", "waktu": "14 Apr 2026, 13:20", "kasir": "NaWa", "total": 75000},
      {"id_transaksi": "TRX-1005", "waktu": "14 Apr 2026, 14:10", "kasir": "Siti", "total": 350000},
    ];

    int hitungPendapatan = 0;
    for (var trx in dummyData) {
      hitungPendapatan += trx['total'] as int;
    }

    if (mounted) {
      setState(() {
        riwayatTransaksi = dummyData;
        totalTransaksi = dummyData.length;
        totalPendapatan = hitungPendapatan;
        isLoading = false;
      });
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // =========================================================
  // --- FUNGSI EXCEL YANG SUDAH DIPERBAIKI (BEBAS ERROR MERAH) ---
  // =========================================================
  Future<void> _exportKeExcelReal() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan Penjualan'];
      
      // Hapus Sheet1 bawaan biar rapi
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1'); 
      }

      // 3. Tambahkan Judul (Pake TextCellValue karena strict type)
      sheetObject.appendRow([TextCellValue("LAPORAN PENJUALAN - $filterWaktu")]);
      sheetObject.appendRow([TextCellValue("Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}")]);
      sheetObject.appendRow([TextCellValue("")]); // Baris kosong

      // 4. Bikin Header Kolom
      sheetObject.appendRow([
        TextCellValue("ID Transaksi"),
        TextCellValue("Waktu"),
        TextCellValue("Kasir"),
        TextCellValue("Total Pendapatan"),
      ]);

      // 5. Masukin Data Transaksi
      for (var trx in riwayatTransaksi) {
        sheetObject.appendRow([
          TextCellValue(trx['id_transaksi'].toString()),
          TextCellValue(trx['waktu'].toString()),
          TextCellValue(trx['kasir'].toString()),
          IntCellValue(trx['total'] as int), // Ini biar jadi format Angka di Excel
        ]);
      }

      // 6. Baris Total di paling bawah
      sheetObject.appendRow([TextCellValue("")]);
      sheetObject.appendRow([
        TextCellValue("TOTAL PENDAPATAN"),
        TextCellValue(""),
        TextCellValue(""),
        IntCellValue(totalPendapatan),
      ]);

      // 7. Simpan ke File
      var fileBytes = excel.save();
      if (fileBytes == null) return; // Jaga-jaga kalau gagal generate

      final directory = await getTemporaryDirectory();
      String fileName = "Laporan_${filterWaktu.replaceAll(" ", "_")}.xlsx";
      final File file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(fileBytes);

      // 8. Share/Save
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Penjualan $filterWaktu');
      
    } catch (e) {
      debugPrint("Error Excel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal export .xlsx: $e"), backgroundColor: AppColors.error) // Merah
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Sales Report")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Sales Report", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppColors.primary), // Icon download toska
            onPressed: () async {
              if (riwayatTransaksi.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data"), backgroundColor: AppColors.error)); // Merah
                return;
              }
              await _exportKeExcelReal();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading toska
          : Column(
              children: [
                // --- 1. FILTER WAKTU (CHIPS DI TENGAH) ---
                Container(
                  width: double.infinity,
                  color: Colors.transparent, // Transparan mengikuti background scaffold
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((filter) {
                      bool isSelected = filterWaktu == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => filterWaktu = filter);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white, // Toska kalau dipilih
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87, // Teks putih atau hitam
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // --- 2. SUMMARY CARDS ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Toska solid
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text("Pendapatan", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                formatRupiah(totalPendapatan), 
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, color: AppColors.textGrey, size: 22),
                                  SizedBox(width: 8),
                                  Text("Transaksi", style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "$totalTransaksi", 
                                style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold), // Angka hitam tebal
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 3. LIST RIWAYAT TRANSAKSI ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text("Riwayat Transaksi Terbaru", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul hitam
                        ),
                        Expanded(
                          child: riwayatTransaksi.isEmpty
                              ? const Center(child: Text("Belum ada transaksi hari ini.", style: TextStyle(color: AppColors.textGrey)))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: riwayatTransaksi.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final trx = riwayatTransaksi[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                        child: const Icon(Icons.check_circle, color: AppColors.primary, size: 24), // Icon toska
                                      ),
                                      title: Text(trx['id_transaksi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)), // Teks hitam
                                      subtitle: Text("Kasir: ${trx['kasir']} • ${trx['waktu']}", style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                                      trailing: Text(
                                        formatRupiah(trx['total']),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14), // Harga toska gelap
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}