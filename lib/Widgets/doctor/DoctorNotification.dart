//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DoctorNotification extends StatefulWidget {
  const DoctorNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorNotification> createState() => _DoctorNotificationState();
}

class _DoctorNotificationState extends State<DoctorNotification> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Appointment Cancelled',
      'body': 'Patient Nguyen Van A has cancelled the appointment for Oct 24, 09:00 AM.',
      'time': '10 mins ago',
      'type': 'alert',
      'read': false,
    },
    {
      'title': 'New Appointment Request',
      'body': 'You have a new appointment request from Tran Thi B.',
      'time': '1 hour ago',
      'type': 'appointment',
      'read': false,
    },
    {
      'title': 'Lab Results Ready',
      'body': 'Lab results for Patient Le Van C are now available.',
      'time': '2 hours ago',
      'type': 'info',
      'read': true,
    },
    {
      'title': 'System Maintenance',
      'body': 'The system will undergo maintenance tonight at 11 PM.',
      'time': '1 day ago',
      'type': 'system',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF2D3748)),
            onPressed: () {},
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Container(
            color: notif['read'] ? Colors.transparent : Colors.blue.withOpacity(0.05),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(notif['type']),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          _getIcon(notif['type']),
                          color: _getIconColor(notif['type']),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: notif['read'] ? Colors.grey[700] : const Color(0xFF2D3748),
                                  ),
                                ),
                                Text(
                                  notif['time'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['body'],
                              style: TextStyle(
                                color: notif['read'] ? Colors.grey[600] : const Color(0xFF4A5568),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red[50]!;
      case 'appointment':
        return Colors.blue[50]!;
      case 'info':
        return Colors.green[50]!;
      case 'system':
        return Colors.grey[100]!;
      default:
        return Colors.blue[50]!;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red;
      case 'appointment':
        return Colors.blue;
      case 'info':
        return Colors.green;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alert':
        return FontAwesomeIcons.circleExclamation;
      case 'appointment':
        return FontAwesomeIcons.calendarCheck;
      case 'info':
        return FontAwesomeIcons.circleInfo;
      case 'system':
        return FontAwesomeIcons.gear;
      default:
        return FontAwesomeIcons.bell;
    }
  }
}
