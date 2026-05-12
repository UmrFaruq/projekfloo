import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔥 PERBAIKAN IMPORT: MUNDUR 2 LANGKAH BIAR KETEMU FOLDER THEME 🔥
import '../../theme/colors.dart'; 

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController taxNameController = TextEditingController();
  final TextEditingController taxRateController = TextEditingController();
  
  bool isRounding = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('ms_setting').select();

      for (var item in response) {
        if (item['key_name'] == 'tax_name') taxNameController.text = item['key_value'].toString();
        if (item['key_name'] == 'tax_rate') taxRateController.text = item['key_value'].toString();
        if (item['key_name'] == 'is_rounding') isRounding = item['key_value'].toString() == 'true';
      }
      
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error load setting: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (taxNameController.text.trim().isEmpty || taxRateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nama dan Nilai Pajak tidak boleh kosong!"), 
          backgroundColor: AppColors.error, // 🔥 CONST DIHAPUS
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('ms_setting').update({'key_value': taxNameController.text.trim()}).eq('key_name', 'tax_name');
      await supabase.from('ms_setting').update({'key_value': taxRateController.text.trim()}).eq('key_name', 'tax_rate');
      await supabase.from('ms_setting').update({'key_value': isRounding.toString()}).eq('key_name', 'is_rounding');

      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Pengaturan berhasil disimpan!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgLight,
        title: const Text("Pengaturan POS", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primary)) // 🔥 CONST DIHAPUS
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Pengaturan Pajak / Tax", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nama Pajak (Contoh: PPN, PB1, Service Charge)", style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)), // 🔥 CONST DIHAPUS
                    const SizedBox(height: 8),
                    TextField(
                      controller: taxNameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.receipt_long, color: AppColors.primary), // 🔥 CONST DIHAPUS
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text("Persentase Pajak (%)", style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)), // 🔥 CONST DIHAPUS
                    const SizedBox(height: 8),
                    TextField(
                      controller: taxRateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.percent, color: AppColors.primary), // 🔥 CONST DIHAPUS
                        suffixText: "%",
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Sistem Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: SwitchListTile(
                  title: const Text("Aktifkan Pembulatan Rupiah", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  subtitle: const Text("Membulatkan Grand Total ke bawah (kelipatan 100) agar tidak ada kembalian receh/koin.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: isRounding,
                  activeColor: AppColors.primary,
                  onChanged: (bool value) {
                    setState(() {
                      isRounding = value;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isSaving ? null : _saveSettings,
                  icon: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    isSaving ? "Menyimpan..." : "Simpan Pengaturan", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                  ),
                ),
              )
            ],
          ),
    );
  }
}