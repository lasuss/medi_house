import 'package:medi_house/enroll/UserRole.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();

  factory UserManager() {
    return _instance;
  }

  UserManager._internal();

  static UserManager get instance => _instance;

  User? _supabaseUser;
  UserRole? _role;
  Map<String, dynamic>? _profileData;

  User? get supabaseUser => _supabaseUser;
  UserRole? get role => _role;
  Map<String, dynamic>? get profileData => _profileData;

  bool get isLoggedIn => _supabaseUser != null;

  /// Tải dữ liệu người dùng từ Supabase và SharedPreferences
  Future<void> loadUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    _supabaseUser = session?.user;

    if (_supabaseUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString('user_role');

      if (roleString != null) {
        _role = UserRole.fromString(roleString);
      } else {
        await _fetchAndSaveRole();
      }
    } else {
      _role = null;
    }
  }

  /// Lấy thông tin vai trò từ Supabase và lưu vào SharedPreferences.
  Future<void> _fetchAndSaveRole() async {
    if (_supabaseUser == null) return;

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', _supabaseUser!.id)
          .single();

      final roleStr = userData['role'] as String?;
      if (roleStr != null) {
        _role = UserRole.fromString(roleStr);
        await saveUserRole(roleStr);
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  /// Lưu vai trò vào SharedPreferences
  Future<void> saveUserRole(String roleStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', roleStr);
    _role = UserRole.fromString(roleStr);
  }

  /// Xóa dữ liệu người dùng khi đăng xuất.
  Future<void> clearUser() async {
    _supabaseUser = null;
    _role = null;
    _profileData = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    
    await Supabase.instance.client.auth.signOut();
  }
}
