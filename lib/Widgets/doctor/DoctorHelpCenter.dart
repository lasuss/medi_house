
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class DoctorHelpCenter extends StatelessWidget {
  const DoctorHelpCenter({Key? key}) : super(key: key);

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
            title: 'Làm thế nào để quản lý lịch làm việc?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Bạn có thể cập nhật lịch làm việc trong tab "Lịch trình". Chọn ngày và giờ bạn muốn mở hoặc đóng lịch khám.')),
            ],
          ),
          _buildExpansionTile(
            title: 'Làm sao để xem hồ sơ bệnh nhân?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Khi có lịch hẹn, bạn có thể nhấn vào tên bệnh nhân để xem chi tiết hồ sơ bệnh án và lịch sử khám.')),
            ],
          ),
          _buildExpansionTile(
            title: 'Quy trình kê đơn thuốc như thế nào?',
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Trong chi tiết phiếu khám, chọn nút "Kê đơn", tìm kiếm thuốc từ kho dược và nhập số lượng, liều dùng.')),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Liên hệ hỗ trợ kỹ thuật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          _buildContactTile(
            icon: Icons.phone,
            title: 'Hotline Kỹ thuật',
            subtitle: '1900 6666',
            onTap: () async {
               final Uri launchUri = Uri(
                scheme: 'tel',
                path: '19006666',
              );
              await launchUrl(launchUri);
            },
          ),
          _buildContactTile(
            icon: Icons.email,
            title: 'Email Hỗ trợ',
            subtitle: 'doctor-support@medihouse.com',
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'mailto',
                path: 'doctor-support@medihouse.com',
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
                 context.go('/doctor/profile/help_center/terms');
              }),
          _buildContactTile(
              icon: Icons.privacy_tip,
              title: 'Chính sách bảo mật',
              subtitle: 'Xem chi tiết',
              onTap: () {
                context.go('/doctor/profile/help_center/privacy');
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
