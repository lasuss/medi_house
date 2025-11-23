import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:medi_house/menus/bottom_navigation.dart';

class AppShell extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {

  /// Xác định vai trò của người dùng dựa trên đường dẫn URL hiện tại.
  /// Đây là một giải pháp tạm thời để xây dựng giao diện.
  /// Trong thực tế, bạn nên lấy vai trò từ state quản lý đăng nhập (ví dụ: Provider, Bloc).
  UserRole _getRoleFromLocation(String location) {
    if (location.startsWith('/doctor')) return UserRole.doctor;
    if (location.startsWith('/pharmacy')) return UserRole.pharmacy;
    if (location.startsWith('/admin')) return UserRole.admin;
    if (location.startsWith('/hospital')) return UserRole.hospital;
    // Mặc định là patient cho các route còn lại trong shell
    return UserRole.patient;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đường dẫn hiện tại để xác định vai trò
    final String location = GoRouterState.of(context).uri.toString();
    final UserRole currentUserRole = _getRoleFromLocation(location);

    // Lấy danh sách các mục điều hướng cho vai trò hiện tại
    final List<NavigationItemConfig> navItems = navigationConfigs[currentUserRole] ?? [];

    // Tự động lấy tiêu đề từ mục điều hướng đang được chọn
    final String title = (navItems.isNotEmpty && widget.currentIndex < navItems.length)
        ? navItems[widget.currentIndex].label
        : 'MediHouse'; // Một tiêu đề mặc định hợp lý

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Một màu nền sáng và sạch sẽ
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          title, // Sử dụng tiêu đề động
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Điều hướng về trang đăng nhập khi đăng xuất.
              context.go('/login');
            },
          ),
        ],
      ),
      body: widget.child,
      // drawer: const MainDrawer(), // Bạn có thể thêm Drawer ở đây sau
      bottomNavigationBar: BottomNavigation(
        currentIndex: widget.currentIndex,
        navItems: navItems, // Truyền danh sách navItems động vào đây
      ),
    );
  }
}
