import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CCCDScanner extends StatefulWidget {
  const CCCDScanner({super.key});

  @override
  State<CCCDScanner> createState() => _CCCDScannerState();
}
///Hàm hiển thị giao diện quét CCCD
class _CCCDScannerState extends State<CCCDScanner> {
  bool scanned = false;
  MobileScannerController cameraController = MobileScannerController();

  Map<String, String>? _parseCCCD(String qrData) {
    try {
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
    if (rawDate.length == 8) {
      return "${rawDate.substring(0, 2)}/${rawDate.substring(2, 4)}/${rawDate.substring(4)}";
    }
    return rawDate;
  }
///Hàm hiển thị kết quả quét
  void _showResultSheet(Map<String, String> data) {
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
                'Thông tin CCCD',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              _buildDataRow('Số CCCD:', data['id'] ?? ''),
              _buildDataRow('Họ và tên:', data['name'] ?? ''),
              _buildDataRow('Ngày sinh:', data['dob'] ?? ''),
              _buildDataRow('Giới tính:', data['gender'] ?? ''),
              _buildDataRow('Địa chỉ:', data['address'] ?? ''),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, data);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Xác nhận và Sử dụng', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
       setState(() {
        scanned = false;
      });
    });
  }
///Hàm hiển thị dòng dữ liệu
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           SizedBox(
             width: 100, 
             child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
           ),
           Expanded(
             child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))
           ),
         ],
      ),
    );
  }
///Hàm hiển thị giao diện chính
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Quét CCCD", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
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
                      setState(() => scanned = true);
                      _showResultSheet(parsedData);
                   }
                 }
              }
            },
          ),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(true, true), _corner(true, false)]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(false, true), _corner(false, false)]),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: const Text(
              "Di chuyển camera đến mã QR trên \nCăn Cước Công Dân",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
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
    super.dispose();
  }
}
