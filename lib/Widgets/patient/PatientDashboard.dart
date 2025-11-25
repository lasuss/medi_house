import 'package:flutter/material.dart';


class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}


class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;


  final List<String> _filters = [
    'All',
    'Consultations',
    'Lab Results',
    'Prescriptions'
  ];


  final List<Map<String, dynamic>> _medicalRecords = [
    {
      'icon': Icons.article_outlined,
      'title': 'Annual Blood Work',
      'subtitle': 'Downtown Clinic Labs',
      'date': 'Nov 02, 2023',
      'status': 'Results Ready'
    },
    {
      'icon': Icons.medical_services_outlined,
      'title': 'Dermatology Follow-up',
      'subtitle': 'Dr. Evelyn Reed',
      'date': 'Oct 26, 2023',
      'status': null
    },
    {
      'icon': Icons.article_outlined,
      'title': 'Allergy Medication Refill',
      'subtitle': 'Dr. Alan Grant',
      'date': 'Oct 15, 2023',
      'status': null
    },
    {
      'icon': Icons.medical_services_outlined,
      'title': 'Annual Physical Exam',
      'subtitle': 'Dr. Sarah Johnson',
      'date': 'Sep 21, 2023',
      'status': null
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            // Display a user icon or image
            child: Icon(Icons.person),
          ),
        ),
        title: const Text(
          'Medical Records',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.blue),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 20),
            _buildFilterChips(),
            const SizedBox(height: 20),
            _buildMedicalRecordsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle FAB tap
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search records...',
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }


  Widget _buildFilterChips() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: _selectedIndex == index,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue,
              labelStyle: const TextStyle(color: Colors.black),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
            ),
          );
        },
      ),
    );
  }


  Widget _buildMedicalRecordsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _medicalRecords.length,
        itemBuilder: (context, index) {
          final record = _medicalRecords[index];
          return Card(
            color: Colors.white,
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(record['icon'], color: Colors.white),
              ),
              title: Text(
                record['title'],
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                record['subtitle'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record['date'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (record['status'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record['status'],
                        style:
                        const TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
