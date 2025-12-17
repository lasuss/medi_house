import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PharmacyInventory extends StatefulWidget {
  const PharmacyInventory({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyInventory> createState() => _PharmacyInventoryState();
}

class _PharmacyInventoryState extends State<PharmacyInventory> {
  // Mock data for inventory
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Panadol Extra', 'stock': 150, 'unit': 'box', 'status': 'Good'},
    {'name': 'Amoxicillin 500mg', 'stock': 20, 'unit': 'box', 'status': 'Low'},
    {'name': 'Vitamin C 1000mg', 'stock': 45, 'unit': 'tube', 'status': 'Warning'},
    {'name': 'Berberin', 'stock': 200, 'unit': 'bottle', 'status': 'Good'},
    {'name': 'Insulin Pen', 'stock': 8, 'unit': 'pen', 'status': 'Low'},
    {'name': 'Cough Syrup', 'stock': 35, 'unit': 'bottle', 'status': 'Warning'},
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Good': return Colors.green;
      case 'Warning': return Colors.orange;
      case 'Low': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search medicine...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total Items', '${_inventory.length}', Colors.blue),
                _buildStatCard('Low Stock', '2', Colors.red),
              ],
            ),
            const SizedBox(height: 20),

            // Inventory List
            Expanded(
              child: ListView.builder(
                itemCount: _inventory.length,
                itemBuilder: (context, index) {
                  final item = _inventory[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0, // Flat design for list
                    color: Colors.white,
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(FontAwesomeIcons.pills, color: Colors.blue, size: 16),
                      ),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${item['stock']} ${item['unit']} available'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: _getStatusColor(item['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF38B2AC),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
