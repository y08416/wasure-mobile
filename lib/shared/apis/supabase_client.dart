import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static SupabaseClient? _client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await Supabase.initialize(
        url: 'https://eeqflvnhxyfwqelztheu.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlcWZsdm5oeHlmd3FlbHp0aGV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYxNDUyNzEsImV4cCI6MjA0MTcyMTI3MX0.k9cjeI55i9ajRCwbvJWxcNzLo2Pfy2VamkHXwRQdHss',
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