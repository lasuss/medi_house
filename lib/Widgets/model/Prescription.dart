
import 'package:medi_house/Widgets/model/Medicine.dart';

class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String medicineId;
  final int quantity;
  final String? instructions;
  final DateTime createdAt;
  final Medicine? medicine;

  PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicineId,
    required this.quantity,
    this.instructions,
    required this.createdAt,
    this.medicine,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) { //Factory constructor dùng để chuyển dữ liệu từ JSON sang object PrescriptionItem
    return PrescriptionItem(
      id: json['id'] ?? '',
      prescriptionId: json['prescription_id'] ?? '',
      medicineId: json['medicine_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      instructions: json['instructions'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      medicine: json['medicines'] != null ? Medicine.fromJson(json['medicines']) : null,
    );
  }
}

class Prescription {
  final String id;
  final String? doctorId; // Nullable in DB
  final String? patientId; // Nullable in DB
  final DateTime createdAt;
  final String? doctorName; 
  final String? patientName;
  final String? status;
  final String? recordId;
  
  final List<PrescriptionItem> items;

  Prescription({
    required this.id,
    this.doctorId,
    this.patientId,
    required this.createdAt,
    this.doctorName,
    this.patientName,
    this.status,
    this.recordId,
    this.items = const [],
  });
  
  
  factory Prescription.fromJson(Map<String, dynamic> json) { //Factory constructor dùng để chuyển dữ liệu từ JSON sang object Prescription
    return Prescription(
      id: json['id'] ?? '', // Xử lý trường hợp ID có thể bị null nếu xảy ra lỗi khi kết nối
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      recordId: json['record_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      doctorName: json['doctors']?['name'],
      patientName: json['patients']?['name'],
      status: json['status'] ?? 'Pending', 
      items: (json['prescription_items'] as List<dynamic>?)
          ?.map((e) => PrescriptionItem.fromJson(e))
          .toList() ?? [],
    );
  }
}
