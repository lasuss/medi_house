
import 'package:medi_house/Widgets/model/Medicine.dart';

class Inventory { //Model Inventory quản lý tồn kho thuốc
  final String id;
  final String medicineId;
  final String? batchNumber;
  final int quantity;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final Medicine? medicine; // Joined data

  Inventory({ // Constructor khởi tạo đối tượng Inventory
    required this.id,
    required this.medicineId,
    this.batchNumber,
    required this.quantity,
    this.expiryDate,
    required this.createdAt,
    this.medicine,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) { //Factory constructor dùng để chuyển dữ liệu từ JSON sang object Inventory
    return Inventory(
      id: json['id'],
      medicineId: json['medicine_id'],
      batchNumber: json['batch_number'],
      quantity: json['quantity'] ?? 0,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      medicine: json['medicines'] != null ? Medicine.fromJson(json['medicines']) : null,
    );
  }

  Map<String, dynamic> toJson() { //Chuyển object Inventory thành JSON để gửi lên server
    return {
      'medicine_id': medicineId,
      'batch_number': batchNumber,
      'quantity': quantity,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}
