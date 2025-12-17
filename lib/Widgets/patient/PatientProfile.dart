import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_house/Widgets/ChangePassword.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final _supabase = Supabase.instance.client;
  String? _avatarUrl;
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('users')
          .select('name, avatar_url') // Chỉ lấy các trường cần thiết từ hồ sơ công khai
          .eq('id', userId)
          .single();

      setState(() {
        _userName = data['name'] ?? 'N/A';
        _avatarUrl = data['avatar_url'];
        // Lấy email từ đối tượng người dùng đã xác thực để đảm bảo chính xác
        _userEmail = _supabase.auth.currentUser!.email ?? 'N/A';
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
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () {
                  context.go('/patient/profile/edit');
                },
              ),
              _buildProfileOption(
                icon: Icons.notifications_outlined,
                title: 'Thông báo',
                onTap: () {
                  context.go('/patient/profile/personalize_notification');
                },
              ),
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
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Trợ giúp & Hỗ trợ',
                onTap: () {},
              ),
              const Divider(height: 40),
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

  Widget _buildProfileHeader() {
    ImageProvider? backgroundImage;
    // Kiểm tra xem URL avatar là một liên kết web hay data URI
    if (_avatarUrl != null) {
      if (_avatarUrl!.startsWith('http')) {
        // Nếu là URL, sử dụng NetworkImage
        backgroundImage = NetworkImage(_avatarUrl!);
      } else if (_avatarUrl!.startsWith('data:image')) {
        // Nếu là data URI, giải mã chuỗi base64
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
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
