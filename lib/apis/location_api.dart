import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationAPI {
  static Future<void> updateLocation() async {
    print('LocationAPI.updateLocation()が呼び出されました');

    // 位置情報サービスが有効か確認
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('位置情報サービスが無効です');
    }

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

    // 現在の位置を取得
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('取得した位置情報: 緯度 ${position.latitude}, 経度 ${position.longitude}');

    // Supabaseクライアントを取得
    final supabase = Supabase.instance.client;

    // 現在のユーザーIDを取得
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // 位置情報をアップデート
    await supabase.from('Location').upsert({
      'user_id': userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
    }, onConflict: 'user_id');

    print('位置情報が更新されました');
  }
}
