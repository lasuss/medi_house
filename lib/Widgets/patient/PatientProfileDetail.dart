import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

// Widget hiển thị chi tiết hồ sơ bệnh nhân
class PatientProfileDetail extends StatelessWidget {
  final Map<String, dynamic> profile;

  const PatientProfileDetail({super.key, required this.profile});

  // Định dạng ngày từ chuỗi ISO sang định dạng dd/MM/yyyy
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  // Xây dựng giao diện chi tiết hồ sơ bệnh nhân
  Widget build(BuildContext context) {
    // Tạo mã bệnh nhân giả lập theo định dạng MP-YYMMDD... (dùng cho QR code)
    final String patientCode = "MP-${DateFormat('yyMMdd').format(DateTime.now())}${profile['id'].toString().substring(0, 4)}".toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết hồ sơ", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề phần thông tin bệnh nhân
            const Text(
              "THÔNG TIN BỆNH NHÂN",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            _buildRow("Họ và tên", profile['full_name']?.toUpperCase() ?? "CHƯA CẬP NHẬT"),
            _buildDivider(),
            _buildRow("Mã số bệnh nhân", patientCode),
            _buildDivider(),
            _buildRow("Ngày sinh", _formatDate(profile['dob'] ?? '')),
            _buildDivider(),
            _buildRow("Giới tính", profile['gender'] ?? "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Mã định danh/CCCD/\nPassport", profile['national_id'] ?? "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Mã bảo hiểm y tế", profile['health_insurance_code']?.toString().isNotEmpty == true ? profile['health_insurance_code'] : "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Nghề nghiệp", profile['job'] ?? "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Số điện thoại", profile['phone'] ?? "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Email", profile['email'] ?? "Chưa cập nhật"),
            _buildDivider(),
            _buildRow("Địa chỉ (ghi trên CCCD)", profile['address_street'] ?? "Chưa cập nhật", isAddress: true),

            const SizedBox(height: 40),
            // Phần mã QR bệnh nhân
            Center(
              child: Column(
                children: [
                  BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: patientCode,
                    width: 200,
                    height: 200,
                    drawText: false,
                  ),
                  const SizedBox(height: 8),
                  Text(patientCode, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget một dòng thông tin (nhãn bên trái, giá trị bên phải)
  Widget _buildRow(String label, String value, {bool isAddress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: isAddress ? TextAlign.right : TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF263238),
                fontSize: 15,
                fontWeight: isAddress ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Đường phân cách giữa các dòng thông tin
  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], thickness: 1, height: 1);
  }
}