
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHelpCenter extends StatelessWidget {
  const PatientHelpCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Dark text/icons for white app bar
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Câu hỏi thường gặp',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          _buildExpansionTile(
            title: 'Làm thế nào để đặt lịch khám?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Bạn có thể đặt lịch khám bằng cách chọn bác sĩ và thời gian phù hợp trên trang chủ hoặc tìm kiếm bác sĩ theo chuyên khoa.')),
            ],
          ),
          _buildExpansionTile(
            title: 'Làm sao để đổi mật khẩu?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Vào mục Tài khoản > Đổi mật khẩu để cập nhật mật khẩu mới.')),
            ],
          ),
          _buildExpansionTile(
            title: 'Tôi có thể hủy lịch khám không?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Có, bạn có thể hủy lịch khám trong phần Lịch hẹn của tôi trước giờ khám ít nhất 2 giờ.')),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Liên hệ hỗ trợ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          _buildContactTile(
            icon: Icons.phone,
            title: 'Hotline',
            subtitle: '1900 1234',
            onTap: () async {
               final Uri launchUri = Uri(
                scheme: 'tel',
                path: '1900 1234',
              );
              await launchUrl(launchUri);
            },
          ),
          _buildContactTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'support@medihouse.com',
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'mailto',
                path: 'support@medihouse.com',
              );
              await launchUrl(launchUri);
            },
          ),
          const SizedBox(height: 20),
           const Text(
            'Thông tin pháp lý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          _buildContactTile(
              icon: Icons.description,
              title: 'Điều khoản sử dụng',
              subtitle: 'Xem chi tiết',
              onTap: () {
                 context.go('/patient/profile/help_center/terms');
              }),
          _buildContactTile(
              icon: Icons.privacy_tip,
              title: 'Chính sách bảo mật',
              subtitle: 'Xem chi tiết',
              onTap: () {
                context.go('/patient/profile/help_center/privacy');
              }),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.grey[50], // Light grey background
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        children: children,
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
