import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  UserRole _selectedRole = UserRole.patient;
  String? _selectedGender;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    context.go('/login');
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không khớp')),
      );
      return;
    }

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': _selectedRole.name, // 'patient', 'doctor', etc.
          'gender': _selectedGender,
          'dob': _dobController.text.trim(),
        },
      );

      if (res.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
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
            content: Text('Lỗi không xác định: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F), // Dark blue background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register a new account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Form Fields
                _buildTextField('Email Address', _emailController, hint: 'you@example.com'),
                const SizedBox(height: 16),
                _buildTextField('Full Name', _nameController, hint: 'Nguyen Van A'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Day Of Birth', _dobController, hint: 'DD/MM/YYYY'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Password', _passwordController, hint: 'Enter your password', isPassword: true),
                const SizedBox(height: 16),
                _buildTextField('Confirm your password', _confirmPasswordController, hint: 'Confirm your password', isPassword: true),
                const SizedBox(height: 24),

                // Role Selection
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

                // Register Button
                ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already had an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: _handleSignIn,
                      child: const Text('Sign In', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String hint = '', bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF172A46),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: const Text('Gender', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF172A46),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF172A46),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          ),
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRoleButton(UserRole role, String text, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _selectedRole = role),
        icon: FaIcon(icon, color: isSelected ? Colors.white : Colors.blue, size: 18),
        label: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : const Color(0xFF172A46),
          side: BorderSide(color: isSelected ? Colors.blue : const Color(0xFF172A46)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
