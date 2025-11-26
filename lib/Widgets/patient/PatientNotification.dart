import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientNotification extends StatelessWidget {
  const PatientNotification({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _notifications = const [
    {
      'icon': Icons.system_update,
      'title': 'Cập nhật hệ thống',
      'subtitle': 'Ứng dụng sẽ được bảo trì vào lúc 2 giờ sáng.',
      'time': '1h ago',
      'unread': true,
      'route': null,
    },
    {
      'icon': Icons.new_releases,
      'title': 'Tính năng mới: Đặt lịch trực tuyến',
      'subtitle': 'Giờ đây bạn có thể đặt lịch hẹn dễ dàng hơn.',
      'time': '1d ago',
      'unread': false,
      'route': '/patient/appointments',
    },
    {
      'icon': Icons.lightbulb_outline,
      'title': 'Lời khuyên sức khỏe hàng tuần',
      'subtitle': 'Uống đủ nước mỗi ngày để có một cơ thể khỏe mạnh.',
      'time': '2d ago',
      'unread': false,
      'route': null,
    },
    {
      'icon': Icons.campaign,
      'title': 'Thông báo nghỉ lễ',
      'subtitle': 'Phòng khám sẽ nghỉ lễ từ ngày 30/4 đến hết 1/5.',
      'time': '3d ago',
      'unread': false,
      'route': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Thông báo',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
              onPressed: () {
                // Handle filter tap
              },
            ),
          ],
        ),
        body: _buildNotificationsList(context, _notifications));
  }

  Widget _buildNotificationsList(
      BuildContext context, List<Map<String, dynamic>> notifications) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          // Group by date logic can be added here if needed
          // For simplicity, just showing a list
          return _buildNotificationItem(context, notification);
        });
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        onTap: () {
          if (notification['route'] != null) {
            context.go(notification['route']);
          }
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(notification['icon'], color: Colors.blue),
        ),
        title: Text(
          notification['title'],
          style:
              const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          notification['subtitle'],
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notification['unread'])
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              notification['time'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
