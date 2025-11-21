import 'package:go_router/go_router.dart';


class MediRouter {
  // static final GoRouter router = GoRouter(
  //   initialLocation: '/profile', // Start at the login screen
  //   routes: [
  //     // A single ShellRoute wraps all pages that should display within the Dashboard frame.
  //     ShellRoute(
  //       pageBuilder: (context, state, child) {
  //         final String location = state.uri.toString();
  //         int currentIndex;
  //
  //         // Determine the currentIndex based on the route. This index is used
  //         // by the Dashboard to configure the AppBar title and BottomNavBar.
  //         if (location.startsWith('/home')) {
  //           currentIndex = 0;
  //         } else if (location.startsWith('/notifications')) {
  //           currentIndex = 1;
  //         } else if (location.startsWith('/checkin')) {
  //           currentIndex = 2;
  //         } else if (location.startsWith('/profile')) {
  //           currentIndex = 3;
  //         } else if (location.startsWith('/login')) {
  //           currentIndex = 4; // Special index for Login
  //         } else if (location.startsWith('/register')) {
  //           currentIndex = 5; // Special index for Register
  //         } else {
  //           currentIndex = 0; // Default to home
  //         }
  //
  //         return NoTransitionPage(
  //           child: Dashboard(
  //             currentIndex: currentIndex,
  //             child: child,
  //           ),
  //         );
  //       },
  //       routes: [
  //         GoRoute(
  //           path: '/home',
  //           pageBuilder: (context, state) =>
  //           const NoTransitionPage(child: HomePage()),
  //         ),
  //         GoRoute(
  //           path: '/notifications',
  //           pageBuilder: (context, state) =>
  //           const NoTransitionPage(child: NotificationsPage()),
  //         ),
  //         GoRoute(
  //           path: '/checkin',
  //           pageBuilder: (context, state) =>
  //           const NoTransitionPage(child: CheckinPage()),
  //         ),
  //         GoRoute(
  //           path: '/profile',
  //           pageBuilder: (context, state) =>
  //           const NoTransitionPage(child: ProfilePage(title: 'Tài khoản')),
  //         ),
  //         GoRoute(
  //           path: '/login',
  //           pageBuilder: (context, state) {
  //             return CustomTransitionPage<void>(
  //               key: state.pageKey,
  //               child: const LoginPage(title: 'Đăng nhập'),
  //               transitionsBuilder:
  //                   (context, animation, secondaryAnimation, child) {
  //                 return FadeTransition(
  //                   opacity: CurveTween(curve: Curves.easeInOutCirc)
  //                       .animate(animation),
  //                   child: child,
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //         GoRoute(
  //           path: '/register',
  //           pageBuilder: (context, state) {
  //             return CustomTransitionPage<void>(
  //               key: state.pageKey,
  //               child: const RegisterPage(title: 'Đăng ký'),
  //               transitionsBuilder:
  //                   (context, animation, secondaryAnimation, child) {
  //                 return FadeTransition(
  //                   opacity: CurveTween(curve: Curves.easeInOutCirc)
  //                       .animate(animation),
  //                   child: child,
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   ],
  //   // errorPageBuilder: (context, state) => const Scaffold(
  //   //   body: Center(
  //   //     child: Text('Page not found'),
  //   //   ),
  //   // ),
  // );
}