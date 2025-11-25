//function in notif that allow patient to edit what they want to receive notification
import 'package:flutter/material.dart';

class PatientPersonalizeNotification extends StatefulWidget {
  const PatientPersonalizeNotification({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientPersonalizeNotification> createState() =>
      _PatientPersonalizeNotificationState();
}

class _PatientPersonalizeNotificationState
    extends State<PatientPersonalizeNotification> {

  // States for each notification type
  bool notifyMedicine = true;
  bool notifyAppointment = true;
  bool notifyLabResult = false;
  bool notifyDoctorMessage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1621),
        elevation: 0,
        title: const Text(
          "Cá nhân hóa thông báo",
          style: TextStyle(fontSize: 22, color: Colors.white),
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
                color: const Color(0xFF4A515A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    "Nhắc uống thuốc",
                    notifyMedicine,
                        (value) => setState(() => notifyMedicine = value),
                  ),
                  const Divider(color: Colors.white24),
                  _buildSwitchRow(
                    "Nhắc lịch khám",
                    notifyAppointment,
                        (value) => setState(() => notifyAppointment = value),
                  ),
                  const Divider(color: Colors.white24),
                  _buildSwitchRow(
                    "Kết quả xét nghiệm",
                    notifyLabResult,
                        (value) => setState(() => notifyLabResult = value),
                  ),
                  const Divider(color: Colors.white24),
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
          style: const TextStyle(color: Colors.white, fontSize: 16),
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

