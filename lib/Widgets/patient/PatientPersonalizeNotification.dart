import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Widget chính cho màn hình cá nhân hóa cài đặt thông báo của bệnh nhân
class PatientPersonalizeNotification extends StatefulWidget {
  const PatientPersonalizeNotification({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientPersonalizeNotification> createState() =>
      _PatientPersonalizeNotificationState();
}

// Trạng thái quản lý cài đặt thông báo cá nhân
class _PatientPersonalizeNotificationState extends State<PatientPersonalizeNotification> with SingleTickerProviderStateMixin {

  // Trạng thái bật/tắt cho từng loại thông báo
  bool notifyMedicine = true;
  bool notifyAppointment = true;
  bool notifyLabResult = false;
  bool notifyDoctorMessage = true;

  // Controller cho TabBar (dù hiện tại chưa dùng đến TabBar, nhưng đã khai báo)
  late TabController _tabController;

  @override
  // Khởi tạo TabController
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  // Giải phóng TabController khi widget bị hủy
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  // Xây dựng giao diện chính của màn hình cá nhân hóa thông báo
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF),
      appBar: AppBar(
          iconTheme: const IconThemeData(color: const Color(0xFF2196F3)),
          backgroundColor: const Color(0xFFFFFF),
          elevation: 0,
          // Tiêu đề màn hình
          title: const Center(child: Text(
            "Cá nhân hóa thông báo",
            style: TextStyle(fontSize: 22, color: Colors.blue),
          ),)

      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Phần cài đặt bật/tắt các loại thông báo
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

            // Hai nút Hủy và Lưu ở dưới cùng
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    // Quay lại màn hình trước mà không lưu
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
                    // Lưu cài đặt (hiện tại chưa implement gửi backend)
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

  // Widget một dòng cài đặt với tiêu đề và Switch bật/tắt
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