enum UserRole {
  patient,
  doctor,
  pharmacy,
  admin,
  receptionist;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'patient':
        return UserRole.patient;
      case 'doctor':
        return UserRole.doctor;
      case 'pharmacy':
        return UserRole.pharmacy;
      case 'admin':
        return UserRole.admin;
      case 'receptionist':
        return UserRole.receptionist;
      default:
        return UserRole.patient;
    }
  }
}
