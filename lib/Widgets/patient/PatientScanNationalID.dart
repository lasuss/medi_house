import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PatientScanNationalID extends StatefulWidget {
  const PatientScanNationalID({super.key});

  @override
  State<PatientScanNationalID> createState() =>
      _PatientScanNationalIDState();
}

class _PatientScanNationalIDState
    extends State<PatientScanNationalID> {
  bool scanned = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1621),
        elevation: 0,
        title: const Text(
          "Quét CCCD",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF4A515A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (barcodeCapture) {
                    if (!scanned && barcodeCapture.barcodes.isNotEmpty) {
                      scanned = true;
                      final code = barcodeCapture.barcodes.first.rawValue ?? '';
                      print("QR DATA: $code");

                      // TODO: chuyển sang màn hình chi tiết hồ sơ bệnh nhân
                      // Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      //   PatientRecordDetailScreen(data: code)
                      // ));
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quét mã QR để truy cập hồ sơ bệnh nhân",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E6E6E),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Enter ID manually",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
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
              ],
            ),
            const SizedBox(height: 20),
          ],
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
