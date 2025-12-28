  import 'package:flutter/material.dart';
  import 'package:font_awesome_flutter/font_awesome_flutter.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:medi_house/Widgets/doctor/DoctorRecordDetailEdit.dart';


class DoctorRecordDetail extends StatefulWidget { //Hiển thị chi tiết record
  const DoctorRecordDetail({
    Key? key,
    this.title,
    required this.recordId,
  }) : super(key: key);

    final String? title;
    final String recordId;

    @override
    State<DoctorRecordDetail> createState() => _DoctorRecordDetailState();
  }

class _DoctorRecordDetailState extends State<DoctorRecordDetail> { //State của DoctorRecordDetail
  final supabase = Supabase.instance.client;

    bool isLoading = true;

    Map<String, dynamic>? record;
    Map<String, dynamic>? patient;
    List<Map<String, dynamic>> prescriptionItems = [];
    String? doctorNote;

    @override
    void initState() {
      super.initState();
      _loadRecordDetail();
    }

    Future<void> _loadRecordDetail() async {
      try {
        // ===== RECORD + PATIENT =====
        final recordRes = await supabase
            .from('records')
            .select('''
              id,
              diagnosis,
              symptoms,
              notes,
              created_at,
              triage_data,
              patient:patient_id (
                id,
                name
              ),
              appointment:appointments!record_id  (
                date
                )
            ''')
            .eq('id', widget.recordId)
            .single();

      // ===== PRESCRIPTION + ITEMS =====
      final prescriptionRes = await supabase //Lấy thông tin đơn thuốc
          .from('prescriptions')
          .select('''
            prescription_items (
              quantity,
              instructions,
              medicine:medicine_id (
                name,
                unit,
                description
              )
            )
          ''')
          .eq('record_id', widget.recordId)
          .maybeSingle();

        setState(() {
          record = recordRes;
          patient = recordRes['patient'];
          doctorNote = recordRes['notes'];
          prescriptionItems = List<Map<String, dynamic>>.from(
            prescriptionRes?['prescription_items'] ?? [],
          );
          isLoading = false;
        });
      } catch (e) {
        debugPrint('Load record detail error: $e');
        setState(() => isLoading = false);
      }
    }

    String _formatAppointmentDate(dynamic appointment) {
      if (appointment == null ||
          appointment is! Map ||
          appointment['date'] == null) {
        return '-';
      }

      final rawDate = appointment['date'];
      DateTime visitDate;

      if (rawDate is String) {
        visitDate = DateTime.parse(rawDate).toLocal();
      } else if (rawDate is int) {
        visitDate = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
      } else {
        return '-';
      }

      return '${visitDate.day.toString().padLeft(2, '0')}/'
          '${visitDate.month.toString().padLeft(2, '0')}/'
          '${visitDate.year} '
          '${visitDate.hour.toString().padLeft(2, '0')}:'
          '${visitDate.minute.toString().padLeft(2, '0')}';
    }


  @override
  Widget build(BuildContext context) { //Hàm chính để dựng giao diện
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String patientName = '-';
    if (record?['triage_data'] != null && record?['triage_data']['profile_name'] != null) {
      patientName = record!['triage_data']['profile_name'];
    } else {
         // Fallback logic
         final notes = record?['notes']?.toString() ?? '';
         if (notes.startsWith('Booking Init:')) {
           final RegExp nameExp = RegExp(r'Bệnh nhân: (.*?)\.');
           final match = nameExp.firstMatch(notes);
           if (match != null) {
             patientName = match.group(1)?.trim() ?? '-';
           }
         } else if (patient?['name'] != null) {
            patientName = patient!['name'].toString();
         }
    }

      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            widget.title ?? 'Chi tiết hồ sơ',
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ===== Patient Info Section (New Separate Field) =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: const [
                      Icon(Icons.person_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Thông tin bệnh nhân", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow("Họ tên", patientName),
                  const SizedBox(height: 12),
                  
                  if (record?['triage_data'] != null) ...[
                      Row(
                        children: [
                           Expanded(child: _buildDetailRow("Tuổi", "${record!['triage_data']['age'] ?? '-'} tuổi")),
                           Expanded(child: _buildDetailRow("Giới tính", "${record!['triage_data']['gender'] ?? '-'}")),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow("Địa chỉ", "${record!['triage_data']['address'] ?? '-'}"),
                  ] else ...[
                       _buildDetailRow("ID Bệnh nhân", "${patient?['id'] ?? '-'}"),
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 20),

              const SizedBox(height: 20),

              // ===== Diagnosis =====
              const Text(
                'Chẩn đoán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record?['diagnosis'] ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3182CE),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Triệu chứng: ${record?['symptoms'] ?? '-'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            // ===== Prescription =====
            const Text(
              'Đơn thuốc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: prescriptionItems.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Không có đơn thuốc'),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescriptionItems.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = prescriptionItems[index];

                    return ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.pills,
                        color: Colors.blue,
                        size: 20,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== Dòng 1 =====
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['medicine']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                '${item['quantity']} ${item['medicine']['unit']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // ===== Dòng 2: Description =====
                          if (item['medicine']['description'] != null)
                             Text(
                              item['medicine']['description'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 4),

                        // ===== Dòng 3: Instructions =====
                        Text(
                          item['instructions'] ?? 'Chưa có hướng dẫn sử dụng',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

              const SizedBox(height: 20),

            // ===== Doctor Notes =====
            const Text(
              'Dặn dò của bác sĩ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                doctorNote ?? 'Không có hướng dẫn',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF744210),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

              const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Push sang trang edit
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorRecordDetailEdit(recordId: widget.recordId),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      isLoading = true;
                    });
                    await _loadRecordDetail();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            ],
          ),
        ),
      );
    }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }
}
