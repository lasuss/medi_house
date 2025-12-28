import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medi_house/Widgets/patient/PatientAddProfile.dart';
import 'package:medi_house/Widgets/patient/PatientProfileDetail.dart';

// Widget chính hiển thị danh sách hồ sơ bệnh nhân của người dùng
class PatientProfiles extends StatefulWidget {
  const PatientProfiles({Key? key}) : super(key: key);

  @override
  State<PatientProfiles> createState() => _PatientProfilesState();
}

// Trạng thái quản lý danh sách hồ sơ bệnh nhân
class _PatientProfilesState extends State<PatientProfiles> {
  // Client Supabase
  final SupabaseClient supabase = Supabase.instance.client;
  // Trạng thái loading và danh sách hồ sơ
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];

  @override
  // Khởi tạo trạng thái: lấy danh sách hồ sơ khi mở màn hình
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  // Lấy danh sách hồ sơ bệnh nhân thuộc người dùng hiện tại từ bảng patient_profiles
  Future<void> _fetchProfiles() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _profiles = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hồ sơ: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Mở màn hình thêm hồ sơ mới (giới hạn tối đa 5 hồ sơ)
  Future<void> _addProfile() async {
    if (_profiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chỉ được tạo tối đa 5 hồ sơ.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientAddProfile()),
    );

    if (result == true) {
      _fetchProfiles();
    }
  }

  // Xác nhận và xóa một hồ sơ bệnh nhân
  Future<void> _deleteProfile(String profileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hồ sơ?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('patient_profiles').delete().eq('id', profileId);
        _fetchProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa hồ sơ')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
        }
      }
    }
  }

  @override
  // Xây dựng giao diện danh sách hồ sơ bệnh nhân
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
      // Trạng thái chưa có hồ sơ nào
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chưa có hồ sơ nào.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addProfile, child: const Text('Tạo hồ sơ ngay')),
          ],
        ),
      )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Mỗi tài khoản được tạo tối đa 5 hồ sơ thành viên.",
                            style: TextStyle(color: Colors.blue[900], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
          final profile = _profiles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              // Avatar với chữ cái đầu của tên
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(profile['full_name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              // Tên đầy đủ
              title: Text(profile['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              // Giới tính và ngày sinh
              subtitle: Text("Giới tính: ${profile['gender']} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(profile['dob']))}"),
              // Nút xóa hồ sơ
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteProfile(profile['id']),
              ),
              // Tap để xem chi tiết hồ sơ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientProfileDetail(profile: profile),
                  ),
                );
              },
            ),
          );
        },
                  ),
                ),
              ],
            ),
      // Nút nổi để thêm hồ sơ mới (Đã làm nổi bật)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tạo Hồ Sơ Mới', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}