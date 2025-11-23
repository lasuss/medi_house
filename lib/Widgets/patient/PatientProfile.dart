//have access on Patient Bottom Navigation

import 'package:flutter/material.dart';
import 'package:medi_house/menus/bottom_navigation.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientProfile> createState() => _PatientProfileState();

}

class _PatientProfileState extends State<PatientProfile> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Patient Profile'),
    );
  }
}