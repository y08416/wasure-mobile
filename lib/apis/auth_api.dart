import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/apis/supabase_client.dart';

class AuthAPI {
  late final SupabaseClient _supabase;

  AuthAPI._();

  static Future<AuthAPI> create() async {
    final instance = AuthAPI._();
    instance._supabase = await SupabaseClientWrapper.instance;
    return instance;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String occupation,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await _supabase.from('User').insert({
        'user_id': res.user!.id,
        'username': username,
        'email': email,
        'occupation': occupation,
      });
    }

    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res;
    } catch (e) {
      print('Supabase sign in error: $e');
      rethrow;
    }
  }
}