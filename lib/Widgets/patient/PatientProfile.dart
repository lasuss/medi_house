import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_house/Widgets/ChangePassword.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';

// Widget chính hiển thị màn hình hồ sơ cá nhân của bệnh nhân
class PatientProfile extends StatefulWidget {
  const PatientProfile({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

// Trạng thái quản lý dữ liệu và giao diện hồ sơ cá nhân
class _PatientProfileState extends State<PatientProfile> {
  // Client Supabase
  final _supabase = Supabase.instance.client;
  // URL avatar, tên và email người dùng
  String? _avatarUrl;
  String _userName = '';
  String _userEmail = '';
  // Trạng thái đang tải dữ liệu
  bool _isLoading = false;

  @override
  // Khởi tạo trạng thái: lấy thông tin hồ sơ khi mở màn hình
  void initState() {
    super.initState();
    _getProfile();
  }

  // Lấy thông tin hồ sơ người dùng từ bảng users và auth
  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('users')
          .select('name, avatar_url')
          .eq('id', userId)
          .single();

      setState(() {
        _userName = data['name'] ?? 'Chưa cập nhật';
        _avatarUrl = data['avatar_url'];
        _userEmail = _supabase.auth.currentUser!.email ?? 'Chưa cập nhật';
      });
    } catch (e) {
      debugPrint('Lỗi khi tải hồ sơ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải hồ sơ: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tải lên avatar mới từ thư viện ảnh và cập nhật vào Supabase Storage + bảng users
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
      final fileName = '${_supabase.auth.currentUser!.id}/avatar.$fileExt';
      await _supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      final imageUrlResponse = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase.from('users').update({'avatar_url': imageUrlResponse}).eq('id', _supabase.auth.currentUser!.id);
      setState(() {
        _avatarUrl = imageUrlResponse;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật avatar thành công!'),
        ));
      }
    } on StorageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lên avatar: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Thực hiện đăng xuất: xóa session Supabase và chuyển về màn hình login
  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      UserManager().clearUser();
      if(mounted) {
        context.go('/login');
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  // Xây dựng giao diện chính của màn hình hồ sơ
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 30),
          // Tùy chọn chỉnh sửa hồ sơ
          _buildProfileOption(
            icon: Icons.person_outline,
            title: 'Chỉnh sửa hồ sơ',
            onTap: () {
              context.go('/patient/profile/edit');
            },
          ),
          // Tùy chọn cá nhân hóa thông báo
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            onTap: () {
              context.go('/patient/profile/personalize_notification');
            },
          ),
          // Tùy chọn đổi mật khẩu
          _buildProfileOption(
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const ChangePasswordDialog();
                  }
              );
            },
          ),
          // Tùy chọn trợ giúp & hỗ trợ
          _buildProfileOption(
            icon: Icons.help_outline,
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () {
              context.go('/patient/profile/help_center');
            },
          ),
          const Divider(height: 40),
          // Tùy chọn đăng xuất
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Đăng xuất',
            isLogout: true,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  // Phần header hiển thị avatar, tên và email người dùng
  Widget _buildProfileHeader() {
    ImageProvider? backgroundImage;
    if (_avatarUrl != null) {
      if (_avatarUrl!.startsWith('http')) {
        backgroundImage = NetworkImage(_avatarUrl!);
      } else if (_avatarUrl!.startsWith('data:image')) {
        try {
          final uri = Uri.parse(_avatarUrl!);
          if (uri.data != null) {
            backgroundImage = MemoryImage(uri.data!.contentAsBytes());
          }
        } catch (e) {
          debugPrint('Lỗi phân tích data URI cho avatar: $e');
          backgroundImage = null;
        }
      }
    }

    return Column(
      children: [
        // Avatar có thể tap để thay đổi
        GestureDetector(
          onTap: _uploadAvatar,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: backgroundImage,
            child: backgroundImage == null
                ? const Icon(Icons.person, size: 50, color: Colors.blue)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userEmail,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Widget một mục tùy chọn trong danh sách (có icon, tiêu đề và hành động tap)
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.red : Colors.grey[800];
    final iconColor = isLogout ? Colors.red : Colors.blue;
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}