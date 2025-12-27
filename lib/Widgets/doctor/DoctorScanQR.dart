
import 'package:flutter/material.dart';

class DoctorScanQR extends StatefulWidget {
  const DoctorScanQR({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorScanQR> createState() => _DoctorScanQRState();
}

class _DoctorScanQRState extends State<DoctorScanQR> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Camera Preview (Placeholder)
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.camera_alt, size: 80, color: Colors.white24),
            ),
          ),
          
          // Overlay Scanner Frame
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.5), width: 50),
            ),
          ),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)))),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)))),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)))),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)))),
                ),
                // Scanning animation bar (mock)
                Align(
                  alignment: Alignment(0, 0),
                  child: Container(
                    height: 2,
                    width: 230,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
           Positioned(
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Căn chỉnh mã QR sao cho nằm trong khung để quét',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
