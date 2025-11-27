import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientPersonalizeNotification extends StatefulWidget {
  const PatientPersonalizeNotification({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientPersonalizeNotification> createState() =>
      _PatientPersonalizeNotificationState();
}

class _PatientPersonalizeNotificationState extends State<PatientPersonalizeNotification> with SingleTickerProviderStateMixin {

  // States for each notification type
  bool notifyMedicine = true;
  bool notifyAppointment = true;
  bool notifyLabResult = false;
  bool notifyDoctorMessage = true;

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
      backgroundColor: const Color(0xFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFF),
        elevation: 0,
        title: const Text(
          "Cá nhân hóa thông báo",
          style: TextStyle(fontSize: 22, color: Colors.blue),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // CARD SETTINGS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    "Nhắc uống thuốc",
                    notifyMedicine,
                        (value) => setState(() => notifyMedicine = value),
                  ),
                  const Divider(color: Colors.blue),
                  _buildSwitchRow(
                    "Nhắc lịch khám",
                    notifyAppointment,
                        (value) => setState(() => notifyAppointment = value),
                  ),
                  const Divider(color: Colors.blue),
                  _buildSwitchRow(
                    "Kết quả xét nghiệm",
                    notifyLabResult,
                        (value) => setState(() => notifyLabResult = value),
                  ),
                  const Divider(color: Colors.blue),
                  _buildSwitchRow(
                    "Tin nhắn từ bác sĩ",
                    notifyDoctorMessage,
                        (value) => setState(() => notifyDoctorMessage = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E6E6E),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Hủy",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Gửi dữ liệu vào backend hoặc lưu local
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Lưu",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Row builder
  Widget _buildSwitchRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.blue, fontSize: 16,  fontWeight: FontWeight.bold),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF007AFF),
          onChanged: onChanged,
        ),

      ],
    );
  }
}

