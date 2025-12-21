
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

class PatientProfileDetail extends StatelessWidget {
  final Map<String, dynamic> profile;

  const PatientProfileDetail({super.key, required this.profile});

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate a pseudo-patient ID if not present (Mocking the format MP-YYMMDD...)
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
            const Text(
              "THÔNG TIN BỆNH NHÂN",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1), // Dark Blue
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
              textAlign: isAddress ? TextAlign.right : TextAlign.right, // Image aligns values to right? Or Left aligned in second column? 
              // Looking at image: Values are Left aligned within their column, but the column starts at a specific point.
              // Actually, looking closely, "Họ và tên" is Left, "NGUYỄN LÊ..." is Right aligned or just starts at center.
              // Let's use TextAlign.right for cleanliness or try to mimic the spacing.
              // The image shows Label on left, Value on right (or center-right).
              style: TextStyle(
                color: const Color(0xFF263238), // Dark Blue Grey
                fontSize: 15,
                fontWeight: isAddress ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], thickness: 1, height: 1);
  }
}
