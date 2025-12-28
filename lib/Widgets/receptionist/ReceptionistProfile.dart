import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceptionistProfile extends StatelessWidget {
  const ReceptionistProfile({Key? key}) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    UserManager().clearUser();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Có thể lấy thêm thông tin user ở đây nếu cần, hoặc chỉ hiện thông tin cơ bản
    final user = Supabase.instance.client.auth.currentUser;
    // user?.email might be available.

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                 radius: 50,
                 backgroundColor: Colors.blue,
                 child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                user?.email ?? 'Receptionist',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vai trò: Lễ Tân (Receptionist)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Đăng Xuất", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
