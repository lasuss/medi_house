import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_house/Widgets/ChangePassword.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:medi_house/Widgets/doctor/DoctorNotification.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  final _supabase = Supabase.instance.client;
  String? _avatarUrl;
  String _userName = '';
  String _userSpecialty = '';
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
      final userData = await _supabase
          .from('users')
          .select('name, avatar_url')
          .eq('id', userId)
          .single();

      final doctorData = await _supabase
          .from('doctor_info')
          .select('specialty')
          .eq('user_id', userId)
          .single();

      setState(() {
        _userName = userData['name'] ?? 'N/A';
        _avatarUrl = userData['avatar_url'];
        _userSpecialty = doctorData['specialty'] ?? 'General Practitioner';
      });
    } catch (e) {
      debugPrint('Lỗi khi tải hồ sơ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải hồ sơ: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
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
          SnackBar(
            content: Text('Lỗi tải lên avatar: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3182CE)))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header with Profile Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userSpecialty,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSectionHeader('Account Settings'),
                  _buildSettingsItem(
                    Icons.person_outline,
                    'Chỉnh sửa hồ sơ cá nhân',
                        () {
                      context.go('/doctor/profile/edit');
                    },
                  ),
                  _buildSettingsItem(
                    Icons.lock_outline,
                    'Đổi mật khẩu',
                        () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const ChangePasswordDialog();
                        },
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.notifications_none,
                    'Thông báo',
                        () {
                      context.go('/doctor/notifications');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('General'),
                  _buildSettingsItem(
                    Icons.privacy_tip_outlined,
                    'Chính sách bảo mật',
                        () {},
                  ),
                  _buildSettingsItem(
                    Icons.help_outline,
                    'Trợ giúp & Hỗ trợ',
                        () {},
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsItem(
                    Icons.logout,
                    'Đăng xuất',
                    _signOut,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

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

    return GestureDetector(
      onTap: _uploadAvatar,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? const FaIcon(FontAwesomeIcons.userDoctor, size: 50, color: Color(0xFFCBD5E0))
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF3182CE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color textColor = const Color(0xFF2D3748),
        Color iconColor = const Color(0xFF4A5568),
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}