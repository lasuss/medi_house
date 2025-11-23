
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
    return const Center(
      child: Text('Doctor Scan QR'),
    );
  }
}
