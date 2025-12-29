import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// Widget chính cho màn hình đặt lịch khám đa bước của bệnh nhân
class PatientBooking extends StatefulWidget {
  const PatientBooking({Key? key}) : super(key: key);

  @override
  State<PatientBooking> createState() => _PatientBookingState();
}

// Trạng thái quản lý toàn bộ quy trình đặt lịch khám
class _PatientBookingState extends State<PatientBooking> {
  // Khởi tạo client Supabase
  final SupabaseClient supabase = Supabase.instance.client;
  // Bước hiện tại trong stepper và trạng thái loading
  int _currentStep = 0;
  bool _isLoading = false;

  // Dữ liệu đặt lịch
  String? _selectedCategory; // 'dich_vu', 'bac_si', 'xet_nghiem'
  Map<String, dynamic>? _selectedItem; // Dịch vụ hoặc bác sĩ được chọn
  Map<String, dynamic>? _selectedProfile; // Hồ sơ bệnh nhân được chọn
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  // Controller tìm kiếm và danh sách bác sĩ đã lọc
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDoctors = [];

  // Danh sách dữ liệu từ server
  List<Map<String, dynamic>> _availableServices = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _profiles = [];

  // Trạng thái quản lý các khung giờ bận
  Set<String> _busySlots = {};

  @override
  // Khởi tạo ban đầu: lấy dữ liệu đặt lịch, hồ sơ và lắng nghe tìm kiếm
  void initState() {
    super.initState();
    _fetchBookingData();
    _fetchProfiles();
    _searchController.addListener(_onSearchChanged);
    initializeDateFormatting('vi', null);
  }

  @override
  // Giải phóng tài nguyên khi widget bị hủy
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lọc danh sách bác sĩ theo từ khóa tìm kiếm
  void _onSearchChanged() {
    setState(() {
      _filteredDoctors = _doctors.where((d) {
        final name = (d['name'] ?? '').toLowerCase();
        final query = _searchController.text.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  // Lấy dữ liệu dịch vụ y tế và danh sách bác sĩ từ Supabase (song song để nhanh)
  Future<void> _fetchBookingData() async {
    final servicesRes = await supabase.from('medical_services').select();
    final doctorsRes = await supabase.from('users').select('id, name, doctor_info(specialty)').eq('role', 'doctor');

    if (mounted) {
      setState(() {
        _availableServices = List<Map<String, dynamic>>.from(servicesRes);
        _doctors = List<Map<String, dynamic>>.from(doctorsRes);
        _filteredDoctors = _doctors;
      });
    }
  }

  // Lấy danh sách hồ sơ bệnh nhân của người dùng hiện tại
  Future<void> _fetchProfiles() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase.from('patient_profiles').select().eq('user_id', userId);
    if (mounted) {
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  // Lấy danh sách các khung giờ bận cho ngày đã chọn
  Future<void> _fetchBusySlots() async {
    if (_doctors.isEmpty) return;

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    try {
      // 1. Lấy tất cả lịch hẹn trong ngày đó (bao gồm status để lọc)
      final res = await supabase
          .from('appointments')
          .select('time_slot, doctor_id, status')
          .gte('date', startOfDay.toIso8601String())
          .lte('date', endOfDay.toIso8601String());
      
      var appointments = List<Map<String, dynamic>>.from(res);

      // Lọc bỏ các lịch đã hủy hoặc từ chối
      appointments = appointments.where((a) {
        final status = a['status'] as String?;
        return status != 'Cancelled' && status != 'Rejected';
      }).toList();
      
      print("Found ${appointments.length} valid appointments for $_selectedDate"); // Debug log

      Set<String> busy = {};

      // 2. Nếu đã chọn bác sĩ cụ thể -> Chỉ lọc theo bác sĩ đó
      if (_selectedCategory == 'bac_si' && _selectedItem != null) {
        final doctorId = _selectedItem!['id'];
        final doctorAppts = appointments.where((a) => a['doctor_id'] == doctorId);
        busy = doctorAppts.map((a) => a['time_slot'] as String).toSet();
      } 
      // 3. Nếu chọn dịch vụ -> Phải kiểm tra 'candidate doctors'
      else if (_selectedCategory == 'dich_vu' && _selectedItem != null) {
        // Tìm các bác sĩ có thể làm dịch vụ này
        final serviceName = _selectedItem!['name'] as String;
        List<String> candidateIds = _doctors.where((d) {
           final info = d['doctor_info'] ?? {};
           final specialty = (info['specialty'] as String?)?.toLowerCase() ?? '';
           if (specialty == 'general' || specialty == 'đa khoa') return true;
           return serviceName.toLowerCase().contains(specialty);
        }).map((d) => d['id'] as String).toList();

        // Fallback nếu không có chuyên khoa phù hợp thì lấy đa khoa
        if (candidateIds.isEmpty) {
           candidateIds = _doctors.where((d) {
             final s = ((d['doctor_info']?['specialty'] as String?) ?? '').toLowerCase();
             return s == 'general' || s == 'đa khoa';
           }).map((d) => d['id'] as String).toList();
        }

        if (candidateIds.isNotEmpty) {
           // Mảng slots
           final allSlots = ['08:00', '09:00', '10:00', '11:00', '13:30', '14:30', '15:30', '16:30'];
           
           for (var slot in allSlots) {
             // Đếm số bác sĩ candidate đã bận ở slot này
             final busyCount = appointments.where((a) => a['time_slot'] == slot && candidateIds.contains(a['doctor_id'])).length;
             // Nếu tất cả candidate đều bận -> slot này bận
             if (busyCount >= candidateIds.length) {
               busy.add(slot);
             }
           }
        }
      }

      if (mounted) {
        setState(() {
          _busySlots = busy;
          // Nếu giờ đang chọn bị bận thì bỏ chọn
          if (_selectedTime != null && _busySlots.contains(_selectedTime)) {
             _selectedTime = null;
          }
        });
      }

    } catch (e) {
      debugPrint("Error fetching busy slots: $e");
    }
  }

  // Giao diện bước 1: Chọn loại đặt lịch (dịch vụ, bác sĩ, xét nghiệm) hoặc chọn cụ thể
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
      return const SizedBox.shrink();
    }

    // Hiển thị danh sách dịch vụ hoặc xét nghiệm tương ứng
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

    // Hiển thị danh sách bác sĩ kèm ô tìm kiếm
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
        Container(
          height: 400, // Limit height to approx 5 items
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _filteredDoctors.length,
            itemBuilder: (context, index) {
              final doc = _filteredDoctors[index];
              final info = doc['doctor_info'] ?? {};
              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(doc['name'] ?? 'Bác sĩ'),
                  subtitle: Text(info['specialty'] ?? 'Đa khoa'),
                  onTap: () {
                    setState(() {
                      _selectedItem = doc;
                      _selectedItem!['price'] = 150000;
                    });
                  },
                  selected: _selectedItem == doc,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Giao diện bước 2: Chọn hồ sơ bệnh nhân
  Widget _buildStep2_Profile() {
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('Bạn chưa có hồ sơ nào.'),
            TextButton(
              onPressed: () {
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

  // Giao diện bước 3: Chọn ngày và giờ khám
  Widget _buildStep3_DateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Localizations(
          locale: const Locale('vi', 'VN'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
                _selectedTime = null;
              });
              _fetchBusySlots();
            },
          ),
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
            final isBusy = _busySlots.contains(time);
            final isSelected = _selectedTime == time;
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: isBusy ? null : (selected) {
                setState(() => _selectedTime = selected ? time : null);
              },
              selectedColor: Colors.blue,
              disabledColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isBusy ? Colors.grey : Colors.black),
                decoration: isBusy ? TextDecoration.lineThrough : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Giao diện bước 4: Xác nhận thông tin đặt lịch
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

  // Giao diện bước 5: Hướng dẫn thanh toán (hiển thị QR và thông tin chuyển khoản)
  Widget _buildStep5_Payment() {
    return Column(
      children: [
        const Text("Quét mã thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
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

  // Widget thẻ chọn loại đặt lịch (dịch vụ, bác sĩ, xét nghiệm, triage)
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

  // Widget hiển thị một dòng thông tin chi tiết trong xác nhận
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

  // Widget chip hiển thị icon ngân hàng/thanh toán
  Widget _bankIcon(String name) {
    return Chip(label: Text(name), backgroundColor: Colors.grey[200]);
  }

  // Tìm bác sĩ trống lịch phù hợp (tự động phân bổ khi không chọn bác sĩ cụ thể)
  Future<String?> _findAvailableDoctor(DateTime time) async {
    if (_doctors.isEmpty) return null;

    List<Map<String, dynamic>> candidateDoctors = _doctors;

    // Lọc bác sĩ phù hợp với dịch vụ nếu chọn dịch vụ chuyên khoa
    if (_selectedCategory == 'dich_vu' && _selectedItem != null) {
      final serviceName = _selectedItem!['name'] as String;

      candidateDoctors = _doctors.where((d) {
        final info = d['doctor_info'] ?? {};
        final specialty = (info['specialty'] as String?)?.toLowerCase() ?? '';

        if (specialty == 'general' || specialty == 'đa khoa') return true;

        if (serviceName.toLowerCase().contains(specialty)) return true;

        return false;
      }).toList();

      // Fallback về bác sĩ đa khoa nếu không tìm thấy chuyên khoa phù hợp
      if (candidateDoctors.isEmpty) {
        candidateDoctors = _doctors.where((d) {
          final s = ((d['doctor_info']?['specialty'] as String?) ?? '').toLowerCase();
          return s == 'general' || s == 'đa khoa';
        }).toList();
      }
    }

    final allDoctorIds = candidateDoctors.map((d) => d['id'] as String).toList();
    if (allDoctorIds.isEmpty) return null;

    // Lấy danh sách bác sĩ đã có lịch tại thời điểm chọn
    final timeStr = time.toIso8601String();

    final response = await supabase
        .from('appointments')
        .select('doctor_id')
        .eq('date', timeStr);

    final busyDoctorIds = List<Map<String, dynamic>>.from(response)
        .map((a) => a['doctor_id'] as String?)
        .where((id) => id != null)
        .toSet();

    // Lọc ra bác sĩ còn trống
    final available = allDoctorIds.where((id) => !busyDoctorIds.contains(id)).toList();

    if (available.isEmpty) return null;

    // Chọn ngẫu nhiên một bác sĩ trống
    available.shuffle();
    return available.first;
  }

  // Thực hiện gửi dữ liệu đặt lịch lên server
  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final profileName = _selectedProfile?['full_name'] ?? 'Không xác định';
      final serviceName = _selectedItem?['name'] ?? 'Khám tổng quát';
      final notes = "Bệnh nhân: $profileName. Dịch vụ: $serviceName";

      // Kết hợp ngày và giờ thành datetime đầy đủ
      DateTime finalDateTime = _selectedDate;
      if (_selectedTime != null) {
        final parts = _selectedTime!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        finalDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
      }

      // Xác định doctor_id: nếu chọn bác sĩ cụ thể thì dùng, còn lại tự động phân bổ
      String? doctorId;
      if (_selectedCategory == 'bac_si') {
        doctorId = _selectedItem?['id'];
        
        // Final check to make sure the slot isn't busy before submitting?
        // (Optional, UI should handle this mostly)
      } else {
        doctorId = await _findAvailableDoctor(finalDateTime);
        if (doctorId == null) {
          throw Exception("Không tìm thấy bác sĩ trống lịch vào giờ này. Vui lòng chọn giờ khác.");
        }
      }

      // Prepare triage_data from selected profile
      Map<String, dynamic>? triageData;
      if (_selectedProfile != null) {
        final p = _selectedProfile!;
        int age = 0;
        if (p['dob'] != null) {
          try {
             final dob = DateTime.parse(p['dob']);
             age = DateTime.now().year - dob.year;
          } catch (_) {}
        }
        
        final addressParts = [
          p['address_street'], 
          p['address_ward'], 
          p['address_district'],
          p['address_province']
        ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

        triageData = {
          'profile_name': p['full_name'],
          'age': age,
          'gender': p['gender'],
          'address': addressParts,
          'profile_id': p['id']
        };
      }

      // Tạo bản ghi hồ sơ khám (records)
      final recordRes = await supabase.from('records').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'status': 'Pending',
        'notes': "Booking Init: $notes",
        'triage_data': triageData,
        'symptoms': _selectedCategory == 'dich_vu' ? serviceName : 'Khám theo yêu cầu'
      }).select().single();

      final recordId = recordRes['id'];

      // Tạo lịch hẹn (appointments) liên kết với record
      await supabase.from('appointments').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'record_id': recordId,
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
  // Xây dựng giao diện chính với Stepper dọc
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
          // Kiểm tra dữ liệu bắt buộc trước khi chuyển bước
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
            if (_currentStep == 2) {
              _fetchBusySlots();
            }
          } else {
            _submitBooking();
          }
        },
        onStepCancel: () {
          // Quay lại bước trước hoặc thoát màn hình
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
        // Tùy chỉnh nút điều khiển stepper
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
        // Danh sách các bước trong quy trình đặt lịch
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

  // Xử lý nút back/close trên AppBar tùy theo trạng thái hiện tại
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