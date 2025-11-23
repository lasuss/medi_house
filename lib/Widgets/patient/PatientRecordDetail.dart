
import 'package:flutter/material.dart';

class PatientRecordDetail extends StatefulWidget {
  const PatientRecordDetail({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientRecordDetail> createState() => _PatientRecordDetailState();

}

class _PatientRecordDetailState extends State<PatientRecordDetail> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Record Detail'),
    );
  }
}
