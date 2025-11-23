//have access on Admin Bottom Navigation

import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();

}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Admin Dashboard'),
    );
  }
}
