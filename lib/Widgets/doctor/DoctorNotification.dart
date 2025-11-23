//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';

class DoctorNotification extends StatefulWidget {
  const DoctorNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorNotification> createState() => _DoctorNotificationState();

}

class _DoctorNotificationState extends State<DoctorNotification> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Notification'),
    );
  }
}
