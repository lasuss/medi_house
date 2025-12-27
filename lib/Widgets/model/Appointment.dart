class Appointment {
  final String id;
  final String? patientId;
  final String? doctorId;
  final DateTime? date;
  final String? status;

  Appointment({required this.id, this.patientId, this.doctorId, this.date, this.status}); //Constructor khởi tạo đối tượng Appointment

  factory Appointment.fromJson(Map<String, dynamic> json) { //Factory constructor dùng để chuyển dữ liệu từ JSON sang object Appointment
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      status: json['status'],
    );
  }
}