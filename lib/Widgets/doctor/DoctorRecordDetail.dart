
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DoctorRecordDetail extends StatefulWidget {
  const DoctorRecordDetail({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorRecordDetail> createState() => _DoctorRecordDetailState();
}

class _DoctorRecordDetailState extends State<DoctorRecordDetail> {
  // Mock data for the record
  final Map<String, dynamic> _record = {
    'patientName': 'Nguyen Van A',
    'patientId': 'PID-12345',
    'date': 'Oct 24, 2023',
    'diagnosis': 'Acute Bronchitis',
    'symptoms': 'Cough, mild fever, sore throat',
    'prescription': [
      {'medicine': 'Amoxicillin 500mg', 'dosage': '1 tablet every 8 hours', 'duration': '5 days'},
      {'medicine': 'Paracetamol 500mg', 'dosage': '1 tablet every 6 hours if fever > 38.5', 'duration': 'As needed'},
      {'medicine': 'Siro Prospan', 'dosage': '5ml every morning', 'duration': '7 days'},
    ],
    'notes': 'Patient needs to rest and drink plenty of water. Follow up in 7 days if symptoms persist.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Record Detail',
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {},
            tooltip: 'Print Record',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
             tooltip: 'Share Record',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _record['patientName'].substring(0, 1),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _record['patientName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_record['patientId']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                         Text(
                          'Date: ${_record['date']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Diagnosis Section
            const Text(
              'Diagnosis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _record['diagnosis'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3182CE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Symptoms: ${_record['symptoms']}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 20),

            // Prescription Section
            const Text(
              'Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
             const SizedBox(height: 10),
             Container(
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.grey.withOpacity(0.05),
                     spreadRadius: 1,
                     blurRadius: 5,
                   ),
                 ],
               ),
               child: ListView.separated(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 itemCount: _record['prescription']!.length,
                 separatorBuilder: (context, index) => const Divider(height: 1),
                 itemBuilder: (context, index) {
                   final item = _record['prescription'][index];
                   return ListTile(
                     leading: const FaIcon(FontAwesomeIcons.pills, color: Colors.blue, size: 20),
                     title: Text(
                       item['medicine'],
                       style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                     ),
                     subtitle: Text('${item['dosage']} • ${item['duration']}'),
                   );
                 },
               ),
             ),
             const SizedBox(height: 20),

            // Notes Section
             const Text(
              'Doctor Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50], // Light yellow for notes
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                _record['notes'],
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF744210),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Edit record logic
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
