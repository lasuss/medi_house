import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Widget chính hiển thị màn hình thông báo của bệnh nhân
class PatientNotification extends StatefulWidget {
  const PatientNotification({Key? key}) : super(key: key);

  @override
  State<PatientNotification> createState() => _PatientNotificationState();
}

// Trạng thái quản lý danh sách thông báo và tin tức
class _PatientNotificationState extends State<PatientNotification> {
  // Client Supabase
  final _supabase = Supabase.instance.client;
  // Bộ lọc hiện tại (tab đang chọn)
  String _selectedFilter = 'Phiếu khám';

  // Danh sách các tab bộ lọc
  final List<String> _filters = ['Phiếu khám', 'Tin tức', 'Thông báo', 'Tin nhắn'];

  // Stream lấy danh sách thông báo cá nhân của người dùng hiện tại
  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => json).toList());
  }

  // Stream lấy danh sách tin tức chung
  Stream<List<Map<String, dynamic>>> _getNewsStream() {
    return _supabase
        .from('news')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => json).toList());
  }

  // Đánh dấu một thông báo cụ thể là đã đọc
  Future<void> _markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // Đánh dấu tất cả thông báo chưa đọc của người dùng là đã đọc
  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && _selectedFilter != 'Tin tức') {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    }
  }

  // Chuyển đổi thời gian thành định dạng "bao lâu trước" (ví dụ: 2 giờ trước, 3 ngày trước)
  String _timeAgo(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // Trả về icon phù hợp với loại thông báo
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'prescription':
      case 'record':
        return Icons.medication_liquid;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'news':
        return Icons.newspaper;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  // Lọc thông báo theo tab đang chọn
  bool _filterNotification(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'info';

    if (_selectedFilter == 'Phiếu khám') {
      return type == 'record' || type == 'prescription';
    }
    if (_selectedFilter == 'Thông báo') {
      return type == 'info' || type == 'appointment' || type == 'admin' || type == 'system';
    }
    if (_selectedFilter == 'Tin nhắn') {
      return type == 'message';
    }

    return true;
  }

  @override
  // Xây dựng giao diện chính của màn hình thông báo
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Phần header chứa tiêu đề và các tab bộ lọc
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Danh sách thông báo",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      // Nút đánh dấu tất cả đã đọc (ẩn khi đang ở tab Tin tức)
                      if (_selectedFilter != 'Tin tức')
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: const Text("Đánh dấu đã đọc", style: TextStyle(color: Colors.blue)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Các tab bộ lọc (ChoiceChip)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        // Giá trị đếm giả lập để hiển thị (thực tế nên lấy từ stream riêng)
                        int count = 0;
                        if (filter == 'Phiếu khám') count = 3;
                        if (filter == 'Tin tức') count = 4;
                        if (filter == 'Thông báo') count = 2;
                        if (filter == 'Tin nhắn') count = 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              "$filter ($count)",
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Phần nội dung chính: hiển thị tin tức hoặc thông báo tùy tab
            Expanded(
              child: _selectedFilter == 'Tin tức'
                  ? _buildNewsList()
                  : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  // Xây dựng danh sách tin tức từ bảng news
  Widget _buildNewsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getNewsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final newsList = snapshot.data ?? [];
        if (newsList.isEmpty) return _buildEmptyState("Không có tin tức nào");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hình ảnh tin tức nếu có
                  if (news['image_url'] != null)
                    Image.network(
                      news['image_url'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(height: 150, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image))),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(news['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(news['summary'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(_timeAgo(news['created_at']), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Xây dựng danh sách thông báo đã lọc theo tab hiện tại
  Widget _buildNotificationList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allNotifications = snapshot.data ?? [];
        final notifications = allNotifications.where(_filterNotification).toList();

        if (notifications.isEmpty) {
          return _buildEmptyState("Không có thông báo nào");
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
    );
  }

  // Trạng thái rỗng khi không có dữ liệu
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Widget hiển thị một thông báo riêng lẻ với xử lý tap và đánh dấu đã đọc
  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] ?? false;
    final String title = notification['title'] ?? 'Thông báo';
    final String body = notification['body'] ?? '';
    final String time = _timeAgo(notification['created_at']);
    final String type = notification['type'] ?? 'info';
    final Map<String, dynamic> data = notification['data'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          _markAsRead(notification['id']);

          // Điều hướng sâu tùy theo loại thông báo
          if (type == 'appointment' && data.containsKey('appointment_id')) {
            context.push('/patient/appointments');
          } else if ((type == 'prescription' || type == 'record') && (data.containsKey('prescription_id') || data.containsKey('record_id'))) {
            context.push('/patient/profile');
          } else if (type == 'message') {
            context.go('/patient/messages');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon thông báo với badge chưa đọc
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isRead ? Colors.grey[100] : Colors.blue.withOpacity(0.1),
                    child: Icon(_getIconForType(type), color: isRead ? Colors.grey : Colors.blue, size: 24),
                  ),
                  if (!isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 12),
              // Nội dung thông báo (tiêu đề + mô tả + thời gian)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              color: isRead ? Colors.black87 : Colors.black,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(color: isRead ? Colors.grey[600] : Colors.black87, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}