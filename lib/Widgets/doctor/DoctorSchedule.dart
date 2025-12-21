import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DoctorSchedule extends StatefulWidget {
  const DoctorSchedule({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorSchedule> createState() => _DoctorScheduleState();
}

class _DoctorScheduleState extends State<DoctorSchedule>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getAppointmentsStream() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('doctor_id', userId)
        .order('date', ascending: true)
        .map((data) => data); // We will enrich/filter locally or fetching joined data is harder with stream
    
    // Note: Supabase stream doesn't support deep joins easily. 
    // We might need to fetch user details separately or use a FutureBuilder if we want joins.
    // For now, let's use Stream for reactivity and fetch user names if needed, 
    // OR just use a FutureBuilder with .select('*, patient:patient_id(name, avatar_url)') which is better.
    // Let's switch to StreamBuilder with a .select query? No, .asStream()
    
    // Better approach for Joins + Realtime:
    // 1. Listen to table changes. 2. Fetch full data on change.
    // For simplicity in this demo, let's use Stream containing just the basic info 
    // and maybe we assume we can't easily get the name without a separate fetch 
    // OR we switch to FutureBuilder and pull-to-refresh.
    // User expects "real data". 
    // Let's use StreamBuilder but do the fetch inside.
  }
  
  // Actually, for "Join" support with Realtime, it's best to use a plain Stream of the table 
  // and then a Future to fetch details, OR just use FutureBuilder with a periodic refresh or manual refresh.
  // Given the complexity, let's use a Stream of the query.
  // Supabase Flutter SDK v2 supports .stream() but joins are limited.
  // Let's try to just fetch "notes" which contains "Bệnh nhân: Name". 
  // I saved "Bệnh nhân: $profileName" in notes in PatientBooking.dart! 
  // So I can parse that or just display "notes". Perfect fallback.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3182CE),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF3182CE),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Lịch hẹn'),
                Tab(text: 'Đã khám'),
                Tab(text: 'Lịch họp'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('appointments')
                  .stream(primaryKey: ['id'])
                  .eq('doctor_id', supabase.auth.currentUser!.id)
                  .order('date', ascending: true),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 if (snapshot.hasError) {
                   return Center(child: Text('Error: ${snapshot.error}'));
                 }
                 
                 final allAppointments = snapshot.data ?? [];
                 
                 // Filter
                 final upcoming = allAppointments.where((a) => 
                     a['type'] != 'meeting' && 
                     (a['status'] == 'Pending' || a['status'] == 'Confirmed')
                 ).toList();
                 
                 final completed = allAppointments.where((a) => 
                     a['status'] == 'Completed' || a['status'] == 'Cancelled'
                 ).toList();
                 
                 final meetings = allAppointments.where((a) => 
                     a['type'] == 'meeting'
                 ).toList();
      
                 return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(upcoming, 'Lịch hẹn'),
                    _buildAppointmentList(completed, 'Đã khám'),
                    _buildAppointmentList(meetings, 'Lịch họp'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<Map<String, dynamic>> appointments, String tabName) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có $tabName nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final notes = appt['notes'] ?? '';
        final isMeeting = appt['type'] == 'meeting';
        
        String title = 'Bệnh nhân';
        String subtitle = 'Khám bệnh';
        String letter = '?';
        Color iconBg = Colors.blue[100]!;
        Color iconColor = Colors.blue[800]!;
        IconData? customIcon;

        if (isMeeting) {
           title = notes.isNotEmpty ? notes : 'Cuộc họp';
           subtitle = 'Lịch họp khoa';
           iconBg = Colors.purple[100]!;
           iconColor = Colors.purple[800]!;
           customIcon = FontAwesomeIcons.users;
        } else {
           // Extract Patient Name from Notes if possible, else use "Bệnh nhân"
           // Format saved: "Bệnh nhân: $profileName. Dịch vụ: $serviceName"
           if (notes.toString().contains('Bệnh nhân:')) {
              final parts = notes.toString().split('.');
              if (parts.isNotEmpty) {
                title = parts[0].replaceAll('Bệnh nhân:', '').trim();
                // If title is empty after trim, revert to default
                if (title.isEmpty) title = 'Bệnh nhân';
                
                if (parts.length > 1) {
                   subtitle = parts[1].replaceAll('Dịch vụ:', '').trim();
                }
              }
           }
           letter = title.isNotEmpty ? title[0].toUpperCase() : '?';
        }
        
        final date = DateTime.parse(appt['date']).toLocal();
        final timeStr = DateFormat('HH:mm').format(date);
        final dateStr = DateFormat('dd/MM/yyyy').format(date);
        final status = appt['status'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: customIcon != null 
                          ? FaIcon(customIcon, color: iconColor, size: 20)
                          : Text(
                              letter,
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
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
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.clock,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(
                      '$dateStr - $timeStr',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusDisplay(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      case 'Chờ xác nhận': return Colors.orange; // Pending mapped to VN
      case 'Đã xác nhận': return Colors.blue;
      case 'Hoàn thành': return Colors.green;
      case 'Đã hủy': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getStatusDisplay(String status) {
     switch (status) {
       case 'Pending': return 'Chờ xác nhận';
       case 'Confirmed': return 'Đã xác nhận';
       case 'Completed': return 'Hoàn thành';
       case 'Cancelled': return 'Đã hủy';
       default: return status;
     }
  }

  // Helper method if we want actions later
  Widget _buildActionButton(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
