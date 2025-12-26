import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
///Khởi tạo trạng thái và tải dữ liệu cho trang quản trị
class _AdminDashboardState extends State<AdminDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _doctors = [];
  int patientCount = 0;
  int doctorCount = 0;
  int pharmacyCount = 0;
  int appointmentCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchDoctors();
  }
  
  Future<void> _fetchDoctors() async {
    final res = await supabase.from('users').select('id, name, doctor_info(specialty)').eq('role', 'doctor');
    if (mounted) {
      setState(() {
        _doctors = List<Map<String, dynamic>>.from(res);
      });
    }
  }
///Hàm tải dữ liệu thống kê
  Future<void> _fetchStats() async {
    try {
      final patients = await supabase.from('users').count(CountOption.exact).eq('role', 'patient');
      final doctors = await supabase.from('users').count(CountOption.exact).eq('role', 'doctor');
      final pharmacies = await supabase.from('users').count(CountOption.exact).eq('role', 'pharmacy');
      final appointments = await supabase.from('appointments').count(CountOption.exact);

      if (mounted) {
        setState(() {
          patientCount = patients;
          doctorCount = doctors;
          pharmacyCount = pharmacies;
          appointmentCount = appointments;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
  ///Hàm hiển thị hộp thoại chọn bác sĩ
  Future<void> _showAssignMeetingDialog() async {
    List<String> selectedDoctorIds = [];
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final noteController = TextEditingController();

    final specialties = _doctors
        .map((d) => (d['doctor_info'] != null && d['doctor_info']['specialty'] != null) 
            ? d['doctor_info']['specialty'] as String 
            : 'General')
        .toSet()
        .toList();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Meeting'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Quick Select by Specialty'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Manual Selection')),
                        ...specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        const DropdownMenuItem(value: 'All', child: Text('Select All Doctors')),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == 'All') {
                            selectedDoctorIds = _doctors.map((d) => d['id'] as String).toList();
                          } else if (val != null) {
                             selectedDoctorIds = _doctors
                               .where((d) {
                                 final spec = (d['doctor_info'] != null && d['doctor_info']['specialty'] != null) 
                                  ? d['doctor_info']['specialty'] 
                                  : 'General';
                                 return spec == val;
                               })
                               .map((d) => d['id'] as String)
                               .toList();
                          } else {
                            selectedDoctorIds = [];
                          }
                        });
                      },
                     ),
                     const SizedBox(height: 10),

                     Text("Selected: ${selectedDoctorIds.length} doctors", style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 5),
                     Container(
                       height: 150,
                       width: double.maxFinite,
                       decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                       child: ListView.builder(
                         shrinkWrap: true,
                         itemCount: _doctors.length,
                         itemBuilder: (context, index) {
                           final doc = _doctors[index];
                           final isSelected = selectedDoctorIds.contains(doc['id']);
                           return CheckboxListTile(
                             value: isSelected,
                             title: Text(doc['name'] ?? 'Unknown'),
                             subtitle: Text(doc['doctor_info']?['specialty'] ?? 'General'),
                             dense: true,
                             onChanged: (val) {
                               setDialogState(() {
                                 if (val == true) {
                                   selectedDoctorIds.add(doc['id']);
                                 } else {
                                   selectedDoctorIds.remove(doc['id']);
                                 }
                               });
                             },
                           );
                         },
                       ),
                     ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context, 
                              firstDate: DateTime.now(), 
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDate: selectedDate
                            );
                            if (d != null) setDialogState(() => selectedDate = d);
                          },
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                          onPressed: () async {
                            final t = await showTimePicker(context: context, initialTime: selectedTime);
                            if (t != null) setDialogState(() => selectedTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Meeting Topic / Notes', border: OutlineInputBorder()),
                    maxLines: 3,
                  )
                ],
              ),
            ),
          ),
          actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                   if (selectedDoctorIds.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one doctor")));
                     return;
                   }
                   
                   final finalDateTime = DateTime(
                     selectedDate.year, selectedDate.month, selectedDate.day,
                     selectedTime.hour, selectedTime.minute
                   );
                   
                   try {
                     final currentUserId = supabase.auth.currentUser!.id;

                     Future<void> insertMeeting(String docId) async {
                        await supabase.from('appointments').insert({
                           'patient_id': currentUserId, 
                           'doctor_id': docId,
                           'date': finalDateTime.toIso8601String(),
                           'status': 'Confirmed',
                           'type': 'meeting',
                           'notes': noteController.text,
                         });
                     }

                     await Future.wait(selectedDoctorIds.map((id) => insertMeeting(id)));

                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meeting assigned to ${selectedDoctorIds.length} doctors!")));
                     Navigator.pop(context);
                   } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                   }
                }, 
                child: const Text('Assign'),
              ),
            ],
            );
        }
      )
    );
  }
///Hàm hiển thị giao diện chính
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignMeetingDialog,
        label: const Text('Assign Meeting'),
        icon: const Icon(Icons.meeting_room),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Patients', patientCount.toString(), FontAwesomeIcons.user, Colors.blue),
                _buildStatCard('Doctors', doctorCount.toString(), FontAwesomeIcons.userDoctor, Colors.purple),
                _buildStatCard('Pharmacy', pharmacyCount.toString(), FontAwesomeIcons.pills, Colors.green),
                _buildStatCard('Appointments', appointmentCount.toString(), FontAwesomeIcons.calendarCheck, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
///Hàm hiển thị thẻ thống kê
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: FaIcon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
