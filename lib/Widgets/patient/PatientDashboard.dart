import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  late List<Map<String, dynamic>> _filteredRecords;

  final List<String> _filters = [
    'Tất cả',
    'Kết quả khám bệnh',
    'Kết quả xét nghiệm',
    'Đơn thuốc'
  ];

  final List<Map<String, dynamic>> _medicalRecords = [
    {
      'id': 'rec1',
      'icon': Icons.article_outlined,
      'title': 'Annual Blood Work',
      'subtitle': 'Downtown Clinic Labs',
      'date': 'Nov 02, 2023',
      'status': 'Results Ready',
      'category': 'Kết quả xét nghiệm'
    },
    {
      'id': 'rec2',
      'icon': Icons.medical_services_outlined,
      'title': 'Dermatology Follow-up',
      'subtitle': 'Dr. Evelyn Reed',
      'date': 'Oct 26, 2023',
      'status': null,
      'category': 'Kết quả khám bệnh'
    },
    {
      'id': 'rec3',
      'icon': Icons.article_outlined,
      'title': 'Allergy Medication Refill',
      'subtitle': 'Dr. Alan Grant',
      'date': 'Oct 15, 2023',
      'status': null,
      'category': 'Đơn thuốc'
    },
    {
      'id': 'rec4',
      'icon': Icons.medical_services_outlined,
      'title': 'Annual Physical Exam',
      'subtitle': 'Dr. Sarah Johnson',
      'date': 'Sep 21, 2023',
      'status': null,
      'category': 'Kết quả khám bệnh'
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredRecords = _medicalRecords; // Initially, show all records
  }

  void _updateFilteredRecords(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _filteredRecords = _medicalRecords;
      } else {
        final selectedCategory = _filters[index];
        _filteredRecords = _medicalRecords
            .where((record) => record['category'] == selectedCategory)
            .toList();
      }
    });
  }

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
            child: Icon(Icons.person),
          ),
        ),
        title: const Text(
          'Hồ sơ y tế',
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
          context.go('/patient/records/add');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm hồ sơ...',
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
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateFilteredRecords(index);
                }
              },
              avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicalRecordsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredRecords.length,
        itemBuilder: (context, index) {
          final record = _filteredRecords[index];
          return Card(
            color: Colors.white,
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              onTap: () {
                context.go('/patient/records/${record['id']}');
              },
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
