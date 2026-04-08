import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

class ReportHelper {
  static Future<void> downloadExcel(List<Order> orders, String title) async {
    if (orders.isEmpty) return;

    // Formatter buat bikin titik (1.000.000)
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'Laporan Penjualan');
    Sheet sheetObject = excel['Laporan Penjualan'];

    // 1. Header
    var headers = ["Order ID", "Tanggal", "Waktu", "Customer", "Payment", "Total", "Items"];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
    }

    // 2. Data Transaksi
    int grandTotal = 0;
    int currentRow = 1;

    for (var order in orders) {
      String date = DateFormat('dd/MM/yyyy').format(order.date);
      String time = DateFormat('HH:mm').format(order.date);
      String itemsStr = order.items.map((it) => "${it['name']} (x${it['qty']})").join(", ");
      
      grandTotal += order.total;

      // Format angka jadi ada titiknya (Contoh: 15.000)
      String formattedTotal = formatter.format(order.total).trim();

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(order.id);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(date);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(time);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(order.customer.isEmpty ? "Umum" : order.customer);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(order.paymentMethod.toUpperCase());
      
      // DISINI KITA KIRIM SEBAGAI TEXT BIAR TITIKNYA GAK ILANG
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(formattedTotal);
      
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = TextCellValue(itemsStr);
      
      currentRow++;
    }

    // 3. Baris Total (Juga dikasih titik)
    currentRow++; 
    String formattedGrandTotal = formatter.format(grandTotal).trim();

    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue("TOTAL PENDAPATAN:");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(formattedGrandTotal);

    // 4. Save & Share
    var fileBytes = excel.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');

    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Penjualan');
    }
  }
}