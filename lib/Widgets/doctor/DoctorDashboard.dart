import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final supabase = Supabase.instance.client;

  int patientCount = 0;
  int pendingReportCount = 0;
  String _doctorName = 'Bác sĩ';

  List<Map<String, dynamic>> records = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final doctorId = supabase.auth.currentUser!.id;
    final doctorRes = await supabase
        .from('users')
        .select('name')
        .eq('id', doctorId);
    final fetchedName = doctorRes.first['name'];

    // ===== Patients (distinct) =====
    final patientRes = await supabase
        .from('records')
        .select('patient_id')
        .eq('doctor_id', doctorId);

    final uniquePatients = patientRes
        .map((e) => e['patient_id'])
        .toSet();

    // ===== Pending reports =====
    final pendingRes = await supabase
        .from('records')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('status', 'Pending');

    // ===== Records list =====
    final recordRes = await supabase
        .from('records')
        .select('''
          id,
          created_at,
          status,
          patient:patient_id (
            id,
            name
          )
        ''')
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    setState(() {
      _doctorName = fetchedName ?? 'Bác sĩ';
      patientCount = uniquePatients.length;
      pendingReportCount = pendingRes.length;
      records = List<Map<String, dynamic>>.from(recordRes);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                'Xin chào, $_doctorName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đang quản lý ${records.length} hồ sơ',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  _buildStatCard(
                    'Bệnh nhân',
                    '$patientCount',
                    FontAwesomeIcons.users,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Hồ sơ chờ',
                    '$pendingReportCount',
                    FontAwesomeIcons.fileMedical,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Records List
              const Text(
                "Hồ sơ gần đây",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final patient = record['patient'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF3182CE),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient?['name'] ?? 'Bệnh nhân',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Trạng thái: ${record['status']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            GoRouter.of(context).push(
                              '/doctor/records/${record['id']}',
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: DoctorSearchDelegate(records),
          );
        },
        backgroundColor: const Color(0xFF3182CE),
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> records;

  DoctorSearchDelegate(this.records);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = records.where((record) {
      final patientName = record['patient']?['name']?.toString().toLowerCase() ?? '';
      final status = record['status']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return patientName.contains(searchQuery) || status.contains(searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final record = results[index];
        final patientName = record['patient']?['name'] ?? 'Bệnh nhân';

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(patientName),
          subtitle: Text('Trạng thái: ${record['status']}\nNgày tạo: ${record['created_at'].toString().split('T')[0]}'),
          isThreeLine: true,
          onTap: () {
            close(context, null); // Close search
            GoRouter.of(context).push('/doctor/records/${record['id']}');
          },
        );
      },
    );
  }
}
