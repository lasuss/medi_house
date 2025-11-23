enum UserRole {
  patient,
  doctor,
  hospital,
  pharmacy,
  admin;

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
      case 'hospital':
        return UserRole.hospital;
      case 'pharmacy':
        return UserRole.pharmacy;
      case 'admin':
        return UserRole.admin;
      default:
        // Mặc định là patient, hoặc bạn có thể throw một exception
        // để báo lỗi nếu vai trò không hợp lệ.
        return UserRole.patient;
    }
  }
}
