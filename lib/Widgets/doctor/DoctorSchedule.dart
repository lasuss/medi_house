//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';

class DoctorSchedule extends StatefulWidget {
  const DoctorSchedule({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorSchedule> createState() => _DoctorScheduleState();

}

class _DoctorScheduleState extends State<DoctorSchedule> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Schedule'),
    );
  }
}
