//function in notif that allow patient to edit what they want to receive notification
import 'package:flutter/material.dart';

class PatientPersonalizeNotification extends StatefulWidget {
  const PatientPersonalizeNotification({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientPersonalizeNotification> createState() => _PatientPersonalizeNotificationState();

}

class _PatientPersonalizeNotificationState extends State<PatientPersonalizeNotification> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Personalize Notification'),
    );
  }
}
