import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PharmacyFilled extends StatefulWidget {
  const PharmacyFilled({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyFilled> createState() => _PharmacyFilledState();
}

class _PharmacyFilledState extends State<PharmacyFilled> {
  // Mock data for completed prescriptions
  final List<Map<String, dynamic>> _filledPrescriptions = [
    {
      'id': 'RX004',
      'patientName': 'Hoang Van G',
      'date': '2023-10-26 02:30 PM',
      'doctor': 'Dr. Le Thi B',
      'items': 2,
      'status': 'Completed',
    },
    {
      'id': 'RX005',
      'patientName': 'Vo Thi H',
      'date': '2023-10-26 11:00 AM',
      'doctor': 'Dr. Pham Van D',
      'items': 4,
      'status': 'Completed',
    },
    {
      'id': 'RX006',
      'patientName': 'Dang Van I',
      'date': '2023-10-25 04:45 PM',
      'doctor': 'Dr. Nguyen Van F',
      'items': 1,
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View past filled prescriptions',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filledPrescriptions.length,
                itemBuilder: (context, index) {
                  final item = _filledPrescriptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: const FaIcon(FontAwesomeIcons.check, size: 16, color: Colors.green),
                      ),
                      title: Text(
                        item['patientName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Prescription #${item['id']}'),
                          Text(
                            item['date'],
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item['items']} Items',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['status'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
