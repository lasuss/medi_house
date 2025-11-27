class Appointment {
  final String id;
  final String? patientId;
  final String? doctorId;
  final DateTime? date;
  final String? status;

  Appointment({required this.id, this.patientId, this.doctorId, this.date, this.status});

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      status: json['status'],
    );
  }
}