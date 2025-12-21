//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class DoctorNotification extends StatefulWidget {
  const DoctorNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  
  @override
  State<DoctorNotification> createState() => _DoctorNotificationState();
}

class _DoctorNotificationState extends State<DoctorNotification> {
  final _supabase = Supabase.instance.client;
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Lịch hẹn', 'Tin nhắn', 'Hệ thống'];

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

  bool _filterNotification(Map<String, dynamic> notif) {
    if (_selectedFilter == 'Tất cả') return true;
    final type = notif['type'] ?? 'info';
    
    if (_selectedFilter == 'Lịch hẹn') return type == 'appointment';
    if (_selectedFilter == 'Tin nhắn') return type == 'message';
    if (_selectedFilter == 'Hệ thống') return ['system', 'alert', 'info'].contains(type);
    
    return true;
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
  
  IconData _getIcon(String type) {
    switch (type) {
      case 'alert': return FontAwesomeIcons.circleExclamation;
      case 'appointment': return FontAwesomeIcons.calendarCheck;
      case 'message': return FontAwesomeIcons.solidComment; // Message specific
      case 'info': return FontAwesomeIcons.circleInfo;
      case 'system': return FontAwesomeIcons.gear;
      case 'prescription': return FontAwesomeIcons.prescription;
      default: return FontAwesomeIcons.bell;
    }
  }
  
  Color _getIconColor(String type) {
     switch (type) {
      case 'alert': return Colors.red;
      case 'appointment': return Colors.blue;
      case 'message': return Colors.teal;
      case 'info': return Colors.green;
      case 'system': return Colors.grey;
      default: return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey bg
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
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
                        "Thông báo",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: const Text("Đánh dấu đã đọc", style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                   ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              filter,
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
            
            // Notification List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allNotifs = snapshot.data ?? [];
                  final notifications = allNotifs.where(_filterNotification).toList();

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(FontAwesomeIcons.bellSlash, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Không có thông báo ${_selectedFilter != 'Tất cả' ? 'trong mục này' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final bool isRead = notif['is_read'] ?? false;
                      final String type = notif['type'] ?? 'info';
                      final String title = notif['title'] ?? 'Notification';
                      final String body = notif['body'] ?? '';
                      final String time = _timeAgo(notif['created_at']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.blueGrey.withOpacity(0.1)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _markAsRead(notif['id']);
                            // Navigation logic
                            if (type == 'appointment') {
                               context.go('/doctor/schedule'); // Or logic to switch tab
                            } else if (type == 'message') {
                               context.go('/doctor/messages');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                     CircleAvatar(
                                       radius: 24,
                                       backgroundColor: isRead ? Colors.grey[100] : _getIconColor(type).withOpacity(0.1),
                                       child: FaIcon(
                                         _getIcon(type), 
                                         color: isRead ? Colors.grey : _getIconColor(type), 
                                         size: 20
                                       ),
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
                                const SizedBox(width: 16),
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
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                fontSize: 16,
                                                color: isRead ? Colors.black87 : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          color: isRead ? Colors.grey[600] : Colors.black87,
                                          height: 1.3
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
