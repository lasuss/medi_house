import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';

class DoctorRecordDetailEdit extends StatefulWidget {
  final String recordId;

  const DoctorRecordDetailEdit({Key? key, required this.recordId}) : super(key: key);

  @override
  State<DoctorRecordDetailEdit> createState() => _DoctorRecordDetailEditState();
}

class _DoctorRecordDetailEditState extends State<DoctorRecordDetailEdit> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isSaving = false;

  Map<String, dynamic>? record;
  Map<String, dynamic>? patient;

  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController doctorNoteController = TextEditingController();

  String status = 'pending';

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    try {
      final recordRes = await supabase
          .from('records')
          .select('''
            id,
            symptoms,
            diagnosis,
            status,
            notes,
            patient:patient_id (
              id,
              name
            )
          ''')
          .eq('id', widget.recordId)
          .single();

      setState(() {
        record = recordRes;
        patient = recordRes['patient'];
        symptomsController.text = record?['symptoms'] ?? '';
        diagnosisController.text = record?['diagnosis'] ?? '';
        doctorNoteController.text = record?['notes'] ?? '';
        status = record?['status'] ?? 'pending';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading record: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final doctorId = UserManager.instance.supabaseUser?.id;

      await supabase.from('records').update({
        'symptoms': symptomsController.text,
        'diagnosis': diagnosisController.text,
        'status': status, // pending / completed
        'notes': doctorNoteController.text,
        'doctor_id': doctorId,
      }).eq('id', widget.recordId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record updated successfully!')),
      );

      Navigator.pop(context, true); // trả về true để biết đã chỉnh sửa
    } catch (e) {
      debugPrint('Error saving record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update record')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    symptomsController.dispose();
    diagnosisController.dispose();
    doctorNoteController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: const Text('Edit Record'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        elevation: 0,
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      patientName[0],
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
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
                      Text('ID: ${patient?['id'] ?? '-'}',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ===== Symptoms =====
            const Text(
              'Symptoms',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            // ===== Diagnosis =====
            const Text(
              'Diagnosis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: diagnosisController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            // ===== Doctor Notes =====
            const Text(
              'Doctor Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: doctorNoteController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Enter doctor notes...',
              ),
            ),
            const SizedBox(height: 20),

            // ===== Status =====
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: status[0].toUpperCase() + status.substring(1),
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => status = val.toLowerCase());
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 30),

            // ===== Buttons =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
