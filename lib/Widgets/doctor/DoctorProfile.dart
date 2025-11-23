
//have access on Doctor Bottom Navigation
import 'package:flutter/material.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorProfile> createState() => _DoctorProfileState();

}

class _DoctorProfileState extends State<DoctorProfile> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor Profile'),
    );
  }
}
