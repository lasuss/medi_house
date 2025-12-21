import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PatientBooking extends StatefulWidget {
  const PatientBooking({Key? key}) : super(key: key);

  @override
  State<PatientBooking> createState() => _PatientBookingState();
}

class _PatientBookingState extends State<PatientBooking> {
  final SupabaseClient supabase = Supabase.instance.client;
  int _currentStep = 0;
  bool _isLoading = false;

  // Booking Data
  String? _selectedCategory; // 'dich_vu', 'bac_si', 'xet_nghiem'
  Map<String, dynamic>? _selectedItem; // The chosen doctor or service
  Map<String, dynamic>? _selectedProfile;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDoctors = [];

  // Data Lists
  List<Map<String, dynamic>> _availableServices = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
    _fetchProfiles();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _filteredDoctors = _doctors.where((d) {
        final name = (d['name'] ?? '').toLowerCase();
        final query = _searchController.text.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchBookingData() async {
    // Parallel fetch for speed
    final servicesRes = await supabase.from('medical_services').select();
    final doctorsRes = await supabase.from('users').select('id, name, doctor_info(specialty)').eq('role', 'doctor');

    if (mounted) {
      setState(() {
        _availableServices = List<Map<String, dynamic>>.from(servicesRes);
        _doctors = List<Map<String, dynamic>>.from(doctorsRes);
        _filteredDoctors = _doctors; // Init filtered list
      });
    }
  }

  Future<void> _fetchProfiles() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase.from('patient_profiles').select().eq('user_id', userId);
    if (mounted) {
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  // --- STEPS UI ---

  Widget _buildStep1_Selection() {
    if (_selectedCategory == null) {
      return Column(
        children: [
          _buildCategoryCard('Khám Dịch Vụ', Icons.medical_services, 'dich_vu'),
          _buildCategoryCard('Khám Theo Bác Sĩ', Icons.person_search, 'bac_si'),
          _buildCategoryCard('Xét Nghiệm', Icons.biotech, 'xet_nghiem'),
          _buildCategoryCard('Không biết khám khoa nào?', Icons.help_outline, 'triage', isHighlight: true),
        ],
      );
    }

    if (_selectedCategory == 'triage') {
       // This should trigger navigation, but for stepper logic we might need to handle it in onTap
       // See _buildCategoryCard modification below
       return const SizedBox.shrink(); 
    }

    if (_selectedCategory == 'dich_vu' || _selectedCategory == 'xet_nghiem') {
      final categoryFilter = _selectedCategory == 'xet_nghiem' ? 'Xét nghiệm' : 'Khám chuyên khoa';
      final list = _availableServices.where((e) => e['category'] == categoryFilter).toList();
      
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return Card(
            child: ListTile(
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("${NumberFormat('#,###').format(item['price'])}đ", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              onTap: () => setState(() => _selectedItem = item),
              selected: _selectedItem == item,
              selectedTileColor: Colors.blue.withOpacity(0.1),
            ),
          );
        },
      );
    }
    
    // Doctor Selection with Search
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm bác sĩ...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredDoctors.length,
          itemBuilder: (context, index) {
            final doc = _filteredDoctors[index];
            final info = doc['doctor_info'] ?? {};
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(doc['name'] ?? 'Bác sĩ'),
                subtitle: Text(info['specialty'] ?? 'Đa khoa'),
                onTap: () {
                  setState(() {
                    _selectedItem = doc;
                    // Add a dummy price for doctor consultation
                    _selectedItem!['price'] = 150000; 
                  });
                }, 
                selected: _selectedItem == doc,
                 selectedTileColor: Colors.blue.withOpacity(0.1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2_Profile() {
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('Bạn chưa có hồ sơ nào.'),
            TextButton(
              onPressed: () { 
                // Navigate to profile creation or handle inline
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng vào tab Hồ Sơ để tạo mới")));
              },
              child: const Text('Tạo hồ sơ ngay'),
            )
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final p = _profiles[index];
        return RadioListTile<Map<String, dynamic>>(
          title: Text(p['full_name']),
          subtitle: Text("${p['gender']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(p['dob']))}"),
          value: p,
          groupValue: _selectedProfile,
          onChanged: (val) => setState(() => _selectedProfile = val),
        );
      },
    );
  }

  Widget _buildStep3_DateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
              _selectedTime = null; // Reset time when date changes
            });
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Chọn giờ khám", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4_Confirm() {
    final price = _selectedItem?['price'] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _rowDetail('Hồ sơ', _selectedProfile?['full_name']),
            const Divider(),
            _rowDetail('Dịch vụ/Bác sĩ', _selectedItem?['name']),
            const SizedBox(height: 10),
            _rowDetail('Ngày khám', DateFormat('dd/MM/yyyy').format(_selectedDate)),
            _rowDetail('Giờ khám', _selectedTime ?? '--:--', isBold: true),
             const Divider(),
            _rowDetail('Phí khám', "${NumberFormat('#,###').format(price)}đ", isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5_Payment() {
    return Column(
      children: [
        const Text("Quét mã thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        // Placeholder QR
        Container(
          width: 200,
          height: 200,
          color: Colors.white,
          child: Center(
            child: Icon(Icons.qr_code_2, size: 180, color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Ngân hàng: Vietcombank\nSTK: 0071000xxxx\nNội dung: MEDIHOUSE BOOKING", textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _bankIcon('VCB'),
            _bankIcon('Momo'),
            _bankIcon('ZaloPay'),
          ],
        )
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildCategoryCard(String title, IconData icon, String id, {bool isHighlight = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isHighlight ? Colors.orange[50] : Colors.white,
      shape: isHighlight 
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.withOpacity(0.5)))
          : null,
      child: ListTile(
        leading: Icon(icon, color: isHighlight ? Colors.orange[800] : Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isHighlight ? Colors.orange[900] : Colors.black)),
        onTap: () {
          if (id == 'triage') {
             context.push('/patient/triage');
          } else {
            setState(() {
              _selectedCategory = id;
              _selectedItem = null;
            });
          }
        },
        trailing: Icon(Icons.chevron_right, color: isHighlight ? Colors.orange[800] : Colors.grey),
      ),
    );
  }

  Widget _rowDetail(String label, String? value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value ?? '---', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
  
  Widget _bankIcon(String name) {
    return Chip(label: Text(name), backgroundColor: Colors.grey[200]);
  }

  Future<String?> _findAvailableDoctor(DateTime time) async {
    // 1. Get all doctors
    if (_doctors.isEmpty) return null;
    
    // Filter doctors by specialty if a service is selected
    List<Map<String, dynamic>> candidateDoctors = _doctors;
    
    if (_selectedCategory == 'dich_vu' && _selectedItem != null) {
      final serviceName = _selectedItem!['name'] as String;
      // Heuristic: Map Service Name to Specialty or assume doctors with matching specialty
      // For now, let's try to find doctors whose specialty matches the service category
      // Or we can try to matches service name partially. 
      // Example: Service "Khám Tim Mạch" -> Doctor Specialty "Tim Mạch"
      
      // Let's refine this: If we can't easily map, we might need to rely on 'category' from service
      final category = _selectedItem!['category'] as String?;
      
      // If we have a category like "Tim mạch", we can filter. 
      // Let's check if the doctor's specialty is contained in the service name or vice versa.
      
      candidateDoctors = _doctors.where((d) {
        final info = d['doctor_info'] ?? {};
        final specialty = (info['specialty'] as String?)?.toLowerCase() ?? '';
        
        if (specialty == 'general' || specialty == 'đa khoa') return true; // General doctors can do basic services? Maybe not.
        
        // Check match
        if (serviceName.toLowerCase().contains(specialty)) return true;
        
        return false; 
      }).toList();
      
      // Fallback: If no specialist found, maybe return all? No, that's dangerous.
      // If filter result is empty, maybe we should just keep it empty or fallback to General if appropriate.
      // Let's keep existing behavior if candidateDoctors becomes empty to avoid blocking, OR be strict.
      // User complaint implies we should be strict.
      if (candidateDoctors.isEmpty) {
         // Try to find "General" / "Đa khoa" doctors as fallback?
         candidateDoctors = _doctors.where((d) {
            final s = ((d['doctor_info']?['specialty'] as String?) ?? '').toLowerCase();
            return s == 'general' || s == 'đa khoa';
         }).toList();
      }
    }

    final allDoctorIds = candidateDoctors.map((d) => d['id'] as String).toList();
    if (allDoctorIds.isEmpty) return null;

    // 2. Get busy doctors at this time
    // Note: This is a simple exact match check. 
    // In production, you'd check time ranges (e.g. +/- 30 mins).
    final timeStr = time.toIso8601String();
    
    // We can't easily query "not in" with complex time logic in one go without a stored procedure 
    // or loading all appointments for that time.
    // Let's load appointments near this time.
    final response = await supabase
        .from('appointments')
        .select('doctor_id')
        .eq('date', timeStr); // Strict equality for now as we use slots
    
    final busyDoctorIds = List<Map<String, dynamic>>.from(response)
        .map((a) => a['doctor_id'] as String?)
        .where((id) => id != null)
        .toSet();

    // 3. Filter available
    final available = allDoctorIds.where((id) => !busyDoctorIds.contains(id)).toList();
    
    if (available.isEmpty) return null;
    
    // 4. Pick random or first
    available.shuffle();
    return available.first;
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final profileName = _selectedProfile?['full_name'] ?? 'Không xác định';
      final serviceName = _selectedItem?['name'] ?? 'Khám tổng quát';
      final notes = "Bệnh nhân: $profileName. Dịch vụ: $serviceName";
      
      // Combine Date and Time
      DateTime finalDateTime = _selectedDate;
      if (_selectedTime != null) {
        final parts = _selectedTime!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        finalDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
      }

      // Determine doctor_id
      String? doctorId;
      if (_selectedCategory == 'bac_si') {
        doctorId = _selectedItem?['id'];
      } else {
        // Auto-assign
        doctorId = await _findAvailableDoctor(finalDateTime);
        if (doctorId == null) {
           throw Exception("Không tìm thấy bác sĩ trống lịch vào giờ này. Vui lòng chọn giờ khác.");
        }
      }
      
      // 1. Create Record first
      final recordRes = await supabase.from('records').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'status': 'Pending',
        'notes': "Booking Init: $notes",
        'symptoms': _selectedCategory == 'dich_vu' ? serviceName : 'Khám theo yêu cầu'
      }).select().single();
      
      final recordId = recordRes['id'];

      // 2. Create Appointment linked to Record
      await supabase.from('appointments').insert({
        'patient_id': user.id, 
        'doctor_id': doctorId,
        'record_id': recordId, // Linked!
        'date': finalDateTime.toIso8601String(), 
        'status': 'Pending',
        'type': _selectedCategory,
        'notes': notes,
        'time_slot': _selectedTime, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đặt lịch thành công!")));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/patient/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lịch Khám'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: _buildLeading(),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedItem == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn dịch vụ hoặc bác sĩ")));
            return;
          }
          if (_currentStep == 1 && _selectedProfile == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn hồ sơ bệnh nhân")));
            return;
          }
          if (_currentStep == 2 && _selectedTime == null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn giờ khám")));
             return;
          }
          
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            _submitBooking();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient/dashboard');
            }
          }
        },
        controlsBuilder: (context, details) {
           return Padding(
             padding: const EdgeInsets.only(top: 20),
             child: Row(
               children: [
                 Expanded(
                   child: ElevatedButton(
                     onPressed: details.onStepContinue,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                     ),
                     child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 4 ? 'Hoàn Tất' : 'Tiếp Tục', style: const TextStyle(color: Colors.white, fontSize: 16)),
                   ),
                 ),
                 if (_currentStep > 0) ...[
                   const SizedBox(width: 10),
                   TextButton(
                     onPressed: details.onStepCancel,
                     child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
                   ),
                 ]
               ],
             ),
           );
        },
        steps: [
          Step(title: const Text('Chọn'), content: _buildStep1_Selection(), isActive: _currentStep >= 0, state: _currentStep > 0 ? StepState.complete : StepState.editing),
          Step(title: const Text('Hồ sơ'), content: _buildStep2_Profile(), isActive: _currentStep >= 1, state: _currentStep > 1 ? StepState.complete : StepState.editing),
          Step(title: const Text('Giờ'), content: _buildStep3_DateTime(), isActive: _currentStep >= 2, state: _currentStep > 2 ? StepState.complete : StepState.editing),
          Step(title: const Text('Xác nhận'), content: _buildStep4_Confirm(), isActive: _currentStep >= 3, state: _currentStep > 3 ? StepState.complete : StepState.editing),
          Step(title: const Text('Thanh toán'), content: _buildStep5_Payment(), isActive: _currentStep >= 4, state: StepState.editing),
        ],
      ),
    );
  }

  Widget? _buildLeading() {
    if (_selectedCategory != null && _currentStep == 0) {
      return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() {
        _selectedCategory = null; 
        _selectedItem = null;
      }));
    }
    return IconButton(
      icon: const Icon(Icons.close), 
      onPressed: () {
        if (context.canPop()) {
           context.pop();
        } else {
           context.go('/patient/dashboard');
        }
      },
    );
  }
}
