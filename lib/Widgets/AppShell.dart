import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:medi_house/menus/bottom_navigation.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
  UserRole _getRoleFromLocation(String location) {
    if (location.startsWith('/doctor')) return UserRole.doctor;
    if (location.startsWith('/pharmacy')) return UserRole.pharmacy;
    if (location.startsWith('/admin')) return UserRole.admin;
    if (location.startsWith('/receptionist')) return UserRole.receptionist;
    return UserRole.patient;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đường dẫn hiện tại để xác định vai trò
    final String location = GoRouterState.of(context).uri.toString();
    final UserRole currentUserRole = _getRoleFromLocation(location);

    // Lấy danh sách các mục điều hướng cho vai trò hiện tại
    final List<NavigationItemConfig> navItems = navigationConfigs[currentUserRole] ?? [];

    // Tiêu đề mặc định nếu không tìm thấy cấu hình
    final String title = (navItems.isNotEmpty && widget.currentIndex < navItems.length)
        ? navItems[widget.currentIndex].label
        : 'MediHouse';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
            top: Radius.circular(10),

        )),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xff2196F3),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          title,
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
              UserManager().clearUser();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SizedBox.expand(
        child: widget.child,
      ),
      // drawer: const MainDrawer(), // Để dành cho việc mở rộng sau này
      bottomNavigationBar: BottomNavigation(
        currentIndex: widget.currentIndex,
        navItems: navItems, // Menu điều hướng dưới cùng
      ),
    );
  }
}
