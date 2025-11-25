import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/menus/bottom_navigation.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final _supabase = Supabase.instance.client;
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _avatarUrl = data['avatar_url'];
      });
    } catch (e) {
      // Handle error or if user profile doesn't exist yet
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';
      final filePath = imageFile.path;
      final file = File(filePath);

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get Public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update User Profile
      await _supabase.from('users').update({
        'avatar_url': imageUrl,
      }).eq('id', userId);

      setState(() {
        _avatarUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text(widget.title ?? 'Hồ sơ cá nhân')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _uploadAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading)
              TextButton.icon(
                onPressed: _uploadAvatar,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Đổi ảnh đại diện'),
              ),
            const SizedBox(height: 32),
            const Text('Thông tin bệnh nhân', style: TextStyle(fontSize: 20)),
            // Add more profile fields here
          ],
        ),
      ),
    );
  }
}