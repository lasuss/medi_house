import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  String _patientName = 'Bệnh nhân';
  String? _avatarUrl;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Fetch User Name & Avatar
      final userRes = await supabase.from('users').select('name, avatar_url').eq('id', userId).single();
      _patientName = userRes['name'] ?? 'Bệnh nhân';
      _avatarUrl = userRes['avatar_url'];

      // 2. Fetch Medical Records (Results)
      final recordsRes = await supabase
          .from('records')
          .select('*, doctor:doctor_id(id, name), appointments(*)') 
          .eq('patient_id', userId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(recordsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Kết quả khám & Xét nghiệm'),
                  const SizedBox(height: 12),
                  _buildRecordsList(),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/patient/records/add'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào,',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _patientName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? NetworkImage(_avatarUrl!)
              : null,
          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? null
              : Text(
                  _patientName.isNotEmpty ? _patientName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Chưa có hồ sơ khám bệnh nào',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final created = DateTime.parse(record['created_at']).toLocal();
        final doctorMap = record['doctor']; // Can be null or Map
        String doctorName = 'Bác sĩ';
        if (doctorMap != null && doctorMap is Map) {
             doctorName = doctorMap['name'] ?? 'Bác sĩ';
        }
        
        // Try to get appointment time
        String? timeDisplay;
        final appointments = record['appointments'];
        if (appointments != null && (appointments is List) && appointments.isNotEmpty) {
           final appt = appointments[0];
           if (appt['date'] != null) {
              final date = DateTime.parse(appt['date']).toLocal();
              final dateStr = DateFormat('dd/MM/yyyy').format(date);
              final timeSlot = appt['time_slot'] ?? '';
              timeDisplay = timeSlot.isNotEmpty ? "$timeSlot - $dateStr" : DateFormat('dd/MM/yyyy HH:mm').format(date);
           }
        }
        
        // Determine type and details based on appointment
        String typeDisplay = 'Phiếu khám';
        IconData icon = Icons.medical_services_outlined;
        Color iconColor = Colors.blue;
        String? doctorDisplay = doctorName;
        
        if (appointments != null && (appointments is List) && appointments.isNotEmpty) {
           final apptType = appointments[0]['type'];
           // 'dich_vu', 'bac_si', 'xet_nghiem'
           if (apptType == 'xet_nghiem') {
              typeDisplay = 'Phiếu Xét Nghiệm';
              icon = Icons.biotech;
              iconColor = Colors.purple;
              doctorDisplay = null; // Hide doctor for lab
           } else if (apptType == 'dich_vu') {
              typeDisplay = 'Khám Dịch Vụ';
              icon = Icons.medical_services_outlined;
              iconColor = Colors.orange;
           } else if (apptType == 'bac_si') {
              typeDisplay = 'Khám Theo Bác Sĩ';
              icon = Icons.person_search;
              iconColor = Colors.blue;
           }
        } else {
            // Fallback heuristics
            final symptoms = (record['symptoms'] as String? ?? '').toLowerCase();
            if (symptoms.contains('xét nghiệm')) {
              typeDisplay = 'Kết quả xét nghiệm';
              icon = Icons.biotech;
              iconColor = Colors.purple;
            } else if (symptoms.contains('đơn thuốc')) {
              typeDisplay = 'Đơn thuốc';
              icon = Icons.medication_outlined;
              iconColor = Colors.green;
            }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                 context.push('/patient/records/${record['id']}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                typeDisplay,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              if (record['status'] == 'Completed') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Hoàn thành",
                                        style: TextStyle(
                                          fontSize: 10, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700]
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (doctorDisplay != null) ...[
                            Text(
                              doctorDisplay,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (timeDisplay != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Hẹn: $timeDisplay",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          Row(
                            children: [
                              Icon(Icons.history, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                 "Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(record['updated_at']).toLocal())}",
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.grey[500],
                                 ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
