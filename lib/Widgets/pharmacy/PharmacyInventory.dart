//have access on Patient Bottom Navigation
import 'package:flutter/material.dart';

class PharmacyInventory extends StatefulWidget {
  const PharmacyInventory({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyInventory> createState() => _PharmacyInventoryState();

}

class _PharmacyInventoryState extends State<PharmacyInventory> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Pharmacy Inventory'),
    );
  }
}
