import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _validatePasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _validatePasswordController.dispose();
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Giả lập đăng nhập thành công
    context.go('/login');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công')));
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon/Logo với Font Awesome
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.userLock,
                  size: 30,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Chào mừng bạn trở lại!',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // TextField Tài khoản
              TextField(
                controller: _accountController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Tài khoản',
                  hintText: 'Tên đăng nhập',
                  labelStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 10),

              // TextField Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  labelStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: FaIcon(
                      FontAwesomeIcons.lock,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: FaIcon(
                        _isPasswordVisible
                            ? FontAwesomeIcons.eye
                            : FontAwesomeIcons.eyeSlash,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 10),

              // TextField Mật khẩu NHẬP LẠI
              TextField(
                controller: _validatePasswordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu ',
                  hintText: 'Nhập mật khẩu',
                  labelStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: FaIcon(
                      FontAwesomeIcons.lock,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: FaIcon(
                        _isPasswordVisible
                            ? FontAwesomeIcons.eye
                            : FontAwesomeIcons.eyeSlash,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 10),

              // TextField Họ và Tên
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Họ và Tên',
                  hintText: 'Nhập họ và tên sinh viên',
                  labelStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 10),

              // TextField Lớp
              TextField(
                controller: _classController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Lớp',
                  hintText: 'Lớp sinh viên',
                  labelStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 10),

              // Button Đăng KÝ
              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Colors.green.shade200,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text(
                  'Đăng KÝ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              // Đã có tài khoản --> đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  TextButton(
                    onPressed: _handleLogin,
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
