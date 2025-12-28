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
///Hàm hiển thị giao diện trang quản lý
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
///Hàm tải dữ liệu trang quản lý
  Future<void> _loadDashboardData() async {
    final doctorId = supabase.auth.currentUser!.id;

    final doctorRes = await supabase
        .from('users')
        .select('name')
        .eq('id', doctorId)
        .single();

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
          triage_data,
          notes,
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

    final List<Map<String, dynamic>> processedRecords = List<Map<String, dynamic>>.from(recordRes);
    
    // Calculate unique patients from the loaded records
    final uniquePatientIds = <String>{};
    
    // Pre-calculate display names to avoid expensive Regex in build loop
    for (var record in processedRecords) {
      if (record['patient'] != null && record['patient']['id'] != null) {
        uniquePatientIds.add(record['patient']['id']);
      }

      String patientName = record['patient']?['name'] ?? 'Bệnh nhân';
      if (record['triage_data'] != null && record['triage_data']['profile_name'] != null) {
        patientName = record['triage_data']['profile_name'];
      } else {
         // Fallback logic for legacy records
         final notes = record['notes']?.toString() ?? '';
         if (notes.startsWith('Booking Init:')) {
           final RegExp nameExp = RegExp(r'Bệnh nhân: (.*?)\.');
           final match = nameExp.firstMatch(notes);
           if (match != null) {
             patientName = match.group(1)?.trim() ?? patientName;
           }
         }
      }
      record['display_name'] = patientName;
    }

    setState(() {
      _doctorName = doctorRes['name'] ?? 'Bác sĩ';
      patientCount = uniquePatientIds.length;
      pendingReportCount = pendingRes.length;
      records = processedRecords;
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
                
                String patientName = patient?['name'] ?? 'Bệnh nhân';
                if (record['triage_data'] != null && record['triage_data']['profile_name'] != null) {
                  patientName = record['triage_data']['profile_name'];
                } else {
                   // Fallback logic for legacy records
                   final notes = record['notes']?.toString() ?? '';
                   if (notes.startsWith('Booking Init:')) {
                     final RegExp nameExp = RegExp(r'Bệnh nhân: (.*?)\.');
                     final match = nameExp.firstMatch(notes);
                     if (match != null) {
                       patientName = match.group(1)?.trim() ?? patientName;
                     }
                   }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.assignment_ind_rounded, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: record['status'] == 'Completed' ? Colors.green[50] : 
                                         record['status'] == 'Prescribed' ? Colors.purple[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: record['status'] == 'Completed' ? Colors.green.withOpacity(0.5) : 
                                           record['status'] == 'Prescribed' ? Colors.purple.withOpacity(0.5) : Colors.orange.withOpacity(0.5)
                                  ),
                                ),
                                child: Text(
                                  record['status'] == 'Completed' ? 'Hoàn thành' : 
                                  record['status'] == 'Prescribed' ? 'Yêu cầu cấp thuốc' : 'Chưa giải quyết',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: record['status'] == 'Completed' ? Colors.green[700] : 
                                           record['status'] == 'Prescribed' ? Colors.purple[700] : Colors.orange[700],
                                  ),
                                ),
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
                                            Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    GoRouter.of(context)
                                        .push('/doctor/records/${record['id']}');
                                  },
                                ),
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
///Hàm hiển thị thẻ thống kê
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
///Hàm hiển thị giao diện tìm kiếm
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
      String nameToCheck = record['patient']?['name']?.toString() ?? '';
      if (record['triage_data'] != null && record['triage_data']['profile_name'] != null) {
         nameToCheck = record['triage_data']['profile_name'];
      } else {
          final notes = record['notes']?.toString() ?? '';
           if (notes.startsWith('Booking Init:')) {
             final RegExp nameExp = RegExp(r'Bệnh nhân: (.*?)\.');
             final match = nameExp.firstMatch(notes);
             if (match != null) {
               nameToCheck = match.group(1)?.trim() ?? nameToCheck;
             }
           }
      }
      
      final patientName = nameToCheck.toLowerCase();
      final status = record['status']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return patientName.contains(searchQuery) || status.contains(searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final record = results[index];
        
        String patientName = record['patient']?['name'] ?? 'Bệnh nhân';
        if (record['triage_data'] != null && record['triage_data']['profile_name'] != null) {
           patientName = record['triage_data']['profile_name'];
        }

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
