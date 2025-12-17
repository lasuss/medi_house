import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_house/Widgets/patient/PatientScanNationalID.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientEditProfile extends StatefulWidget {
  const PatientEditProfile({Key? key}) : super(key: key);

  @override
  State<PatientEditProfile> createState() => _PatientEditProfileState();
}

class _PatientEditProfileState extends State<PatientEditProfile> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController(); // Reverted to controller
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = UserManager.instance.supabaseUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _idController.text = data['national_id'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _genderController.text = data['gender'] ?? ''; // Direct assignment
          _avatarUrl = data['avatar_url'] ?? '';
          _emailController.text = data['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatar() async {
    final imagePicker = ImagePicker();
    final imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (imageFile == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      
      final userId = UserManager.instance.supabaseUser?.id;
      if (userId == null) return;

      final fileName = '$userId/avatar.$fileExt';
      
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      final imageUrlResponse = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      
      setState(() {
        _avatarUrl = imageUrlResponse;
        _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Lỗi tải lên avatar: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (_avatarUrl!.startsWith('http')) {
        return NetworkImage(_avatarUrl!);
      }
    }
    return null;
  }

  Future<void> _handleScanCCCD() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientScanNationalID()),
    );

    // If result is true, it means scan was successful and data saved to DB
    if (result == true) {
      await _fetchUserData(); // Reload data from DB
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin từ CCCD!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarImage = _getAvatarImage();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        actions: [
          IconButton(
            onPressed: _handleScanCCCD,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét CCCD',
            color: Colors.blue,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar section
              Center(
                child: GestureDetector(
                  onTap: _uploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Helper text for scanning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Các thông tin định danh (Tên, CCCD, Ngày sinh, Địa chỉ, Giới tính) được tự động điền từ QR CCCD và không thể sửa thủ công.',
                        style: TextStyle(color: Colors.orange[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Thông tin cá nhân (Từ CCCD)'),
              const SizedBox(height: 12),
              _buildTextField('Họ và tên', _nameController, icon: Icons.person_outline, readOnly: true),
              const SizedBox(height: 16),
              _buildTextField('Số điện thoại', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Địa chỉ', _addressController, icon: Icons.location_on_outlined, maxLines: 2, readOnly: true),

              const SizedBox(height: 24),
              _buildSectionTitle('Thông tin định danh'),
              const SizedBox(height: 12),
              
              _buildTextField('Số CCCD', _idController, icon: Icons.credit_card, readOnly: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Ngày sinh', _dobController, icon: Icons.calendar_today, readOnly: true)),
                  const SizedBox(width: 16),
                   // Gender is now a read-only text file
                  Expanded(child: _buildTextField('Giới tính', _genderController, icon: Icons.people_outline, readOnly: true)),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        final userId = UserManager.instance.supabaseUser?.id;
                        if (userId != null) {
                           await Supabase.instance.client.from('users').update({
                             // All fields are sent, though some are read-only in UI
                             'name': _nameController.text,
                             'phone': _phoneController.text,
                             'address': _addressController.text,
                             'national_id': _idController.text,
                             'dob': _dobController.text,
                             'gender': _genderController.text, // Use controller text
                             'avatar_url': _avatarUrl,
                           }).eq('id', userId);
                           
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Đã cập nhật thông tin thành công!')),
                             );
                             Navigator.of(context).pop();
                           }
                        }
                      } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Lỗi khi lưu: $e')),
                           );
                           setState(() => _isLoading = false);
                         }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182CE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    IconData? icon, 
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 10), // Keep user's font size choice
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 20) : null,
        suffixIcon: readOnly ? const Icon(Icons.lock, size: 16, color: Colors.grey) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: readOnly ? Colors.grey.withOpacity(0.2) : const Color(0xFF3182CE)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          // Optional
        }
        return null;
      },
    );
  }
}
