import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Widget chính hiển thị mã QR y tế để bác sĩ hoặc dược sĩ quét
class PatientShowQR extends StatefulWidget {
  const PatientShowQR({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientShowQR> createState() => _PatientShowQRState();
}

// Trạng thái quản lý dữ liệu và mã QR hiển thị
class _PatientShowQRState extends State<PatientShowQR> {
  // Dữ liệu placeholder cho mã QR, tên bệnh nhân và mã hồ sơ (thực tế lấy từ state management)
  String _qrData = 'MH123456789';
  final String _patientName = 'John Appleseed';
  final String _recordId = 'MH123456789';

  // Làm mới mã QR bằng cách thêm timestamp để tạo mã tạm thời mới
  void _refreshCode() {
    setState(() {
      _qrData = 'MH123456789-${DateTime.now().millisecondsSinceEpoch}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code has been refreshed.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  // Xây dựng giao diện hiển thị mã QR và thông tin bệnh nhân
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        // Nút quay lại
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        // Tiêu đề màn hình
        title: const Text(
          'Mã Y Tế Của Bạn',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phần hiển thị tên bệnh nhân và mã hồ sơ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF172A46),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã Hồ Sơ: $_recordId',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Phần hiển thị mã QR trong khung tròn
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: QrImageView(
                    padding: const EdgeInsets.all(20),
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Hướng dẫn sử dụng mã QR
            const Text(
              'Vui lòng xuất trình mã này cho bác sĩ hoặc dược sĩ để truy cập hồ sơ của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mã này chứa liên kết bảo mật tạm thời đến hồ sơ của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // Nút làm mới mã QR
            ElevatedButton.icon(
              onPressed: _refreshCode,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Làm mới Mã',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}