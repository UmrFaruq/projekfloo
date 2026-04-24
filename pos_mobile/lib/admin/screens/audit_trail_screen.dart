import 'package:flutter/material.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
// IMPORT DRAWER SENTRAL
import 'admin_drawer.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  bool isLoading = false;

  // --- DATA DUMMY SEMENTARA UNTUK PREVIEW UI ---
  // Nanti bisa ditarik dari tabel 'sys_logs' atau 'audit_trail' di Supabase abang
  final List<Map<String, dynamic>> auditLogs = [
    {
      "time": "14 Apr 2026, 09:15",
      "user": "NaWa",
      "role": "Cashier",
      "action": "START SHIFT",
      "detail": "NaWa memulai shift pagi.",
      "type": "login"
    },
    {
      "time": "14 Apr 2026, 08:30",
      "user": "Super Admin",
      "role": "Owner",
      "action": "UPDATE STOCK",
      "detail": "Menambahkan 50 pcs Indomie Goreng.",
      "type": "update"
    },
    {
      "time": "13 Apr 2026, 21:00",
      "user": "Super Admin",
      "role": "Owner",
      "action": "DELETE PRODUCT",
      "detail": "Menghapus produk 'Kopi Hitam Kadaluarsa'.",
      "type": "delete"
    },
    {
      "time": "13 Apr 2026, 16:00",
      "user": "Budi",
      "role": "Cashier",
      "action": "END SHIFT",
      "detail": "Budi mengakhiri shift sore. Total Sales: Rp 1.500.000",
      "type": "logout"
    },
    {
      "time": "13 Apr 2026, 10:00",
      "user": "Super Admin",
      "role": "Owner",
      "action": "ADD PRODUCT",
      "detail": "Menambahkan produk baru 'Oreo Supreme'.",
      "type": "create"
    },
  ];

  // --- FUNGSI UNTUK MENENTUKAN ICON BERDASARKAN TIPE AKTIVITAS ---
  IconData _getLogIcon(String type) {
    switch (type) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'login': return Icons.login;
      case 'logout': return Icons.logout;
      default: return Icons.info_outline;
    }
  }

  // --- FUNGSI UNTUK MENENTUKAN WARNA BERDASARKAN TIPE AKTIVITAS ---
  Color _getLogColor(String type) {
    switch (type) {
      case 'create': return AppColors.primary; // Toska
      case 'update': return AppColors.warning; // Orange/Kuning
      case 'delete': return AppColors.error; // Merah
      case 'login': return Colors.blue;
      case 'logout': return Colors.purple;
      default: return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- MENGGUNAKAN DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Audit Trail")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Audit Trail", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), // Judul Hitam
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary), // Icon Filter Toska
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur filter tanggal segera hadir!"),
                  backgroundColor: AppColors.primary,
                )
              );
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Loading Toska
          : Column(
              children: [
                // --- HEADER INFO ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary, // Header Kotak Toska Solid
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Log Aktivitas Sistem", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Pantau semua perubahan data dan aktivitas user di aplikasi.", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                // --- LIST LOGS / TIMELINE ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: auditLogs.isEmpty
                        ? const Center(child: Text("Belum ada log aktivitas.", style: TextStyle(color: AppColors.textGrey)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: auditLogs.length,
                            separatorBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Divider(color: Colors.grey.shade200),
                            ),
                            itemBuilder: (context, index) {
                              final log = auditLogs[index];
                              final logColor = _getLogColor(log['type']);
                              final logIcon = _getLogIcon(log['type']);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ICON TIMELINE
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: logColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(logIcon, color: logColor, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // DETAIL AKTIVITAS
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(log['action'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: logColor)),
                                            Text(log['time'], style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(log['detail'], style: const TextStyle(fontSize: 14, color: Colors.black87)), // Detail log hitam
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 12, color: AppColors.textGrey),
                                            const SizedBox(width: 4),
                                            Text("${log['user']} (${log['role']})", style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}