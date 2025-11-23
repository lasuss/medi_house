//have access on Patient Bottom Navigation

import 'package:flutter/material.dart';

class PharmacyFilled extends StatefulWidget {
  const PharmacyFilled({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyFilled> createState() => _PharmacyFilledState();

}

class _PharmacyFilledState extends State<PharmacyFilled> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Pharmacy Filled'),
    );
  }
}
