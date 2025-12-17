import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientScanNationalID extends StatefulWidget {
  const PatientScanNationalID({super.key});

  @override
  State<PatientScanNationalID> createState() =>
      _PatientScanNationalIDState();
}

class _PatientScanNationalIDState extends State<PatientScanNationalID> {
  bool scanned = false;
  MobileScannerController cameraController = MobileScannerController();

  // Field Controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Map<String, String>? _parseCCCD(String qrData) {
    try {
      // Vietnam CCCD QR format:
      // ID|Old_ID|Name|DOB|Gender|Address|DateOfIssue
      final parts = qrData.split('|');
      if (parts.length >= 6) {
        return {
          'id': parts[0],
          'old_id': parts[1],
          'name': parts[2],
          'dob': _formatDate(parts[3]),
          'gender': parts[4],
          'address': parts[5],
          'issue_date': parts.length > 6 ? _formatDate(parts[6]) : '',
        };
      }
    } catch (e) {
      debugPrint("Error parsing CCCD: $e");
    }
    return null;
  }

  String _formatDate(String rawDate) {
    // rawDate is usually ddMMyyyy
    if (rawDate.length == 8) {
      return "${rawDate.substring(0, 2)}/${rawDate.substring(2, 4)}/${rawDate.substring(4)}";
    }
    return rawDate;
  }

  String _convertToISO(String displayDate) {
    try {
      final parts = displayDate.split('/');
      if (parts.length == 3) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin CCCD (Chỉ đọc)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              _buildTextField('Số CCCD', _idController),
              const SizedBox(height: 12),
              _buildTextField('Họ và tên', _nameController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Ngày sinh', _dobController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Giới tính', _genderController)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Địa chỉ', _addressController, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final userId = UserManager.instance.supabaseUser?.id;
                      if (userId != null) {
                         // Convert DOB to YYYY-MM-DD for Supabase
                         final dobForDB = _convertToISO(_dobController.text);
                         
                         await Supabase.instance.client.from('users').update({
                           'name': _nameController.text,
                           'national_id': _idController.text,
                           'dob': dobForDB,
                           'gender': _genderController.text,
                           'address': _addressController.text,
                         }).eq('id', userId);
                         
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Đã cập nhật thông tin thành công!')),
                           );
                           Navigator.pop(context); // Close sheet
                           Navigator.pop(context, true); // Return success
                         }
                      }
                    } catch (e) {
                       if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Lỗi khi lưu: $e')),
                         );
                       }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Xác nhận & Lưu', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
       setState(() {
        scanned = false; // Allow rescanning
      });
    });
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: true, // Make read-only
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.grey[200], // Visual indication
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFF),
        elevation: 0,
        title: const Text(
          "Quét CCCD",
          style: TextStyle(fontSize: 22, color: Colors.blue),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A515A),
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: (barcodeCapture) {
                          if (!scanned && barcodeCapture.barcodes.isNotEmpty) {
                             final code = barcodeCapture.barcodes.first.rawValue ?? '';
                             if (code.isNotEmpty) {
                               debugPrint("QR DATA: $code");
                               final parsedData = _parseCCCD(code);
                               if (parsedData != null) {
                                  setState(() {
                                    scanned = true;
                                  });
                                  _showResultSheet(parsedData);
                               } else {
                                  // Invalid format logic (optional)
                               }
                             }
                          }
                        },
                      ),
                      // Scanner Overlay
                       Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _corner(true, true), // Top Left
                                  _corner(true, false), // Top Right
                                ],
                              ),
                               Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _corner(false, true), // Bottom Left
                                  _corner(false, false), // Bottom Right
                                ],
                              ),
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Di chuyển camera đến mã QR trên \nCăn Cước Công Dân",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500
                ),
              ),
               const SizedBox(height: 40),
              const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Quay lại", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _corner(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
