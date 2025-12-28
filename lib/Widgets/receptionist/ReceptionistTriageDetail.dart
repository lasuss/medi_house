import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReceptionistTriageDetail extends StatefulWidget {
  final String recordId;
  const ReceptionistTriageDetail({Key? key, required this.recordId}) : super(key: key);

  @override
  State<ReceptionistTriageDetail> createState() => _ReceptionistTriageDetailState();
}

class _ReceptionistTriageDetailState extends State<ReceptionistTriageDetail> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _record;
  
  // Chọn bác sĩ
  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedSpecialtyFilter;
  bool _isSaving = false;

  final List<String> _specialties = [
    'Đa khoa', 'Nội khoa', 'Ngoại khoa', 'Nhi khoa', 'Tim mạch', 'Da liễu', 'Tai Mũi Họng', 'Tiêu hóa - Gan mật'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Lấy thông tin bản ghi
      final recRes = await supabase
          .from('records')
          .select('*, patient:patient_id(*)') // Lấy thông tin bệnh nhân
          .eq('id', widget.recordId)
          .single();
      
      // 2. Lấy danh sách bác sĩ
      final docRes = await supabase
          .from('doctor_info')
          .select('*, user:user_id(name, avatar_url)');

      if (mounted) {
        setState(() {
          _record = recRes;
          _doctors = List<Map<String, dynamic>>.from(docRes);
          
          // Điền sẵn nếu đang xem lịch sử (đã có bác sĩ)
          if (_record!['doctor_id'] != null) {
            _selectedDoctorId = _record!['doctor_id'];
            
            // Thử tìm chuyên khoa để đặt bộ lọc (tùy chọn)
            try {
              final doc = _doctors.firstWhere((d) => d['user_id'] == _selectedDoctorId);
              if (_specialties.contains(doc['specialty'])) {
                 _selectedSpecialtyFilter = doc['specialty'];
              }
            } catch (_) {}
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _assignDoctor() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn bác sĩ')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Cập nhật bản ghi với mã bác sĩ
      await supabase.from('records').update({
        'doctor_id': _selectedDoctorId,
        'status': 'Pending', // Đảm bảo trạng thái là Pending để bác sĩ thấy
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.recordId);

      // Create Appointment record automatically? 
      // The user prompt implied just classifying ("phân loại vào khoa").
      // But our system works on Doctor assignment.
      // Ideally we create an appointment too so it shows in Doctor's schedule.
      // For now, let's just assign the Doctor ID to the Record, which makes it visible in DoctorRecordDetail if they query it?
      // Actually, DoctorDashboard lists APPOINTMENTS usually.
      // So we should probably create an appointment for "Today" (Now).
      
      // Quản lý lịch hẹn (Appointment)
      final existingAppt = await supabase
          .from('appointments')
          .select('id')
          .eq('record_id', widget.recordId)
          .maybeSingle();

      final now = DateTime.now();
      
      if (existingAppt != null) {
        // Cập nhật lịch hẹn có sẵn
        await supabase.from('appointments').update({
          'doctor_id': _selectedDoctorId,
          'date': now.toIso8601String(),
          'time_slot': DateFormat('HH:mm').format(now),
          'updated_at': now.toIso8601String(),
        }).eq('id', existingAppt['id']);
      } else {
        // Tạo lịch hẹn mới
        await supabase.from('appointments').insert({
          'record_id': widget.recordId,
          'patient_id': _record!['patient_id'],
          'doctor_id': _selectedDoctorId,
          'date': now.toIso8601String(),
          'time_slot': DateFormat('HH:mm').format(now),
          'status': 'Pending',
          'type': 'bac_si',
          'notes': 'Được phân loại từ lễ tân',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phân loại và chuyển bác sĩ thành công.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_record == null) {
      return const Scaffold(body: Center(child: Text("Không tìm thấy dữ liệu")));
    }

    final patient = _record!['patient'] ?? {};
    final triageData = _record!['triage_data'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết yêu cầu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildPatientInfo(patient),
             const SizedBox(height: 20),
             _buildTriageInfo(triageData),
             const SizedBox(height: 30),
             const Divider(thickness: 1),
             const SizedBox(height: 20),
             _buildDoctorAssignment(),
             const SizedBox(height: 40),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _isSaving ? null : _assignDoctor,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                 child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : Text(_record!['doctor_id'] == null ? "Xác Nhận Phân Loại & Chuyển Bác Sĩ" : "Cập Nhật Bác Sĩ Mới", 
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> p) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: p['avatar_url'] != null ? NetworkImage(p['avatar_url']) : null,
          child: p['avatar_url'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text(p['name'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("SĐT: ${p['phone'] ?? 'N/A'}\nCCCD: ${p['national_id'] ?? 'N/A'}"),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTriageInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("THÔNG TIN KHAI BÁO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 10),
        _buildInfoRow('Triệu chứng chính', data['main_symptoms']),
        _buildInfoRow('Thời gian bị', data['duration']),
        _buildInfoRow('Mức độ', "${data['severity']}/10"),
        _buildInfoRow('Tuổi', "${data['age']}"),
        _buildInfoRow('Giới tính', data['gender']),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
          child: _buildInfoRow('Mong muốn khám', "${data['requested_time']} - ${data['requested_date']}"),
        ),
        const SizedBox(height: 10),
        const Text("Dấu hiệu nguy hiểm:", style: TextStyle(fontWeight: FontWeight.bold)),
        if ((data['dangerous_signs'] as List?)?.isEmpty ?? true)
          const Text("Không có", style: TextStyle(color: Colors.green))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (data['dangerous_signs'] as List).map((e) => Text("• $e", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))).toList(),
          )
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDoctorAssignment() {
    // Lọc danh sách bác sĩ
    final doctorsFiltered = _doctors.where((d) {
       if (_selectedSpecialtyFilter == null) return true;
       return d['specialty'] == _selectedSpecialtyFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PHÂN LOẠI VÀ CHỈ ĐỊNH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 16),
        
        // Filter Chips for Specialty
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _specialties.map((spec) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(spec),
                selected: _selectedSpecialtyFilter == spec,
                onSelected: (val) => setState(() {
                  _selectedSpecialtyFilter = val ? spec : null;
                  _selectedDoctorId = null; // Reset selection
                }),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Danh sách chọn bác sĩ
        if (doctorsFiltered.isEmpty)
           const Padding(padding: EdgeInsets.all(8.0), child: Text("Không tìm thấy bác sĩ phù hợp", style: TextStyle(fontStyle: FontStyle.italic))),

        ...doctorsFiltered.map((doc) {
           final user = doc['user'] ?? {};
           final name = user['name'] ?? 'Bác sĩ';
           final spec = doc['specialty'] ?? 'Đa khoa';
           
           return RadioListTile<String>(
             value: doc['user_id'], // Assuming user_id is the doctor's user ID used in records
             groupValue: _selectedDoctorId,
             onChanged: (val) => setState(() => _selectedDoctorId = val),
             secondary: CircleAvatar(
               backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
               child: user['avatar_url'] == null ? const Icon(Icons.medical_services, size: 16) : null,
             ),
             title: Text(name),
             subtitle: Text(spec),
           );
        }).toList(),
      ],
    );
  }
}
