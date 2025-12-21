import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medi_house/enroll/UserRole.dart';

/// Lớp để chứa thông tin cho mỗi mục điều hướng.
class NavigationItemConfig {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItemConfig({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Cấu hình các mục điều hướng cho từng vai trò người dùng.
///
/// `AppShell` sẽ sử dụng Map này để lấy đúng danh sách các mục cần hiển thị
/// dựa trên vai trò của người dùng hiện tại.
final Map<UserRole, List<NavigationItemConfig>> navigationConfigs = {
  UserRole.patient: [
    const NavigationItemConfig(icon: FontAwesomeIcons.houseMedical, label: 'Trang chủ', route: '/patient/dashboard'),
    const NavigationItemConfig(icon: FontAwesomeIcons.idCard, label: 'Hồ sơ', route: '/patient/appointments'),
    const NavigationItemConfig(icon: FontAwesomeIcons.commentDots, label: 'Tin nhắn', route: '/patient/messages'),
    const NavigationItemConfig(icon: FontAwesomeIcons.solidBell, label: 'Thông báo', route: '/patient/notifications'),
    const NavigationItemConfig(icon: FontAwesomeIcons.solidUser, label: 'Tài khoản', route: '/patient/profile'),
  ],
  UserRole.doctor: [
    const NavigationItemConfig(icon: FontAwesomeIcons.chartLine, label: 'Dashboard', route: '/doctor/dashboard'),
    const NavigationItemConfig(icon: FontAwesomeIcons.calendarDays, label: 'Lịch làm việc', route: '/doctor/schedule'),
    const NavigationItemConfig(icon: FontAwesomeIcons.commentMedical, label: 'Tin nhắn', route: '/doctor/messages'),
    const NavigationItemConfig(icon: FontAwesomeIcons.solidBell, label: 'Thông báo', route: '/doctor/notifications'),
    const NavigationItemConfig(icon: FontAwesomeIcons.userDoctor, label: 'Tài khoản', route: '/doctor/profile'),
  ],
  UserRole.pharmacy: [
    const NavigationItemConfig(icon: FontAwesomeIcons.clockRotateLeft, label: 'Chờ xử lý', route: '/pharmacy/pending'),
    const NavigationItemConfig(icon: FontAwesomeIcons.checkDouble, label: 'Đã giao', route: '/pharmacy/filled'),
    const NavigationItemConfig(icon: FontAwesomeIcons.boxesStacked, label: 'Kho thuốc', route: '/pharmacy/inventory'),
  ],
  UserRole.admin: [
    const NavigationItemConfig(icon: FontAwesomeIcons.chartPie, label: 'Dashboard', route: '/admin/dashboard'),
    const NavigationItemConfig(icon: FontAwesomeIcons.usersGear, label: 'Người dùng', route: '/admin/users'),
  ],
  UserRole.receptionist: [
    const NavigationItemConfig(icon: FontAwesomeIcons.clipboardList, label: 'Phân loại', route: '/receptionist/dashboard'),
    const NavigationItemConfig(icon: FontAwesomeIcons.userGear, label: 'Tài khoản', route: '/receptionist/profile'),
  ],
};


class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItemConfig> navItems; // Nhận vào một danh sách các mục

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.navItems, // Bắt buộc phải có
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // BottomNavigationBar yêu cầu phải có ít nhất 2 mục.
    // Nếu có ít hơn 2 mục, ta sẽ không hiển thị thanh điều hướng.
    if (navItems.length < 2) {
      return const SizedBox.shrink(); // Trả về một widget trống
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey[400],
      onTap: (index) {
        // Điều hướng đến route của mục được chọn
        context.go(navItems[index].route);
      },
      // Tạo các mục một cách linh hoạt từ danh sách được cung cấp
      items: navItems.map((item) {
        return BottomNavigationBarItem(
          icon: FaIcon(item.icon, size: 20),
          label: item.label,
        );
      }).toList(),
    );
  }
}
