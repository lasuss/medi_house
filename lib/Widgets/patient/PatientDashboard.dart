//have access on Patient Bottom Navigation
// have floating button to add new record
// have sub navigation include all, consultation, lab results, Prescriptions
import 'package:flutter/material.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();

}

class _PatientDashboardState extends State<PatientDashboard> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Dashboard'),
    );
  }
}
