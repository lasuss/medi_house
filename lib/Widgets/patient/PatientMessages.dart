//have access on Patient Bottom Navigation

import 'package:flutter/material.dart';

class PatientMessages extends StatefulWidget {
  const PatientMessages({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientMessages> createState() => _PatientMessagesState();

}

class _PatientMessagesState extends State<PatientMessages> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Messages'),
    );
  }
}
