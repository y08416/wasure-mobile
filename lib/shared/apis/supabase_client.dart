import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientWrapper {
  static SupabaseClient? _client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      _client = Supabase.instance.client;
      _initialized = true;
    }
  }

  static Future<SupabaseClient> get instance async {
    if (!_initialized) {
      await initialize();
    }
    return _client!;
  }
}