
import 'package:flutter/material.dart';

class DoctorRecordDetail extends StatefulWidget {
  const DoctorRecordDetail({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorRecordDetail> createState() => _DoctorRecordDetailState();

}

class _DoctorRecordDetailState extends State<DoctorRecordDetail> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Record Detail'),
    );
  }
}
