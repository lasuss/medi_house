
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientNotification extends StatefulWidget {
  const PatientNotification({Key? key}) : super(key: key);

  @override
  State<PatientNotification> createState() => _PatientNotificationState();
}

class _PatientNotificationState extends State<PatientNotification> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => json).toList());
  }

  Future<void> _markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    }
  }

  String _timeAgo(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'prescription':
        return Icons.medication;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

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
            tooltip: 'Đánh dấu tất cả là đã đọc',
            onPressed: () {
              _markAllAsRead();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] ?? false;
    final String title = notification['title'] ?? 'No Title';
    final String body = notification['body'] ?? '';
    final String time = _timeAgo(notification['created_at']);
    final String type = notification['type'] ?? 'info';
    final Map<String, dynamic> data = notification['data'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: isRead ? 1.0 : 3.0,
      color: isRead ? Colors.white : Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isRead ? BorderSide.none : const BorderSide(color: Colors.blue, width: 0.5),
      ),
      child: ListTile(
        onTap: () {
          _markAsRead(notification['id']); // Mark as read on tap
          
          // Handle navigation based on type
          if (type == 'appointment' && data.containsKey('appointment_id')) {
             // context.push('/appointment/${data['appointment_id']}'); // Example route
          } else if (type == 'prescription' && data.containsKey('prescription_id')) {
             // context.push('/prescription/${data['prescription_id']}'); // Example
          }
        },
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey.withOpacity(0.1) : Colors.blue.withOpacity(0.2),
          child: Icon(_getIconForType(type), color: isRead ? Colors.grey : Colors.blue),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isRead ? Colors.black87 : Colors.blue[900],
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
