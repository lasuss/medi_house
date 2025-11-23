//have access on Patient Bottom Navigation

import 'package:flutter/material.dart';

class PatientAppointment extends StatefulWidget {
  const PatientAppointment({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientAppointment> createState() => _PatientAppointmentState();

}

class _PatientAppointmentState extends State<PatientAppointment> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Appointment'),
    );
  }
}
