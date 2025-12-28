
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  UserRole _selectedRole = UserRole.patient; // Mặc định chọn Bệnh nhân

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        try {
          final userData = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', res.user!.id)
              .maybeSingle();

          if (userData == null) {
             throw 'Không tìm thấy thông tin người dùng.';
          }

          final role = userData['role'] as String?;
          
          if (mounted && role != null) {
            await UserManager.instance.saveUserRole(role);
            await UserManager.instance.loadUser();

            if ((role == 'patient') && (_selectedRole == UserRole.patient))  {
              context.go('/patient/dashboard');
            } else if (role == 'doctor' && _selectedRole == UserRole.doctor) {
              context.go('/doctor/dashboard');
            } else if (role == 'pharmacy' && _selectedRole == UserRole.pharmacy) {
              context.go('/pharmacy/pending');
            } else if (role == 'admin') {
              context.go('/admin/dashboard');
            } else if (role == 'receptionist') {
              context.go('/receptionist/dashboard');
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sai tài khoản/Mật khẩu. Vui lòng thử lại!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
             throw 'Tài khoản chưa được phân quyền. Vui lòng liên hệ Admin.';
          }
        } catch (dbError) {
           throw 'Lỗi hệ thống khi lấy thông tin người dùng: $dbError';
        }
      } else {
        throw 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng quên mật khẩu đang phát triển'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleRegister() {
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 40),
                const SizedBox(height: 8),
                Text(
                  'MediHouse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                  const Text(
                    'Chào Mừng Trở Lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục sử dụng dịch vụ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Địa chỉ Email', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'email@gmail.com',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mật khẩu', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: _handleForgotPassword,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu của bạn',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Bạn là:', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildRoleButton(UserRole.patient, 'Bệnh nhân', FontAwesomeIcons.user)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildRoleButton(UserRole.doctor, 'Bác sĩ', FontAwesomeIcons.userDoctor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildRoleButton(UserRole.pharmacy, 'Nhà thuốc', FontAwesomeIcons.houseMedical)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildRoleButton(UserRole.receptionist, 'Lễ tân', FontAwesomeIcons.conciergeBell)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đăng Nhập',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Chưa có tài khoản? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: _handleRegister,
                      child: const Text(
                        'Đăng Ký Ngay',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(UserRole role, String text, IconData icon) {
    final isSelected = _selectedRole == role;
    return OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _selectedRole = role;
          });
        },
        icon: FaIcon(icon, color: isSelected ? Colors.white : Colors.blue, size: 18),
        label: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.blue[800])),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          side: BorderSide(color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }
}

