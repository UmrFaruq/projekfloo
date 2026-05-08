import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../theme/colors.dart';
import 'admin_drawer.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  // --- DATA AUDIT DARI SUPABASE ---
  List<Map<String, dynamic>> auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  // --- FETCH DATA AUDIT TRAIL ---
  Future<void> _fetchAuditLogs() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('audit_trail')
          .select('''
            *,
            ms_user (
              username,
              role
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        auditLogs = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetch audit logs: $e");

      setState(() => isLoading = false);
    }
  }

  // --- ICON BERDASARKAN TIPE ---
  IconData _getLogIcon(String type) {
    switch (type.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;

      case 'update':
        return Icons.edit_outlined;

      case 'delete':
        return Icons.delete_outline;

      case 'login':
        return Icons.login;

      case 'logout':
        return Icons.logout;

      default:
        return Icons.info_outline;
    }
  }

  // --- WARNA BERDASARKAN TIPE ---
  Color _getLogColor(String type) {
    switch (type.toLowerCase()) {
      case 'create':
        return AppColors.primary;

      case 'update':
        return AppColors.warning;

      case 'delete':
        return AppColors.error;

      case 'login':
        return Colors.blue;

      case 'logout':
        return Colors.purple;

      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,

      // --- DRAWER ---
      drawer: const SizedBox(
        width: 260,
        child: AdminDrawer(activeMenu: "Audit Trail"),
      ),

      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),

        title: const Text(
          "Audit Trail",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur filter tanggal segera hadir!"),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.all(16),

                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Log Aktivitas Sistem",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Pantau semua perubahan data dan aktivitas user di aplikasi.",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- LIST LOG ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),

                    child: auditLogs.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada log aktivitas.",
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),

                            itemCount: auditLogs.length,

                            separatorBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(left: 30),

                              child: Divider(color: Colors.grey.shade200),
                            ),

                            itemBuilder: (context, index) {
                              final log = auditLogs[index];

                              final String logType = (log['type'] ?? '')
                                  .toString();

                              final logColor = _getLogColor(logType);

                              final logIcon = _getLogIcon(logType);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  // --- ICON ---
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),

                                        padding: const EdgeInsets.all(8),

                                        decoration: BoxDecoration(
                                          color: logColor.withOpacity(0.1),

                                          shape: BoxShape.circle,
                                        ),

                                        child: Icon(
                                          logIcon,
                                          color: logColor,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 16),

                                  // --- DETAIL ---
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,

                                          children: [
                                            Expanded(
                                              child: Text(
                                                log['action'] ?? '-',

                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,

                                                  fontSize: 13,

                                                  color: logColor,
                                                ),
                                              ),
                                            ),

                                            Text(
                                              log['created_at']
                                                      ?.toString()
                                                      .substring(0, 16) ??
                                                  '-',

                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          log['detail'] ?? '-',

                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 12,
                                              color: AppColors.textGrey,
                                            ),

                                            const SizedBox(width: 4),

                                            Text(
                                              "${log['ms_user']?['username'] ?? 'Unknown'} "
                                              "(${log['ms_user']?['role'] ?? '-'})",

                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textGrey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
