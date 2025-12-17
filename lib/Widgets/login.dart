
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
  UserRole _selectedRole = UserRole.patient; // State for selected role

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
        // Fetch user role from public.users table
        final userData = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', res.user!.id)
            .single();

        final role = userData['role'] as String?;

        if (mounted && role != null) {
          // Save user role to UserManager and SharedPreferences
          await UserManager.instance.saveUserRole(role);
          await UserManager.instance.loadUser(); // Refresh state

          if ((role == 'patient') && (_selectedRole == UserRole.patient))  {
            context.go('/patient/dashboard');
          } else if (role == 'doctor' && _selectedRole == UserRole.doctor) {
            context.go('/doctor/dashboard');
          } else if (role == 'pharmacy' && _selectedRole == UserRole.pharmacy) {
            context.go('/pharmacy/pending');
          } else if (role == 'admin') {
            context.go('/admin/dashboard');
          } else {
             // Handle role mismatch
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vai trò bạn chọn không đúng với tài khoản.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: $e'),
            backgroundColor: Colors.red,
          ),
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
      backgroundColor: const Color(0xFF0A192F), // Dark blue background
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
                const Text(
                  'MediHouse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log in to continue to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Email Address', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF172A46),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Password', style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF172A46),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
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
                const Text('I am a:', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoleButton(UserRole.patient, 'Patient', FontAwesomeIcons.user),
                    const SizedBox(width: 10),
                    _buildRoleButton(UserRole.doctor, 'Doctor', FontAwesomeIcons.userDoctor),
                    const SizedBox(width: 10),
                    _buildRoleButton(UserRole.pharmacy, 'Pharmacy', FontAwesomeIcons.pills),
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
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: _handleRegister,
                      child: const Text(
                        'Sign Up',
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
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _selectedRole = role;
          });
        },
        icon: FaIcon(icon, color: isSelected ? Colors.white : Colors.blue, size: 18),
        label: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : const Color(0xFF172A46),
          side: BorderSide(color: isSelected ? Colors.blue : const Color(0xFF172A46)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

