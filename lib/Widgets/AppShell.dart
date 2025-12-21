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
  /// Đây là một giải pháp tạm thời để xây dựng giao diện.
  /// Trong thực tế, bạn nên lấy vai trò từ state quản lý đăng nhập (ví dụ: Provider, Bloc).
  UserRole _getRoleFromLocation(String location) {
    if (location.startsWith('/doctor')) return UserRole.doctor;
    if (location.startsWith('/pharmacy')) return UserRole.pharmacy;
    if (location.startsWith('/admin')) return UserRole.admin;
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
          title, // Sử dụng tiêu đề động
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('notifications')
                .stream(primaryKey: ['id'])
                .eq('is_read', false)
                .order('created_at', ascending: false)
                .map((data) => data.map((json) => json).toList()),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.length;
              }
              
              return Stack(
                children: [
                   IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      final String location = GoRouterState.of(context).uri.toString();
           
                      if (location.startsWith('/doctor')) {
                         context.push('/doctor/notifications');
                      } else if (location.startsWith('/patient')) {
                         context.push('/patient/notifications');
                      } else {
                         // Default fall back or toast
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Điều hướng về trang đăng nhập khi đăng xuất.
              UserManager().clearUser();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SizedBox.expand(
        child: widget.child,
      ),
      // drawer: const MainDrawer(), // Bạn có thể thêm Drawer ở đây sau
      bottomNavigationBar: BottomNavigation(
        currentIndex: widget.currentIndex,
        navItems: navItems, // Truyền danh sách navItems động vào đây
      ),
    );
  }
}
