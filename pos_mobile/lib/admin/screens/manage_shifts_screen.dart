import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Wajib buat fitur Share ke Grup WA

// --- IMPORT PATH (Sesuaikan dengan folder proyek abang) ---
import '../../theme/colors.dart'; // MENGGUNAKAN AppColors
import 'admin_drawer.dart'; // IMPORT DRAWER SENTRAL

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
        return AppColors.primary; // Toska
      case "Selesai":
        return AppColors.textGrey; // Abu-abu
      case "Belum Mulai":
        return AppColors.warning; // Kuning/Warning
      default:
        return AppColors.textGrey;
    }
  }

  // --- FUNGSI SHARE JADWAL KE WA ---
  void _shareSchedule() {
    if (shiftData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Belum ada jadwal untuk dibagikan", style: TextStyle(color: Colors.white)), 
          backgroundColor: AppColors.error // Merah
        )
      );
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Toska
              onPrimary: Colors.white, 
              onSurface: Colors.black87
            ),
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
        title: const Text("Hapus Jadwal?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: const Text("Apakah Anda yakin ingin menghapus jadwal shift ini? Data yang dihapus tidak bisa dikembalikan.", style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, // Merah
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              setState(() {
                shiftData.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal berhasil dihapus"), backgroundColor: AppColors.error)); // Merah
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
            Text(isEdit ? "Edit Jadwal Shift" : "Buat Jadwal Shift", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), // Judul hitam
            const SizedBox(height: 24),
            
            // Kolom Tanggal (Ditambahin)
            TextField(
              controller: _dateController,
              readOnly: true, // Biar kalender yang muncul, bukan keyboard
              onTap: () => _selectDate(context),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
              decoration: InputDecoration(
                labelText: "Tanggal Shift", 
                labelStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primary), // Icon toska
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Toska
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
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
                child: Text(isEdit ? "Simpan Perubahan" : "Simpan Jadwal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
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
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), // Teks input hitam
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIcon: Icon(icon, color: AppColors.primary), // Icon toska
        filled: true, 
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, // Background toska muda
      // --- PAKAI DRAWER SENTRAL ---
      drawer: const SizedBox(
        width: 260, 
        child: AdminDrawer(activeMenu: "Manage Shifts")
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // Icon back hitam
        title: const Text("Manage Shifts", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          // TOMBOL SHARE KE WA
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary), // Icon toska
            onPressed: _shareSchedule,
            tooltip: "Bagikan Jadwal",
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary, // Toska
        onPressed: _showAddShiftSheet, 
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Buat Jadwal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary, // Kotak header toska solid
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
                      ? const Center(child: Text("Belum ada jadwal shift.", style: TextStyle(color: AppColors.textGrey)))
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
                                        Text(shift['nama_shift'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), // Teks hitam
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary), // Toska
                                            const SizedBox(width: 4),
                                            Text("${shift['tanggal']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)), // Toska
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 14, color: AppColors.textGrey),
                                            const SizedBox(width: 4),
                                            Text("Kasir: ${shift['kasir']}", style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)), // Nama kasir lebih jelas
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
                                            const SizedBox(width: 4),
                                            Text("${shift['jam_mulai']} - ${shift['jam_selesai']}", style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
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
                                        icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
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
                                            child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.black87), SizedBox(width: 8), Text("Edit", style: TextStyle(color: Colors.black87))]),
                                          ),
                                          const PopupMenuItem(
                                            value: 'hapus',
                                            child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))]), // Merah
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