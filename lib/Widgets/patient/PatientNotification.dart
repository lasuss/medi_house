//have access on Patient Bottom Navigation

import 'package:flutter/material.dart';

class PatientNotification extends StatefulWidget {
  const PatientNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientNotification> createState() => _PatientNotificationState();

}

class _PatientNotificationState extends State<PatientNotification> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Notification'),
    );
  }
}
