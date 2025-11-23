//have access on Doctor Bottom Navigation
import 'package:flutter/material.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();

}

class _DoctorDashboardState extends State<DoctorDashboard> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Dashboard'),
    );
  }
}
