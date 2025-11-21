import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String _getTitle(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return 'Trang chủ';
      case 1:
        return 'Thông báo';
      case 2:
        return 'Check-in';
      case 3:
        return 'Tài khoản';
      case 4:
        return 'Đăng nhập';
      case 5:
        return 'Đăng ký';
      default:
        return 'UEH';
    }
  }

  @override
  Widget build(BuildContext context) {
    // bỏ các nút đăng xuất với menu ở widget login với  widget đăng ký
    final bool isAuthScreen = widget.currentIndex >= 4;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        // The leading icon (drawer menu) is hidden on auth screens.
        // An automatic back button will appear if possible (e.g., navigating from Login to Register).
        leading: isAuthScreen ? null : Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),),
        automaticallyImplyLeading: !isAuthScreen,
        title: Text(
          _getTitle(widget.currentIndex),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        // The logout button is hidden on auth screens.
        actions: isAuthScreen
            ? []
            : [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Navigate to the login screen on logout.
              context.go('/login');
            },
          ),
        ],
      ),
      body: widget.child,
      // The drawer and bottom navigation are hidden on auth screens.
      // drawer: isAuthScreen ? null : const UEHDrawer(),
      bottomNavigationBar: isAuthScreen
          ? null
          : BottomNavigation(currentIndex: widget.currentIndex),
    );
  }
}
