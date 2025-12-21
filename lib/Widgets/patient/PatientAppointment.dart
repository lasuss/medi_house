import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PatientAppointment extends StatefulWidget {
  const PatientAppointment({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientAppointment> createState() => _PatientAppointmentState();
}

class _PatientAppointmentState extends State<PatientAppointment> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<String> _allSpecialties = ["Tất cả"];
  
  String selectedSpecialty = "Tất cả";
  bool showTodayOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    searchController.addListener(_filterDoctors);
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, name, email, avatar_url, doctor_info(specialty, rating, reviews_count)')
          .eq('role', 'doctor');

      final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(response);
      
      // Flatten the data structure
      final List<Map<String, dynamic>> data = rawData.map((user) {
         final info = user['doctor_info'] != null ? (user['doctor_info'] as Map<String, dynamic>) : {};
         return {
           'id': user['id'],
           'name': user['name'],
           'email': user['email'],
           'avatar_url': user['avatar_url'],
           'specialty': info['specialty'] ?? 'Đa khoa',
           'rating': info['rating'] ?? 5.0,
           'reviews_count': info['reviews_count'] ?? 0,
         };
      }).toList();

      if (mounted) {
        setState(() {
          _allDoctors = data;
          _filteredDoctors = data;
          _extractUniqueSpecialties();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _extractUniqueSpecialties() {
    final Set<String> specialties = <String>{};
    for (var doc in _allDoctors) {
      if (doc['specialty'] != null) {
        specialties.add(doc['specialty'].toString());
      }
    }
    _allSpecialties = ["Tất cả", ...specialties.toList()..sort()];
  }

  void _filterDoctors() {
    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final name = doctor['name']?.toString().toLowerCase() ?? '';
        final specialty = doctor['specialty']?.toString().toLowerCase() ?? '';

        final matchesSearch = name.contains(query) || specialty.contains(query);
        final matchesSpecialty = selectedSpecialty == "Tất cả" || doctor['specialty'] == selectedSpecialty;
        
        // Note: 'availableToday' logic would require checking schedules table, skipping for MVP
        
        return matchesSearch && matchesSpecialty;
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Fetches booked slots for a specific doctor on a specific date
  Future<List<String>> _getBookedSlots(String doctorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await supabase
        .from('appointments')
        .select('time_slot')
        .eq('doctor_id', doctorId)
        .gte('date', startOfDay.toIso8601String())
        .lt('date', endOfDay.toIso8601String());

    return (response as List).map((e) => e['time_slot'] as String).toList();
  }

  void _showBookingDialog(Map<String, dynamic> doctor) {
    DateTime selectedDate = DateTime.now();
    String? selectedTime;
    List<String> bookedSlots = [];
    bool loadingSlots = false;

    // Standard business hours
    final List<String> allTimeSlots = [
      "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00",
      "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          // Helper to fetch slots when date changes
          void fetchSlots() async {
            setStateDialog(() => loadingSlots = true);
            final booked = await _getBookedSlots(doctor['id'], selectedDate);
            if (context.mounted) {
              setStateDialog(() {
                bookedSlots = booked;
                loadingSlots = false;
                selectedTime = null; // Reset selection
              });
            }
          }

          // Initial fetch
          if (loadingSlots == false && bookedSlots.isEmpty && selectedTime == null) {
             // Hacky way to trigger only once or we can pass a future builder
             // checks if we haven't fetched yet for today
          }

          // We'll use a user-triggered refresh for simplicity or fetch immediately on init
          // For this implementation, let's fetch immediately
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Đặt lịch: ${doctor['name'] ?? 'Bác sĩ'}", textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Text("${_getSpecialtyDisplay(doctor['specialty'])} • MediHouse", style: const TextStyle(color: Colors.grey)), // Added static location
                     const SizedBox(height: 10),
                     const Text("Chọn ngày khám", style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     CalendarDatePicker(
                       initialDate: selectedDate,
                       firstDate: DateTime.now(),
                       lastDate: DateTime.now().add(const Duration(days: 30)),
                       onDateChanged: (date) {
                         setStateDialog(() {
                           selectedDate = date;
                           selectedTime = null;
                         });
                         fetchSlots();
                       },
                     ),
                     const Divider(),
                     const Text("Khung giờ trống", style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     
                     FutureBuilder<List<String>>(
                       future: _getBookedSlots(doctor['id'], selectedDate),
                       builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) {
                           return const Center(child: CircularProgressIndicator());
                         }
                         
                         final booked = snapshot.data ?? [];
                         final availableSlots = allTimeSlots.where((slot) => !booked.contains(slot)).toList();

                         if (availableSlots.isEmpty) {
                           return const Text("Hết chỗ ngày này", style: TextStyle(color: Colors.red));
                         }

                         return Wrap(
                           spacing: 8,
                           children: availableSlots.map((time) {
                             return ChoiceChip(
                               label: Text(time),
                               selected: selectedTime == time,
                               onSelected: (val) {
                                 setStateDialog(() => selectedTime = val ? time : null);
                               },
                               selectedColor: Colors.blue,
                               labelStyle: TextStyle(color: selectedTime == time ? Colors.white : Colors.black),
                             );
                           }).toList(),
                         );
                       },
                     )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
              ElevatedButton(
                onPressed: selectedTime == null ? null : () async {
                  await _confirmBooking(doctor, selectedDate, selectedTime!);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Xác nhận"),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmBooking(Map<String, dynamic> doctor, DateTime date, String time) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Create timestamp for the appointment date
      final appointmentDate = DateTime(date.year, date.month, date.day);
      
      await supabase.from('appointments').insert({
        'patient_id': userId,
        'doctor_id': doctor['id'],
        'date': appointmentDate.toIso8601String(),
        'time_slot': time,
        'status': 'Pending',
        'type': 'Khám tổng quát' // Default
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt lịch thành công lúc $time!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đặt lịch: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm bác sĩ, chuyên khoa...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(selectedSpecialty), 
                    selected: selectedSpecialty != "Tất cả",
                    onSelected: (val) {
                      // Logic to pick specialty
                      showModalBottomSheet(context: context, builder: (_) {
                        return ListView(
                          children: _allSpecialties.map((s) => ListTile(
                            title: Text(s),
                            onTap: () {
                              setState(() {
                                selectedSpecialty = s;
                                _filterDoctors();
                              });
                              Navigator.pop(context);
                            },
                          )).toList(),
                        );
                      });
                    },
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredDoctors.isEmpty 
                  ? const Center(child: Text("Không tìm thấy bác sĩ nào"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        return DoctorCard(
                          doctor: _filteredDoctors[index],
                          onBook: () => _showBookingDialog(_filteredDoctors[index]),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30, 
                backgroundImage: doctor['avatar_url'] != null 
                    ? NetworkImage(doctor['avatar_url']) 
                    : null,
                child: doctor['avatar_url'] == null 
                    ? const Icon(Icons.person, size: 30) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor['name'] ?? 'Bác sĩ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text("${_getSpecialtyDisplay(doctor['specialty'] ?? 'Đa khoa')} • MediHouse Hospital", style: const TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(" ${doctor['rating'] ?? 5.0} (${doctor['reviews_count'] ?? 0} đánh giá)", style: const TextStyle(color: Colors.grey)),
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

String _getSpecialtyDisplay(String? specialty) {
  if (specialty == null) return 'Đa khoa';
  switch (specialty) {
    case 'General': return 'Đa khoa';
    case 'Cardiology': return 'Tim mạch';
    case 'Dermatology': return 'Da liễu';
    case 'Neurology': return 'Thần kinh';
    case 'Pediatrics': return 'Nhi khoa';
    case 'Dentistry': return 'Nha khoa';
    default: return specialty;
  }
}