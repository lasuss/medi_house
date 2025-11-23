//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';

class DoctorMessages extends StatefulWidget {
  const DoctorMessages({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorMessages> createState() => _DoctorMessagesState();

}

class _DoctorMessagesState extends State<DoctorMessages> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Messages'),
    );
  }
}
