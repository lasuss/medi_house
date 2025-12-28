import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Widget chính hiển thị dashboard của bệnh nhân
class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

// Trạng thái quản lý dữ liệu và giao diện dashboard bệnh nhân
class _PatientDashboardState extends State<PatientDashboard> {
  // Khởi tạo client Supabase
  final SupabaseClient supabase = Supabase.instance.client;
  // Tên bệnh nhân và url avatar
  String _patientName = 'Bệnh nhân';
  String? _avatarUrl;
  // Danh sách hồ sơ khám bệnh
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'Tất cả',
    'Kết quả khám bệnh',
    'Kết quả xét nghiệm',
    'Đơn thuốc'
  ];
  String _selectedFilter = 'Tất cả';


  @override
  // Khởi tạo trạng thái: lấy dữ liệu khi widget được tạo
  void initState() {
    super.initState();
    _fetchData();
  }

  // Lấy dữ liệu dashboard: thông tin người dùng và danh sách hồ sơ khám
  Future<void> _fetchData() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Lấy tên và avatar của người dùng hiện tại
      final userRes = await supabase.from('users').select('name, avatar_url').eq('id', userId).single();
      _patientName = userRes['name'] ?? 'Bệnh nhân';
      _avatarUrl = userRes['avatar_url'];

      // Lấy danh sách hồ sơ khám (records) kèm thông tin bác sĩ, lịch hẹn và đơn thuốc
      final recordsRes = await supabase
          .from('records')
          .select('*, doctor:doctor_id(id, name), appointments(*), prescriptions(*)')
          .eq('patient_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(recordsRes);
          _filterRecords(); // Initially filter records
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper để phân loại records dựa trên prescriptions và appointments
  String _getRecordType(Map<String, dynamic> record) {
    // Kiểm tra xem có đơn thuốc không
    final prescriptions = record['prescriptions'];
    if (prescriptions != null && (prescriptions is List) && prescriptions.isNotEmpty) {
      return 'Đơn thuốc';
    }

    // Kiểm tra loại appointment
    final appointments = record['appointments'];
    if (appointments != null && (appointments is List) && appointments.isNotEmpty) {
      final apptType = appointments[0]['type'];
      if (apptType == 'xet_nghiem') {
        return 'Kết quả xét nghiệm';
      } else if (apptType == 'dich_vu' || apptType == 'bac_si') {
        return 'Kết quả khám bệnh';
      }
    }

    // Fallback heuristics based on content
    final symptoms = (record['symptoms'] as String? ?? '').toLowerCase();
    final diagnosis = (record['diagnosis'] as String? ?? '').toLowerCase();
    final notes = (record['notes'] as String? ?? '').toLowerCase();

    if (symptoms.contains('xét nghiệm') || diagnosis.contains('xét nghiệm') || notes.contains('xét nghiệm')) {
      return 'Kết quả xét nghiệm';
    }

    return 'Kết quả khám bệnh';
  }

  // Logic lọc records
  void _filterRecords() {
    if (_selectedFilter == 'Tất cả') {
      _filteredRecords = List<Map<String, dynamic>>.from(_records);
    } else {
      _filteredRecords = _records.where((record) {
        return _getRecordType(record) == _selectedFilter;
      }).toList();
    }
  }


  @override
  // Xây dựng giao diện chính của dashboard
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
              _buildSectionTitle('Kết quả khám và Xét nghiệm'),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 12),
              _buildRecordsList(),
            ],
          ),
        ),
      ),
      // Nút nổi để thêm hồ sơ khám mới
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/patient/records/add'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Xây dựng phần header chào mừng với tên và avatar bệnh nhân
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
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

  // Xây dựng tiêu đề phần nội dung
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

  // Widget for filter chips
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _filterRecords();
                });
              }
            },
            backgroundColor: Colors.white,
            selectedColor: Colors.blue.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.blue[800] : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_filteredRecords.isEmpty) {
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
                _selectedFilter == 'Tất cả'
                    ? 'Chưa có hồ sơ khám bệnh nào'
                    : 'Không tìm thấy kết quả cho "$_selectedFilter"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Danh sách các thẻ hồ sơ khám
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        final created = DateTime.parse(record['created_at']).toLocal();
        final doctorMap = record['doctor'];
        String doctorName = 'Bác sĩ';
        if (doctorMap != null && doctorMap is Map) {
          doctorName = doctorMap['name'] ?? 'Bác sĩ';
        }

        // Kiểm tra có đơn thuốc không
        final prescriptions = record['prescriptions'];
        final hasPrescription = prescriptions != null &&
            (prescriptions is List) &&
            prescriptions.isNotEmpty;

        // Xử lý hiển thị thời gian hẹn từ appointments
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

        // Xác định loại phiếu khám, icon và màu sắc tương ứng
        String typeDisplay = 'Phiếu khám';
        IconData icon = Icons.medical_services_outlined;
        Color iconColor = Colors.blue;
        String? doctorDisplay = doctorName;

        if (hasPrescription) {
          typeDisplay = 'Đơn thuốc';
          icon = Icons.medication_outlined;
          iconColor = Colors.green;
        } else if (appointments != null && (appointments is List) && appointments.isNotEmpty) {
          final apptType = appointments[0]['type'];
          if (apptType == 'xet_nghiem') {
            typeDisplay = 'Phiếu Xét Nghiệm';
            icon = Icons.biotech;
            iconColor = Colors.purple;
            doctorDisplay = null;
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

          final symptoms = (record['symptoms'] as String? ?? '').toLowerCase();
          if (symptoms.contains('xét nghiệm')) {
            typeDisplay = 'Kết quả xét nghiệm';
            icon = Icons.biotech;
            iconColor = Colors.purple;
          }
        }

        // Thẻ hiển thị một hồ sơ khám cụ thể
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
                              Flexible(
                                child: Text(
                                  typeDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Hiển thị badge trạng thái
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: record['status'] == 'Completed' ? Colors.green[50] :
                                         record['status'] == 'Prescribed' ? Colors.purple[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: record['status'] == 'Completed' ? Colors.green.withOpacity(0.3) :
                                             record['status'] == 'Prescribed' ? Colors.purple.withOpacity(0.3) : Colors.orange.withOpacity(0.3)
                                  ),
                                ),
                                child: Text(
                                  record['status'] == 'Completed' ? "Hoàn thành" :
                                  record['status'] == 'Prescribed' ? "Chờ cấp thuốc" : "Chưa giải quyết",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: record['status'] == 'Completed' ? Colors.green[700] :
                                             record['status'] == 'Prescribed' ? Colors.purple[700] : Colors.orange[700]
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Hiển thị tên bác sĩ nếu có
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
                          // Hiển thị số lượng thuốc nếu có đơn thuốc
                          if (hasPrescription) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.medical_services, size: 12, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${prescriptions.length} loại thuốc",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Hiển thị thông tin ngày giờ hẹn
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

                          // Hiển thị thời gian cập nhật cuối cùng
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