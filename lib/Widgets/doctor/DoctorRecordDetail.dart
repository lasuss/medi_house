import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/doctor/DoctorRecordDetailEdit.dart';


class DoctorRecordDetail extends StatefulWidget {
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

class _DoctorRecordDetailState extends State<DoctorRecordDetail> {
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
            patient:patient_id (
              id,
              name
            )
          ''')
          .eq('id', widget.recordId)
          .single();

      // ===== PRESCRIPTION + ITEMS =====
      final prescriptionRes = await supabase
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String patientName =
    patient?['name'] != null && patient!['name'].toString().isNotEmpty
        ? patient!['name'].toString()
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Record Detail',
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
            // ===== Patient Info =====
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        patientName[0],
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
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
                          patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${patient?['id'] ?? '-'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ngày: ${record?['created_at']?.toString().split('T').first ?? '-'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                child: Text('No prescription'),
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
                          item['instructions'] ?? 'No instruction',
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
              'Doctor Notes',
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
                doctorNote ?? 'No instruction',
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
                label: const Text('Edit Record'),
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
}
