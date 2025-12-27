import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorScanNationalID extends StatefulWidget {
  const DoctorScanNationalID({super.key});

  @override
  State<DoctorScanNationalID> createState() => _DoctorScanNationalIDState();
}

class _DoctorScanNationalIDState extends State<DoctorScanNationalID> {
  bool scanned = false;
  MobileScannerController cameraController = MobileScannerController();

  // Field Controllers (Chỉ dùng để hiển thị Review trước khi lưu)
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Parse dữ liệu từ QR CCCD Gắn chip
  Map<String, String>? _parseCCCD(String qrData) {
    try {
      // Định dạng: Số CCCD|Số CMND cũ|Họ tên|Ngày sinh|Giới tính|Địa chỉ|Ngày cấp
      final parts = qrData.split('|');
      if (parts.length >= 6) {
        return {
          'id': parts[0],
          'name': parts[2],
          'dob': _formatDate(parts[3]),
          'gender': parts[4],
          'address': parts[5],
        };
      }
    } catch (e) {
      debugPrint("Lỗi phân tích QR: $e");
    }
    return null;
  }

  String _formatDate(String rawDate) { // Chuyển đổi ngày sinh từ dạng YYYYMMDD sang DD/MM/YYYY
    if (rawDate.length == 8) {
      return "${rawDate.substring(0, 2)}/${rawDate.substring(2, 4)}/${rawDate.substring(4)}";
    }
    return rawDate;
  }

  String _convertToISO(String displayDate) { // Chuyển đổi ngày sinh từ dạng DD/MM/YYYY sang YYYY-MM-DD
    try {
      final parts = displayDate.split('/');
      if (parts.length == 3) {
        return "${parts[2]}-${parts[1]}-${parts[0]}"; // YYYY-MM-DD
      }
    } catch (_) {}
    return displayDate;
  }

  void _showResultSheet(Map<String, String> data) {
    _idController.text = data['id'] ?? '';
    _nameController.text = data['name'] ?? '';
    _dobController.text = data['dob'] ?? '';
    _genderController.text = data['gender'] ?? '';
    _addressController.text = data['address'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xác nhận thông tin Bác sĩ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3182CE)),
            ),
            const SizedBox(height: 8),
            const Text('Vui lòng kiểm tra lại thông tin trích xuất từ thẻ CCCD.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            _buildReviewField('Họ và tên', _nameController),
            const SizedBox(height: 12),
            _buildReviewField('Số CCCD', _idController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildReviewField('Ngày sinh', _dobController)),
                const SizedBox(width: 12),
                Expanded(child: _buildReviewField('Giới tính', _genderController)),
              ],
            ),
            const SizedBox(height: 12),
            _buildReviewField('Địa chỉ thường trú', _addressController, maxLines: 2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveDoctorData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Cập nhật hồ sơ Bác sĩ',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => scanned = false));
  }

  Future<void> _saveDoctorData() async {
    try {
      final userId = UserManager.instance.supabaseUser?.id;
      if (userId == null) return;

      // Chuẩn bị dữ liệu cập nhật
      final updateData = {
        'name': _nameController.text,
        'national_id': _idController.text,
        'dob': _convertToISO(_dobController.text),
        'gender': _genderController.text,
        'address': _addressController.text,
      };

      await Supabase.instance.client.from('users').update(updateData).eq('id', userId);

      if (mounted) {
        Navigator.pop(context); // Đóng BottomSheet
        Navigator.pop(context, true); // Trả về true để DoctorEditProfile load lại dữ liệu
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    }
  }

  Widget _buildReviewField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét QR CCCD Bác sĩ", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (!scanned && capture.barcodes.isNotEmpty) {
                      final code = capture.barcodes.first.rawValue ?? '';
                      final data = _parseCCCD(code);
                      if (data != null) {
                        setState(() => scanned = true);
                        _showResultSheet(data);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Đặt mã QR trên thẻ CCCD vào khung hình để tự động nhập thông tin cá nhân",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}