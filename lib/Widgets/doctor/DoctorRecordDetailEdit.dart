import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DoctorRecordDetailEdit extends StatefulWidget { //Hiển thị chi tiết record để edit
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

  // Prescription Data
  List<Map<String, dynamic>> availableMedicines = [];
  List<Map<String, dynamic>> prescribedItems = []; // {medicine_id, medicine_name, unit, quantity, instructions}

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async { //Hàm tải dữ liệu
    try {
      // 1. Load Record
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

      // 2. Load Available Medicines
      final medicinesRes = await supabase
          .from('medicines')
          .select('id, name, unit, description')
          .order('name');

      // 3. Load Existing Prescriptions (if any)
      final existingPrescription = await supabase
          .from('prescriptions')
          .select('''
             id,
             prescription_items (
                medicine_id,
                quantity,
                instructions,
                medicine:medicine_id (name, unit, description)
             )
          ''')
          .eq('record_id', widget.recordId)
          .maybeSingle();

      List<Map<String, dynamic>> loadedItems = [];
      if (existingPrescription != null) {
        final items = List<Map<String, dynamic>>.from(existingPrescription['prescription_items']);
        for (var item in items) {
          loadedItems.add({
            'medicine_id': item['medicine_id'],
            'medicine_name': item['medicine']['name'],
            'unit': item['medicine']['unit'],
            'description': item['medicine']['description'],
            'quantity': item['quantity'],
            'instructions': item['instructions'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          record = recordRes;
          patient = recordRes['patient'];
          symptomsController.text = record?['symptoms'] ?? '';
          diagnosisController.text = record?['diagnosis'] ?? '';
          doctorNoteController.text = record?['notes'] ?? '';
          status = record?['status'] ?? 'pending';
          
          availableMedicines = List<Map<String, dynamic>>.from(medicinesRes);
          prescribedItems = loadedItems;
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _addOrUpdateMedicineItem(Map<String, dynamic> item) { //Hàm thêm hoặc cập nhật đơn thuốc
    setState(() {
      // Check if exists
      final index = prescribedItems.indexWhere((element) => element['medicine_id'] == item['medicine_id']);
      if (index >= 0) {
        prescribedItems[index] = item;
      } else {
        prescribedItems.add(item);
      }
    });
  }

  void _removeMedicineItem(int index) { //Hàm xóa đơn thuốc
    setState(() {
      prescribedItems.removeAt(index);
    });
  }

  void _showAddMedicineDialog() { //Hàm hiển thị dialog thêm đơn thuốc
    String? selectedMedicineId;
    Map<String, dynamic>? selectedMedicine;
    
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController instrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Thêm thuốc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return availableMedicines;
                        }
                        return availableMedicines.where((option) {
                          return option['name']
                              .toString()
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (option) => '${option['name']} (${option['unit']})',
                      onSelected: (selection) {
                         selectedMedicineId = selection['id'];
                         selectedMedicine = selection;
                         setStateDialog(() {});
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm thuốc',
                            hintText: 'Nhập tên thuốc...',
                            suffixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300), 
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      child: Text('${option['name']} (${option['unit']})'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(labelText: 'Số lượng', hintText: 'e.g., 10'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: instrController,
                      decoration: const InputDecoration(labelText: 'Hướng dẫn sử dụng', hintText: 'e.g., Uống sau ăn (After meals)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMedicineId != null && qtyController.text.isNotEmpty) {
                      _addOrUpdateMedicineItem({
                        'medicine_id': selectedMedicineId,
                        'medicine_name': selectedMedicine!['name'],
                        'unit': selectedMedicine!['unit'],
                        'description': selectedMedicine!['description'],
                        'quantity': int.tryParse(qtyController.text) ?? 1,
                        'instructions': instrController.text,
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecord() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final doctorId = UserManager.instance.supabaseUser?.id;

      // 1. Update Record
      await supabase.from('records').update({
        'symptoms': symptomsController.text,
        'diagnosis': diagnosisController.text,
        'status': status,
        'notes': doctorNoteController.text,
        'doctor_id': doctorId,
      }).eq('id', widget.recordId);


      // 2. Handle Prescription
      if (prescribedItems.isNotEmpty) {
        // Check if prescription already exists for this record
        final existingPrescription = await supabase
            .from('prescriptions')
            .select('id')
            .eq('record_id', widget.recordId)
            .maybeSingle();

        String prescriptionId;

        if (existingPrescription == null) {
          // Create new prescription
           final newPrescription = await supabase.from('prescriptions').insert({
             'record_id': widget.recordId,
             'doctor_id': doctorId,
             'patient_id': patient?['id'], 
             'status': 'Pending',
           }).select().single();
           prescriptionId = newPrescription['id'];
        } else {
           prescriptionId = existingPrescription['id'];
           // No need to update notes/instructions here anymore
        }

        // 3. Update Prescription Items (Delete all old, Insert new - simpler strategy)
        await supabase.from('prescription_items').delete().eq('prescription_id', prescriptionId);

        final itemsToInsert = prescribedItems.map((item) => {
          'prescription_id': prescriptionId,
          'medicine_id': item['medicine_id'],
          'quantity': item['quantity'],
          'instructions': item['instructions'],
        }).toList();

        if (itemsToInsert.isNotEmpty) {
           await supabase.from('prescription_items').insert(itemsToInsert);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hồ sơ và đơn thuốc đã được lưu thành công!')),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      debugPrint('Lỗi cập nhật hồ sơ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật hồ sơ.')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
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
  Widget build(BuildContext context) { //Hàm chính để dựng giao diện
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
        title: const Text('Chỉnh sửa hồ sơ'),
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

            // ===== Symptoms & Diagnosis =====
            _buildTextField(symptomsController, 'Triệu chứng (Symptoms)'),
            const SizedBox(height: 16),
            _buildTextField(diagnosisController, 'Chẩn đoán (Diagnosis)'),
            const SizedBox(height: 16),
            _buildTextField(doctorNoteController, 'Ghi chú của bác sĩ / Hướng dẫn chung'),
            const SizedBox(height: 20),

            // ===== Prescription Section (NEW) =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đơn thuốc',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
                ),
                TextButton.icon(
                    onPressed: _showAddMedicineDialog,
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    label: const Text('Thêm thuốc', style: TextStyle(color: Colors.blue)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: prescribedItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Chưa có loại thuốc nào được thêm.', style: TextStyle(color: Colors.grey))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prescribedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = prescribedItems[index];
                        return ListTile(
                          leading: const FaIcon(FontAwesomeIcons.pills, color: Colors.blue),
                          title: Text('${item['medicine_name']} (${item['quantity']} ${item['unit']})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['description'] != null)
                                Text(item['description'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              Text(item['instructions'] ?? ''),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeMedicineItem(index),
                          ),
                        );
                      },
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
              value: status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Pending',
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Chưa giải quyết')),
                DropdownMenuItem(value: 'Completed', child: Text('Hoàn thành')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => status = val);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                      backgroundColor: const Color(0xFF3182CE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text('Hủy', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Enter $label...',
          ),
        ),
      ],
    );
  }
}
