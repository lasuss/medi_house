enum UserRole {
  patient,
  doctor,
  pharmacy,
  admin,
  receptionist;

  /// Chuyển đổi một chuỗi String (lấy từ database) thành một giá trị enum UserRole.
  ///
  /// Điều này rất hữu ích khi bạn lấy dữ liệu vai trò từ Supabase,
  /// vốn thường được lưu dưới dạng text.
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
