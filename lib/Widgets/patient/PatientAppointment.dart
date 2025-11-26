import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Đặt lịch khám',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PatientAppointment(),
    );
  }
}

class PatientAppointment extends StatefulWidget {
  const PatientAppointment({super.key});

  @override
  State<PatientAppointment> createState() => _PatientAppointmentState();
}

class _PatientAppointmentState extends State<PatientAppointment> {
  int _selectedIndex = 1; // Tab Lịch hẹn

  final TextEditingController searchController = TextEditingController();
  String selectedSpecialty = "Tất cả";
  bool showTodayOnly = false;

  // Danh sách bác sĩ mẫu
  final List<Map<String, dynamic>> _allDoctors = [
    {
      "name": "BS. Nguyễn Văn An",
      "specialty": "Tim mạch",
      "clinic": "Bệnh viện Tim Tâm Đức",
      "rating": 4.9,
      "reviews": 189,
      "avatar": "https://i.pravatar.cc/150?img=1",
      "availableToday": true,
      "timeSlots": ["14:00", "14:30", "15:00", "15:30", "16:00"],
    },
    {
      "name": "BS. Trần Thị Lan",
      "specialty": "Da liễu",
      "clinic": "Phòng khám Da liễu Hoa Sen",
      "rating": 4.8,
      "reviews": 156,
      "avatar": "https://i.pravatar.cc/150?img=5",
      "availableToday": true,
      "timeSlots": ["09:00", "09:30", "10:00", "10:30", "11:00"],
    },
    {
      "name": "BS. Lê Minh Tuấn",
      "specialty": "Nhi khoa",
      "clinic": "Bệnh viện Nhi Đồng 2",
      "rating": 4.7,
      "reviews": 203,
      "avatar": "https://i.pravatar.cc/150?img=8",
      "availableToday": false,
      "timeSlots": ["08:00", "08:30", "14:00", "14:30"],
    },
    {
      "name": "BS. Phạm Thị Mai",
      "specialty": "Tâm thần",
      "clinic": "Trung tâm Tâm lý MindCare",
      "rating": 4.9,
      "reviews": 98,
      "avatar": "https://i.pravatar.cc/150?img=12",
      "availableToday": true,
      "timeSlots": ["13:00", "13:30", "16:00", "16:30"],
    },
    {
      "name": "BS. Hồ Văn Khánh",
      "specialty": "Tim mạch",
      "clinic": "Bệnh viện Chợ Rẫy",
      "rating": 4.6,
      "reviews": 312,
      "avatar": "https://i.pravatar.cc/150?img=15",
      "availableToday": false,
      "timeSlots": ["07:30", "08:00", "09:00"],
    },
  ];

  late List<Map<String, dynamic>> _filteredDoctors;
  late List<String> _allSpecialties; // New: To store unique specialties dynamically

  @override
  void initState() {
    super.initState();
    _extractUniqueSpecialties(); // New: Extract specialties from data
    _filteredDoctors = _allDoctors;
    searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // New: Method to dynamically extract unique specialties
  void _extractUniqueSpecialties() {
    final Set<String> specialties = <String>{};
    for (final Map<String, dynamic> doctor in _allDoctors) {
      if (doctor['specialty'] is String) {
        specialties.add(doctor['specialty'] as String);
      }
    }
    _allSpecialties = ["Tất cả", ...specialties.toList()..sort()];
  }

  void _filterDoctors() {
    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final matchesSearch = doctor['name'].toLowerCase().contains(query) ||
            doctor['specialty'].toLowerCase().contains(query) ||
            doctor['clinic'].toLowerCase().contains(query);

        final matchesSpecialty =
            selectedSpecialty == "Tất cả" || doctor['specialty'] == selectedSpecialty;

        final matchesToday = !showTodayOnly || doctor['availableToday'];

        return matchesSearch && matchesSpecialty && matchesToday;
      }).toList();
    });
  }

  // Hàm hiển thị dialog đặt lịch – Đã sửa lỗi tiềm ẩn về an toàn kiểu dữ liệu và tính data-driven
  void _showBookingDialog(Map<String, dynamic> doctor) {
    String? selectedTime;

    // Enhanced robustness for timeSlots data
    final List<String> availableTimeSlots =
    (doctor['timeSlots'] is List<dynamic>?) // Check if it's a list (can be null)
        ? (doctor['timeSlots'] as List<dynamic>)
        .map((dynamic item) => item.toString()) // Convert each item to String safely
        .toList()
        : <String>[]; // Default to an empty list if not a List or null

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Đặt lịch khám\n${doctor['name']}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "${doctor['specialty']} • ${doctor['clinic']}",
                style: const TextStyle(color: Color(0xFF757575)),
              ),
              const SizedBox(height: 20),
              const Text("Chọn khung giờ trống:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableTimeSlots.map<Widget>((String time) {
                  return ChoiceChip(
                    label: Text(time),
                    selected: selectedTime == time,
                    onSelected: (bool selected) {
                      setStateDialog(() {
                        selectedTime = selected ? time : null;
                      });
                    },
                    selectedColor: const Color(0xFF2196F3),
                    backgroundColor: const Color(0xFFEEEEEE),
                    labelStyle: TextStyle(
                      color: selectedTime == time ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
              onPressed: selectedTime == null
                  ? null
                  : () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Đặt lịch thành công!\n${doctor['name']} - $selectedTime",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bác sĩ'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.filter_list, color: Color(0xFF2196F3)),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm bác sĩ, chuyên khoa, phòng khám...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
                filled: true,
                fillColor: const Color(0xFFEEEEEE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Bộ lọc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _buildFilterChip("Tất cả bộ lọc", Icons.tune),
                  const SizedBox(width: 8),
                  _buildSpecialtyChip(), // Now uses data-driven specialties
                  const SizedBox(width: 8),
                  _buildTodayChip(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${_filteredDoctors.length} bác sĩ tìm thấy",
                style: const TextStyle(color: Color(0xFF757575)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách bác sĩ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredDoctors.length,
              itemBuilder: (_, int i) {
                final Map<String, dynamic> doc = _filteredDoctors[i];
                return DoctorCard(doctor: doc, onBook: () => _showBookingDialog(doc));
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: const Color(0xFF757575),
        onTap: (int i) => setState(() => _selectedIndex = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Lịch hẹn'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF2196F3)),
      label: Text(label),
      backgroundColor: const Color(0xFFEEEEEE),
      labelStyle: const TextStyle(color: Color(0xFF2196F3)),
    );
  }

  Widget _buildSpecialtyChip() {
    return FilterChip(
      label: Text(selectedSpecialty),
      selected: selectedSpecialty != "Tất cả",
      onSelected: (bool _) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext _) => Column(
            mainAxisSize: MainAxisSize.min,
            // New: Use _allSpecialties list derived from doctor data
            children: _allSpecialties
                .map<ListTile>((String e) => ListTile(
              title: Text(e),
              onTap: () {
                setState(() => selectedSpecialty = e);
                _filterDoctors();
                Navigator.pop(context);
              },
            ))
                .toList(),
          ),
        );
      },
      selectedColor: const Color(0xFF2196F3),
      labelStyle: TextStyle(color: selectedSpecialty != "Tất cả" ? Colors.white : const Color(0xFF2196F3)),
      backgroundColor: const Color(0xFFEEEEEE),
    );
  }

  Widget _buildTodayChip() {
    return FilterChip(
      label: const Text("Chỉ hôm nay"),
      selected: showTodayOnly,
      onSelected: (bool v) {
        setState(() => showTodayOnly = v);
        _filterDoctors();
      },
      selectedColor: const Color(0xFF2196F3),
      labelStyle: TextStyle(color: showTodayOnly ? Colors.white : const Color(0xFF2196F3)),
      backgroundColor: const Color(0xFFEEEEEE),
    );
  }
}

// Card bác sĩ
class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onBook;

  const DoctorCard({super.key, required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(doctor['avatar'].toString())),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(doctor['name'].toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text("${doctor['specialty']} • ${doctor['clinic']}", style: const TextStyle(color: Color(0xFF757575))),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(" ${doctor['rating']} (${doctor['reviews']} đánh giá)", style: const TextStyle(color: Color(0xFF757575))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Đặt lịch khám", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}