// Compulsory scan National ID to input to Profile
import 'package:flutter/material.dart';

class PatientScanNationalID extends StatefulWidget {
  const PatientScanNationalID({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientScanNationalID> createState() => _PatientScanNationalIDState();

}

class _PatientScanNationalIDState extends State<PatientScanNationalID> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Scan National ID'),
    );
  }
}
