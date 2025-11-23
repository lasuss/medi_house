//show QR code to scan by Doctor
import 'package:flutter/material.dart';

class PatientShowQR extends StatefulWidget {
  const PatientShowQR({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientShowQR> createState() => _PatientShowQRState();

}

class _PatientShowQRState extends State<PatientShowQR> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Show QR'),
    );
  }
}
