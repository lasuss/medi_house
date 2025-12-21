
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
  String _selectedFilter = 'Phiếu khám'; // Default to first tab matches image better or "Tất cả"

  final List<String> _filters = ['Phiếu khám', 'Tin tức', 'Thông báo', 'Tin nhắn'];

  // Stream for notifications (mapped to 3 tabs)
  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id) 
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => json).toList());
  }

  // Stream for News (mapped to 'Tin tức' tab)
  Stream<List<Map<String, dynamic>>> _getNewsStream() {
    return _supabase
        .from('news')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => json).toList());
  }

  Future<void> _markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && _selectedFilter != 'Tin tức') {
       // Only mark visible types? Or just all? 
       // User asked for "Mark as read", usually implies notifications.
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

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'prescription':
      case 'record': // Added record type
        return Icons.medication_liquid; // Or description
      case 'message':
        return Icons.chat_bubble_outline; // Changed to chat bubble
      case 'news':
        return Icons.newspaper;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  bool _filterNotification(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'info';
    
    // Logic:
    // Phiếu khám -> record, prescription
    // Thông báo -> info, appointment, admin, system
    // Tin nhắn -> message
    
    if (_selectedFilter == 'Phiếu khám') {
      return type == 'record' || type == 'prescription';
    }
    if (_selectedFilter == 'Thông báo') {
      return type == 'info' || type == 'appointment' || type == 'admin' || type == 'system';
    }
    if (_selectedFilter == 'Tin nhắn') {
      return type == 'message';
    }
    
    return true; // Should not happen if tabs are strict, or maybe "Tất cả"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                       if (_selectedFilter != 'Tin tức') // Hide for News
                         TextButton(
                          onPressed: _markAllAsRead,
                          child: const Text("Đánh dấu đã đọc", style: TextStyle(color: Colors.blue)),
                        ),
                    ],
                   ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        // Mock counts for UI visualization
                        int count = 0;
                        // In a real app we would stream these counts separately
                        if (filter == 'Phiếu khám') count = 3; 
                        if (filter == 'Tin tức') count = 4; // Approx
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
            
            // Content Body
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
          
          if (type == 'appointment' && data.containsKey('appointment_id')) {
             context.push('/patient/appointments'); 
          } else if ((type == 'prescription' || type == 'record') && (data.containsKey('prescription_id') || data.containsKey('record_id'))) {
             // Navigate to profile details or specific record detail
             // For now profile is safe, but ideally deep link to record
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
