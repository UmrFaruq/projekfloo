import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_service.dart';

class AuditService {
  static final SupabaseClient supabase = Supabase.instance.client;

  static Future<void> logActivity({
    required String action,
    required String detail,
    required String type,
    String? userId,
  }) async {
    try {
      // AUTO AMBIL USER LOGIN
      final currentUserId = userId ?? SessionService.userId;

      await supabase.from('audit_trail').insert({
        'user_id': currentUserId,
        'action': action,
        'detail': detail,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Audit trail tersimpan");
    } catch (e) {
      print("❌ Gagal simpan audit trail: $e");
    }
  }
}
