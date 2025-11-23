
import 'package:flutter/material.dart';

class PatientAddRecord extends StatefulWidget {
  const PatientAddRecord({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientAddRecord> createState() => _PatientAddRecordState();

}

class _PatientAddRecordState extends State<PatientAddRecord> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Add Record'),
    );
  }
}
