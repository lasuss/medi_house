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
        .eq('id', doctorId)
        .single();

    final patientRes = await supabase
        .from('records')
        .select('patient_id')
        .eq('doctor_id', doctorId);

    final uniquePatients =
    patientRes.map((e) => e['patient_id']).toSet();

    final pendingRes = await supabase
        .from('records')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('status', 'Pending');

    final recordRes = await supabase
        .from('records')
        .select('''
          id,
          created_at,
          status,
          patient:patient_id (
            id,
            name
          ),
          appointment:appointments!left (
            date
          )
        ''')
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    setState(() {
      _doctorName = doctorRes['name'] ?? 'Bác sĩ';
      patientCount = uniquePatients.length;
      pendingReportCount = pendingRes.length;
      records = List<Map<String, dynamic>>.from(recordRes);
      isLoading = false;
    });
  }

  String formatVisitTime(dynamic appointment) {
    if (appointment == null ||
        appointment is! List ||
        appointment.isEmpty ||
        appointment[0]['date'] == null) {
      return 'Chưa có lịch khám';
    }

    final rawDate = appointment[0]['date'];
    DateTime visitDate;

    if (rawDate is String) {
      visitDate = DateTime.parse(rawDate).toLocal();
    } else if (rawDate is int) {
      visitDate = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
    } else {
      return 'Chưa có lịch khám';
    }

    final now = DateTime.now();

    // ===== CHƯA TỚI =====
    if (visitDate.isAfter(now)) {
      return '${visitDate.day.toString().padLeft(2, '0')}/'
          '${visitDate.month.toString().padLeft(2, '0')}/'
          '${visitDate.year} '
          '${visitDate.hour.toString().padLeft(2, '0')}:'
          '${visitDate.minute.toString().padLeft(2, '0')}';
    }

    final diff = now.difference(visitDate);

    // ===== ĐÃ QUA - < 24 GIỜ =====
    if (diff.inHours >= 1) {
      return '${diff.inHours} giờ trước';
    }

    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút trước';
    }

    if (diff.inSeconds >= 10) {
      return 'Vừa xong';
    }

    // ===== ĐÃ QUA - < 7 NGÀY =====
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }

    // ===== > 7 NGÀY =====
    return '${visitDate.day.toString().padLeft(2, '0')}/'
        '${visitDate.month.toString().padLeft(2, '0')}/'
        '${visitDate.year} '
        '${visitDate.hour.toString().padLeft(2, '0')}:'
        '${visitDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, $_doctorName',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đang quản lý ${records.length} hồ sơ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildStatCard(
                    'Bệnh nhân',
                    '$patientCount',
                    FontAwesomeIcons.users,
                    Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(
                    'Hồ sơ chờ',
                    '$pendingReportCount',
                    FontAwesomeIcons.fileMedical,
                    Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              "Hồ sơ gần đây",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient?['name'] ?? 'Bệnh nhân',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Trạng thái: ${record['status']}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVisitTime(record['appointment']),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          GoRouter.of(context).push(
                              '/doctor/records/${record['id']}');
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, color: color),
            const SizedBox(height: 12),
            Text(value,
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
