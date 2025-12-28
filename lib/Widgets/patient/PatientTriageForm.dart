import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PatientTriageForm extends StatefulWidget {
  const PatientTriageForm({Key? key}) : super(key: key);

  @override
  State<PatientTriageForm> createState() => _PatientTriageFormState();
}

class _PatientTriageFormState extends State<PatientTriageForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Các trường nhập liệu của form
  final TextEditingController _symptomsController = TextEditingController();
  String _duration = 'Dưới 1 ngày';
  double _severity = 1.0; // 1-10
  
  // Thông tin nhân khẩu học (Tự động điền từ hồ sơ)

  // Danh sách các dấu hiệu nguy hiểm cần cảnh báo
  final Map<String, bool> _dangerousSigns = {
    'Khó thở': false,
    'Đau ngực dữ dội': false,
    'Sốt cao không hạ': false,
    'Co giật': false,
    'Chảy máu không cầm': false,
    'Mất ý thức / Lơ mơ': false,
  };

  // Dữ liệu phân loại (Triage)
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  List<Map<String, dynamic>> _profiles = [];
  Map<String, dynamic>? _selectedProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Lấy danh sách hồ sơ bệnh nhân của người dùng này
      final res = await supabase.from('patient_profiles').select().eq('user_id', userId);
      
      if (mounted) {
        setState(() {
          _profiles = List<Map<String, dynamic>>.from(res);
          _isLoadingProfile = false;
          
          // Tự động chọn hồ sơ đầu tiên nếu chưa chọn
          if (_profiles.isNotEmpty && _selectedProfile == null) {
            _onProfileSelected(_profiles.first);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _onProfileSelected(Map<String, dynamic> profile) {
    setState(() {
      _selectedProfile = profile;
    });
  }

  Future<void> _submitTriage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn giờ mong muốn khám')));
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser!.id;
      final profileName = _selectedProfile?['full_name'] ?? 'Không xác định';
      
      // Tính toán tuổi từ ngày sinh (nếu có)
      int age = 0;
      String gender = 'Không rõ';
      
      if (_selectedProfile != null) {
        if (_selectedProfile!['dob'] != null) {
           final dob = DateTime.parse(_selectedProfile!['dob']);
           age = DateTime.now().year - dob.year;
        }
        if (_selectedProfile!['gender'] != null) {
           gender = _selectedProfile!['gender'];
        }
      }

      final dangerousSignsSelected = _dangerousSigns.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      String fullAddress = 'Không rõ';
      if (_selectedProfile != null) {
         final addrParts = [
           _selectedProfile!['address_street'],
           _selectedProfile!['address_ward'],
           _selectedProfile!['address_district'],
           _selectedProfile!['address_province']
         ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
         if (addrParts.isNotEmpty) fullAddress = addrParts;
      }

      final triageData = {
        'profile_name': profileName,
        'main_symptoms': _symptomsController.text,
        'duration': _duration,
        'severity': _severity.round(),
        'age': age,
        'gender': gender,
        'address': fullAddress,
        'dangerous_signs': dangerousSignsSelected,
        'requested_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'requested_time': _selectedTime,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // Tạo bản ghi y tế mới
      await supabase.from('records').insert({
        'patient_id': userId,
        'doctor_id': null, // Quan trọng: NULL nghĩa là cần được phân loại/điều phối
        'status': 'Pending',
        'symptoms': _symptomsController.text, // Lưu lại triệu chứng để dễ xem ở danh sách
        'notes': 'Yêu cầu phân loại cho: $profileName',
        'triage_data': triageData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu phân loại thành công! Vui lòng chờ lễ tân sắp xếp.')),
        );
        context.go('/patient/dashboard');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ phân loại'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Vui lòng cung cấp thông tin triệu chứng để bộ phận lễ tân sắp xếp bác sĩ phù hợp nhất cho bạn.",
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 0. Chọn hồ sơ bệnh nhân
              _buildSectionTitle('Thông tin người bệnh'),
              if (_isLoadingProfile)
                 const Center(child: LinearProgressIndicator())
              else if (_profiles.isEmpty)
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                   child: const Text("Bạn chưa có hồ sơ nào. Vui lòng tạo hồ sơ trước.", style: TextStyle(color: Colors.orange)),
                 )
              else 
                 Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.grey[300]!),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: _profiles.map((p) {
                       return RadioListTile<Map<String, dynamic>>(
                         value: p,
                         groupValue: _selectedProfile,
                         onChanged: (val) => _onProfileSelected(val!),
                         title: Text(p['full_name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                         subtitle: Text(p['dob'] != null 
                             ? "NS: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(p['dob']))} - ${p['gender']}" 
                             : (p['gender'] ?? '')),
                         activeColor: Colors.blue,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                       );
                     }).toList(),
                   ),
                 ),

              const SizedBox(height: 24),

              // 1. Triệu chứng chính
              _buildSectionTitle('1. Triệu chứng chính *'),
              TextFormField(
                controller: _symptomsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'VD: Đau bụng vùng rốn, sốt nhẹ...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập triệu chứng' : null,
              ),
              const SizedBox(height: 20),

              // 2. Thời gian mắc bệnh
              _buildSectionTitle('2. Thời gian bị bao lâu?'),
              DropdownButtonFormField<String>(
                value: _duration,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['Dưới 1 ngày', '1 - 3 ngày', '3 - 7 ngày', 'Trên 1 tuần', 'Trên 1 tháng']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _duration = val!),
              ),
              const SizedBox(height: 20),

              // 3. Mức độ nghiêm trọng
              _buildSectionTitle('3. Mức độ khó chịu (1 - 10)'),
              Row(
                children: [
                  const Text('Nhẹ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Slider(
                      value: _severity,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _severity.round().toString(),
                      activeColor: _severity > 7 ? Colors.red : (_severity > 4 ? Colors.orange : Colors.green),
                      onChanged: (val) => setState(() => _severity = val),
                    ),
                  ),
                  const Text('Nặng', style: TextStyle(color: Colors.red)),
                ],
              ),
              Center(child: Text("Mức độ: ${_severity.round()}/10", style: const TextStyle(fontWeight: FontWeight.bold))),
              
              const SizedBox(height: 24),

              // 4. Dấu hiệu nguy hiểm
              _buildSectionTitle('4. Dấu hiệu cảnh báo (nếu có)'),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red[50]!.withOpacity(0.3)
                ),
                child: Column(
                  children: _dangerousSigns.keys.map((key) {
                    return CheckboxListTile(
                      title: Text(key, style: const TextStyle(fontSize: 14)),
                      value: _dangerousSigns[key],
                      activeColor: Colors.red,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => setState(() => _dangerousSigns[key] = val!),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 5. Thời gian mong muốn khám
              _buildSectionTitle('5. Mong muốn khám lúc'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = null;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text("Chọn giờ:", style: TextStyle(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 10),
                           Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              '08:00', '09:00', '10:00', '11:00',
                              '13:30', '14:30', '15:30', '16:30'
                            ].map((time) {
                              final isSelected = _selectedTime == time;
                              return ChoiceChip(
                                label: Text(time),
                                selected: isSelected,
                                onSelected: (selected) {
                                   setState(() => _selectedTime = selected ? time : null);
                                },
                                selectedColor: Colors.blue,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                                checkmarkColor: Colors.white,
                              );
                            }).toList(),
                          ),
                         ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTriage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Gửi Yêu Cầu", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
    );
  }
}
