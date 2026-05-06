import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  late SupabaseClient _client;
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  SupabaseClient get client => _client;
  
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
      print('✅ Supabase berhasil nyambung bosku!');
    } catch (e) {
      print('❌ Error Supabase: $e');
      rethrow;
    }
  }
}

final supabaseService = SupabaseService();