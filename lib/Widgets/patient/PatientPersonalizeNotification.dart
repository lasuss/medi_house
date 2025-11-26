import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientPersonalizeNotification extends StatefulWidget {
  const PatientPersonalizeNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientPersonalizeNotification> createState() =>
      _PatientPersonalizeNotificationState();
}

class _PatientPersonalizeNotificationState
    extends State<PatientPersonalizeNotification>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'icon': Icons.calendar_today,
      'title': 'Appointment Reminder',
      'subtitle': 'Dr. Smith - Tomorrow at 10:00 AM',
      'time': '5m ago',
      'unread': true,
      'route': '/patient/appointments',
    },
    {
      'icon': Icons.science_outlined,
      'title': 'Lab Results Available',
      'subtitle': 'Your blood test results are in.',
      'time': '30m ago',
      'unread': true,
      'route': '/patient/records/rec1',
    },
    {
      'icon': Icons.medication_outlined,
      'title': 'Medication Ready',
      'subtitle': 'Your prescription is ready for pickup.',
      'time': '1h ago',
      'unread': false,
      'route': '/patient/records/rec3',
    },
  ];

  final List<Map<String, dynamic>> _yesterdayNotifications = [
    {
      'icon': Icons.receipt_long_outlined,
      'title': 'Payment Confirmed',
      'subtitle': 'Your invoice #12345 has been paid.',
      'time': 'Yesterday',
      'unread': false,
      'route': null, // No route for this one yet
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Personalize'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(_todayNotifications, _yesterdayNotifications),
          _buildNotificationsList(
              _todayNotifications.where((n) => n['unread'] == true).toList(),
              _yesterdayNotifications
                  .where((n) => n['unread'] == true)
                  .toList()),
          _buildNotificationsList(_todayNotifications, _yesterdayNotifications),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      List<Map<String, dynamic>> today, List<Map<String, dynamic>> yesterday) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (today.isNotEmpty) ...[
          const Text(
            'Today',
            style: TextStyle(
                color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: today
                  .map((notification) => _buildNotificationItem(notification,
                      isLast: notification == today.last))
                  .toList(),
            ),
          ),
        ],
        if (yesterday.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Yesterday',
            style: TextStyle(
                color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: yesterday
                  .map((notification) => _buildNotificationItem(notification,
                      isLast: notification == yesterday.last))
                  .toList(),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification,
      {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
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
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
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
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 70.0),
            child: Divider(
              color: Colors.grey.withOpacity(0.2),
              height: 1,
            ),
          )
      ],
    );
  }
}
