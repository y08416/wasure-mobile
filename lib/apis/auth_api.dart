import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/apis/supabase_client.dart';
import '../apis/location_api.dart';

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

      if (res.user != null) {
        try {
          // 位置情報の権限を確認
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              throw Exception('位置情報の権限が拒否されました');
            }
          }
          await LocationAPI.updateLocation();
        } catch (e) {
          print('位置情報の更新に失敗しました: $e');
          // 位置情報の更新に失敗してもログイン処理は継続
        }
      }
      return res;
    } catch (e) {
      print('Supabase sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('サインアウトに成功しました');
    } catch (e) {
      print('サインアウトエラー: $e');
      throw Exception('サインアウトに失敗しました');
    }
  }
}
