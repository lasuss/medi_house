import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Hàm đổi mật khẩu với logic xác thực mật khẩu cũ.
  Future<void> _changePassword() async {
    // Sử dụng context từ build method, lúc này đã có Scaffold.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_newPasswordController.text != _confirmPasswordController.text) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới không khớp.')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 6 ký tự.')),
      );
      return;
    }

    final newPassword = _newPasswordController.text;
    final oldPassword = _oldPasswordController.text;
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Không tìm thấy người dùng. Vui lòng đăng nhập lại.')),
      );
      return;
    }

    try {
      // Thử đăng nhập lại với mật khẩu cũ để xác thực.
      await supabase.auth.signInWithPassword(
        email: currentUser.email!,
        password: oldPassword,
      );

      // Nếu thành công, cập nhật mật khẩu mới.
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại')),
        );
        await UserManager().clearUser();
        context.go('/login');
      }
    } on AuthException catch (e) {
      // Bắt lỗi, ví dụ như sai mật khẩu cũ.
        String errorMessage = 'Lỗi: ${e.message}';
        if (e.message.toLowerCase().contains('invalid login credentials')){
            errorMessage = 'Mật khẩu hiện tại không đúng.';
        }
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(errorMessage)),
        );
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trả về một Dialog chứa Scaffold để SnackBar hoạt động.
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        // Scaffold cung cấp context cần thiết cho SnackBar.
        child: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề của Dialog
                  const Text(
                    'Thay đổi mật khẩu',
                    style: TextStyle(color: Color(0xff2196F3), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Các trường nhập liệu
                  _buildTextField(_oldPasswordController, 'Mật khẩu hiện tại'),
                  const SizedBox(height: 16),
                  _buildTextField(_newPasswordController, 'Mật khẩu mới'),
                  const SizedBox(height: 16),
                  _buildTextField(_confirmPasswordController, 'Xác nhận mật khẩu mới'),
                ],
              ),
            ),
            // Các nút hành động được đặt ở bottomNavigationBar của Scaffold nội bộ.
            bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            TextButton(
                                onPressed: () {
                                    Navigator.of(context).pop(); // Đóng dialog hiện tại
                                    context.push('/forgot_password'); // Điều hướng tới trang quên mật khẩu
                                },
                                child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xff2196F3))),
                            ),
                        ],
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                    ),
                                ),
                                onPressed: _changePassword,
                                child: const Text('Xác nhận')
                            ),
                        ],
                    )
                ],
            ),
        ),
      ),
    );
  }

  // Widget helper để code gọn hơn
  Widget _buildTextField(TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hintText, style: const TextStyle(color: Color(0xff2196F3), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
