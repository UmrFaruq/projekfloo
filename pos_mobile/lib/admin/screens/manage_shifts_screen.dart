import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Wajib buat fitur Share ke Grup WA

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../../../theme/colors.dart';
import '../../../../screens/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_product_screen.dart';
import 'manage_category_screen.dart';
import 'manage_cashier_screen.dart';
import 'manage_payment_screen.dart';
import 'manage_stock_screen.dart';
import 'purchase_incoming_screen.dart';
import 'sales_report_screen.dart';
import 'audit_trail_screen.dart';

class ManageShiftsScreen extends StatefulWidget {
  const ManageShiftsScreen({super.key});

  @override
  State<ManageShiftsScreen> createState() => _ManageShiftsScreenState();
}

class _ManageShiftsScreenState extends State<ManageShiftsScreen> {
  bool isLoading = false;

  // --- CONTROLLER UNTUK FORM TAMBAH/EDIT JADWAL ---
  final TextEditingController _shiftNameController = TextEditingController();
  final TextEditingController _cashierController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // TAMBAHAN: Buat Tanggal
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // --- DATA DUMMY SEMENTARA (Ditambahin Tanggal) ---
  final List<Map<String, dynamic>> shiftData = [
    {
      "tanggal": "17 Apr 2026",
      "nama_shift": "Shift Pagi",
      "kasir": "NaWa",
      "jam_mulai": "08:00",
      "jam_selesai": "16:00",
      "status": "Selesai",
    },
    {
      "tanggal": "17 Apr 2026",
      "nama_shift": "Shift Sore",
      "kasir": "Budi",
      "jam_mulai": "16:00",
      "jam_selesai": "00:00",
      "status": "Aktif",
    },
    {
      "tanggal": "18 Apr 2026",
      "nama_shift": "Shift Pagi",
      "kasir": "Siti",
      "jam_mulai": "08:00",
      "jam_selesai": "16:00",
      "status": "Belum Mulai",
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case "Aktif":
        return PastelColors.emerald;
      case "Selesai":
        return Colors.grey;
      case "Belum Mulai":
        return PastelColors.sage;
      default:
        return Colors.grey;
    }
  }

  // --- FUNGSI SHARE JADWAL KE WA ---
  void _shareSchedule() {
    if (shiftData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Belum ada jadwal untuk dibagikan", style: TextStyle(color: Colors.white)), backgroundColor: PastelColors.rose));
      return;
    }

    // Urutkan jadwal biar rapi (opsional)
    String textBagikan = "*📅 JADWAL SHIFT KASIR PRESTO 📅*\n\n";
    
    for (var shift in shiftData) {
      textBagikan += "🗓️ *Tanggal:* ${shift['tanggal']}\n";
      textBagikan += "⏰ *Shift:* ${shift['nama_shift']} (${shift['jam_mulai']} - ${shift['jam_selesai']})\n";
      textBagikan += "👤 *Kasir:* ${shift['kasir']}\n";
      textBagikan += "--------------------------------\n";
    }
    
    textBagikan += "\n_Mohon hadir 15 menit sebelum shift dimulai. Terima kasih!_";

    // Panggil fungsi share ke HP
    Share.share(textBagikan);
  }

  // --- FUNGSI PILIH TANGGAL (CALENDAR) ---
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: PastelColors.emerald, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  // --- FUNGSI MUNCULIN POPUP FORM TAMBAH JADWAL ---
  void _showAddShiftSheet() {
    _shiftNameController.clear(); 
    _cashierController.clear(); 
    _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now()); // Default hari ini
    _startTimeController.clear(); 
    _endTimeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShiftFormContainer(isEdit: false),
    );
  }

  // --- FUNGSI MUNCULIN POPUP FORM EDIT JADWAL ---
  void _showEditShiftSheet(int index, Map<String, dynamic> existingShift) {
    _shiftNameController.text = existingShift['nama_shift'];
    _cashierController.text = existingShift['kasir'];
    _dateController.text = existingShift['tanggal'];
    _startTimeController.text = existingShift['jam_mulai'];
    _endTimeController.text = existingShift['jam_selesai'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShiftFormContainer(isEdit: true, index: index),
    );
  }

  // --- FUNGSI HAPUS JADWAL ---
  void _deleteShift(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Jadwal?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin menghapus jadwal shift ini? Data yang dihapus tidak bisa dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PastelColors.rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() {
                shiftData.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal berhasil dihapus"), backgroundColor: PastelColors.rose));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- UI FORM (DIPAKAI BARENGAN OLEH ADD & EDIT) ---
  Widget _buildShiftFormContainer({required bool isEdit, int? index}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(isEdit ? "Edit Jadwal Shift" : "Buat Jadwal Shift", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Kolom Tanggal (Ditambahin)
            TextField(
              controller: _dateController,
              readOnly: true, // Biar kalender yang muncul, bukan keyboard
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                labelText: "Tanggal Shift", 
                prefixIcon: const Icon(Icons.calendar_month, color: PastelColors.emerald),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(_shiftNameController, "Nama Shift (Cth: Pagi)", Icons.work_outline),
            const SizedBox(height: 16),
            _buildTextField(_cashierController, "Nama Kasir", Icons.person_outline),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_startTimeController, "Jam Mulai (08:00)", Icons.access_time)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_endTimeController, "Jam Selesai (16:00)", Icons.access_time_filled)),
              ],
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: PastelColors.emerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  if (_shiftNameController.text.isEmpty || _cashierController.text.isEmpty) return;
                  
                  setState(() {
                    if (isEdit && index != null) {
                      shiftData[index] = {
                        "tanggal": _dateController.text,
                        "nama_shift": _shiftNameController.text,
                        "kasir": _cashierController.text,
                        "jam_mulai": _startTimeController.text.isNotEmpty ? _startTimeController.text : "00:00",
                        "jam_selesai": _endTimeController.text.isNotEmpty ? _endTimeController.text : "00:00",
                        "status": shiftData[index]['status'], 
                      };
                    } else {
                      shiftData.add({
                        "tanggal": _dateController.text,
                        "nama_shift": _shiftNameController.text,
                        "kasir": _cashierController.text,
                        "jam_mulai": _startTimeController.text.isNotEmpty ? _startTimeController.text : "00:00",
                        "jam_selesai": _endTimeController.text.isNotEmpty ? _endTimeController.text : "00:00",
                        "status": "Belum Mulai",
                      });
                    }
                  });
                  
                  Navigator.pop(context);
                },
                child: Text(isEdit ? "Simpan Perubahan" : "Simpan Jadwal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, color: PastelColors.emerald),
        filled: true, 
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelColors.mint,
      drawer: const SizedBox(width: 260, child: FullAdminDrawer(activeMenu: "Manage Shifts")),
      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Manage Shifts", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          // TOMBOL SHARE KE WA
          IconButton(
            icon: const Icon(Icons.share, color: PastelColors.emerald),
            onPressed: _shareSchedule,
            tooltip: "Bagikan Jadwal",
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PastelColors.emerald,
        onPressed: _showAddShiftSheet, 
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Buat Jadwal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: PastelColors.emerald))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PastelColors.emerald,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manajemen Jadwal Shift", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Pantau, atur, dan bagikan jadwal kerja kasir Anda.", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: shiftData.isEmpty
                      ? const Center(child: Text("Belum ada jadwal shift.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: shiftData.length,
                          itemBuilder: (context, index) {
                            final shift = shiftData[index];
                            final statusColor = _getStatusColor(shift['status']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // ICON WAKTU
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.schedule, color: statusColor, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // DETAIL SHIFT (Ditambahin Tanggal)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(shift['nama_shift'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: PastelColors.emerald),
                                            const SizedBox(width: 4),
                                            Text("${shift['tanggal']}", style: const TextStyle(color: PastelColors.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text("Kasir: ${shift['kasir']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text("${shift['jam_mulai']} - ${shift['jam_selesai']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // KOLOM KANAN: STATUS BADGE & TOMBOL MENU
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditShiftSheet(index, shift);
                                          } else if (value == 'hapus') {
                                            _deleteShift(index);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.grey), SizedBox(width: 8), Text("Edit")]),
                                          ),
                                          const PopupMenuItem(
                                            value: 'hapus',
                                            child: Row(children: [Icon(Icons.delete, size: 18, color: PastelColors.rose), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: PastelColors.rose))]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          shift['status'],
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ==========================================
// DRAWER FULL ADMIN TETAP SAMA
// ==========================================
class FullAdminDrawer extends StatelessWidget {
  final String activeMenu;
  const FullAdminDrawer({super.key, required this.activeMenu});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 150, width: double.infinity, padding: const EdgeInsets.only(top: 40, left: 16),
            decoration: const BoxDecoration(color: PastelColors.sage),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.admin_panel_settings, color: PastelColors.sage, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Super Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Owner", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTitle("MAIN MENU"),
                _buildMenuItem(context, Icons.dashboard, "Dashboard", activeMenu == "Dashboard", () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
                }),
                _buildMenuItem(context, Icons.receipt_long, "Sales Report", activeMenu == "Sales Report", () {
                  if (activeMenu != "Sales Report") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesReportScreen()));
                  else Navigator.pop(context);
                }),
                
                _buildMenuTitle("MASTER DATA"),
                _buildMenuItem(context, Icons.inventory_2_outlined, "Manage Products", activeMenu == "Manage Products", () {
                  if (activeMenu != "Manage Products") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageProductScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.category_outlined, "Manage Categories", activeMenu == "Manage Categories", () {
                  if (activeMenu != "Manage Categories") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageCategoryScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.people_outline, "Manage Cashiers", activeMenu == "Manage Cashiers", () {
                  if (activeMenu != "Manage Cashiers") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageCashierScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.payments_outlined, "Payment Methods", activeMenu == "Payment Methods", () {
                  if (activeMenu != "Payment Methods") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagePaymentScreen()));
                  else Navigator.pop(context);
                }),

                _buildMenuTitle("OPERATIONAL"),
                _buildMenuItem(context, Icons.warehouse_outlined, "Manage Stock", activeMenu == "Manage Stock", () {
                  if (activeMenu != "Manage Stock") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageStockScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.local_shipping_outlined, "Purchase / Incoming", activeMenu == "Purchase / Incoming", () {
                  if (activeMenu != "Purchase / Incoming") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PurchaseIncomingScreen()));
                  else Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.schedule, "Manage Shifts", activeMenu == "Manage Shifts", () {
                  if (activeMenu != "Manage Shifts") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManageShiftsScreen()));
                  else Navigator.pop(context);
                }),

                _buildMenuTitle("SYSTEM"),
                _buildMenuItem(context, Icons.history, "Audit Trail", activeMenu == "Audit Trail", () {
                  if (activeMenu != "Audit Trail") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuditTrailScreen()));
                  else Navigator.pop(context);
                }),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: PastelColors.rose),
                  title: const Text("Logout", style: TextStyle(color: PastelColors.rose, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
  );

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: isSelected ? PastelColors.emerald : PastelColors.grey),
    title: Text(title, style: TextStyle(color: isSelected ? PastelColors.emerald : PastelColors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
    selected: isSelected, selectedTileColor: PastelColors.mint.withOpacity(0.3), onTap: onTap,
  );
}