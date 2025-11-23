//have access on Patient Bottom Navigation
import 'package:flutter/material.dart';

class PharmacyPending extends StatefulWidget {
  const PharmacyPending({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyPending> createState() => _PharmacyPendingState();

}

class _PharmacyPendingState extends State<PharmacyPending> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Pharmacy Pending'),
    );
  }
}
