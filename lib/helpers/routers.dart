
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/Widgets/AppShell.dart';
import 'package:medi_house/Widgets/login.dart';
import 'package:medi_house/Widgets/register.dart';
import 'package:medi_house/enroll/UserRole.dart';
import 'package:medi_house/helpers/UserManager.dart';

// Admin Widgets
import 'package:medi_house/Widgets/admin/AdminDashboard.dart';

// Doctor Widgets
import 'package:medi_house/Widgets/doctor/DoctorDashboard.dart';
import 'package:medi_house/Widgets/doctor/DoctorMessages.dart';
import 'package:medi_house/Widgets/doctor/DoctorNotification.dart';
import 'package:medi_house/Widgets/doctor/DoctorProfile.dart';
import 'package:medi_house/Widgets/doctor/DoctorRecordDetail.dart';
import 'package:medi_house/Widgets/doctor/DoctorScanQR.dart';
import 'package:medi_house/Widgets/doctor/DoctorSchedule.dart';
import 'package:medi_house/Widgets/doctor/DoctorEditProfile.dart';
import 'package:medi_house/Widgets/doctor/DoctorScanNationalID.dart';
import 'package:medi_house/Widgets/doctor/DoctorHelpCenter.dart';

// Patient Widgets
import 'package:medi_house/Widgets/patient/PatientAddRecord.dart';
import 'package:medi_house/Widgets/patient/PatientAddRecord.dart';
import 'package:medi_house/Widgets/patient/PatientProfiles.dart'; // Replaces PatientAppointment
import 'package:medi_house/Widgets/patient/PatientBooking.dart';
import 'package:medi_house/Widgets/patient/PatientDashboard.dart';
import 'package:medi_house/Widgets/patient/PatientMessages.dart';
import 'package:medi_house/Widgets/patient/PatientNotification.dart';
import 'package:medi_house/Widgets/patient/PatientPersonalizeNotification.dart';
import 'package:medi_house/Widgets/patient/PatientProfile.dart';
import 'package:medi_house/Widgets/patient/PatientEditProfile.dart';
import 'package:medi_house/Widgets/patient/PatientRecordDetail.dart';
import 'package:medi_house/Widgets/patient/PatientScanNationalID.dart';
import 'package:medi_house/Widgets/patient/PatientShowQR.dart';
import 'package:medi_house/Widgets/patient/PatientHelpCenter.dart';
import 'package:medi_house/Widgets/patient/TermsOfService.dart';
import 'package:medi_house/Widgets/patient/PrivacyPolicy.dart';
import 'package:medi_house/Widgets/patient/PatientTriageForm.dart';

// Pharmacy Widgets
import 'package:medi_house/Widgets/admin/AdminDashboard.dart';
import 'package:medi_house/Widgets/admin/AdminUserManagement.dart';
import 'package:medi_house/Widgets/pharmacy/PharmacyFilled.dart';
import 'package:medi_house/Widgets/pharmacy/PharmacyInventory.dart';
import 'package:medi_house/Widgets/pharmacy/PharmacyPending.dart';

// Receptionist Widgets
import 'package:medi_house/Widgets/receptionist/ReceptionistDashboard.dart';
import 'package:medi_house/Widgets/receptionist/ReceptionistTriageDetail.dart';
import 'package:medi_house/Widgets/receptionist/ReceptionistProfile.dart';

class MediRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginPage(title: 'Đăng nhập'),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const RegisterPage(title: 'Đăng ký'),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                child: child,
              );
            },
          );
        },
      ),

      ShellRoute(
        pageBuilder: (context, state, child) {
          final String location = state.uri.toString();
          int currentIndex = 0;
          
          /// Patient Routes
          if (location.startsWith('/patient/dashboard')) {
            currentIndex = 0;
          } else if (location.startsWith('/patient/appointments')) {
            currentIndex = 1;
          } else if (location.startsWith('/patient/messages')) {
            currentIndex = 2;
          } else if (location.startsWith('/patient/notifications')) {
            currentIndex = 3;
          } else if (location.startsWith('/patient/profile')) {
            currentIndex = 4;
          }
          /// Doctor Routes
          else if (location.startsWith('/doctor/dashboard')) {
            currentIndex = 0;
          } else if (location.startsWith('/doctor/schedule')) {
            currentIndex = 1;
          } else if (location.startsWith('/doctor/messages')) {
            currentIndex = 2;
          } else if (location.startsWith('/doctor/notifications')) {
            currentIndex = 3;
          } else if (location.startsWith('/doctor/profile')) {
            currentIndex = 4;
          }
          /// Pharmacy Routes
          else if (location.startsWith('/pharmacy/pending')) {
            currentIndex = 0;
          } else if (location.startsWith('/pharmacy/filled')) {
            currentIndex = 1;
          } else if (location.startsWith('/pharmacy/inventory')) {
            currentIndex = 2;
          }
          /// Admin Routes
          else if (location.startsWith('/admin/dashboard')) {
            currentIndex = 0;
          } else if (location.startsWith('/admin/users')) {
            currentIndex = 1;
          }
          /// Receptionist Routes
          else if (location.startsWith('/receptionist/dashboard')) {
            currentIndex = 0;
          } else if (location.startsWith('/receptionist/profile')) {
            currentIndex = 1;
          }

          return NoTransitionPage(
            child: AppShell(
              currentIndex: currentIndex,
              child: child,
            ),
          );
        },
        routes: [
          /// --- Patient Routes ---
          GoRoute(
            path: '/patient/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: PatientDashboard()),
          ),
          GoRoute(
            path: '/patient/appointments',
            pageBuilder: (context, state) => const NoTransitionPage(child: PatientProfiles()),
          ),
          GoRoute(
            path: '/patient/booking',
            pageBuilder: (context, state) => const MaterialPage(child: PatientBooking(), fullscreenDialog: true),
          ),
          GoRoute(
            path: '/patient/triage',
            pageBuilder: (context, state) => const MaterialPage(child: PatientTriageForm(), fullscreenDialog: true),
          ),
          GoRoute(
            path: '/patient/messages',
            pageBuilder: (context, state) => const NoTransitionPage(child: PatientMessages()),
          ),
          GoRoute(
            path: '/patient/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: PatientProfile()),
              routes: [
                GoRoute(
                  path: 'personalize_notification',
                  pageBuilder: (context, state) => const MaterialPage(child: PatientPersonalizeNotification()),
                ),
                GoRoute(
                  path: 'edit',
                  pageBuilder: (context, state) => const MaterialPage(child: PatientEditProfile(), fullscreenDialog: true),
                ),
                GoRoute(
                  path: 'help_center',
                  pageBuilder: (context, state) => const MaterialPage(child: PatientHelpCenter()),
                  routes: [
                    GoRoute(
                      path: 'terms',
                      pageBuilder: (context, state) => const MaterialPage(child: TermsOfService()),
                    ),
                    GoRoute(
                      path: 'privacy',
                      pageBuilder: (context, state) => const MaterialPage(child: PrivacyPolicy()),
                    ),
                  ],
                ),
              ]
          ),
          GoRoute(
              path: '/patient/notifications',
              pageBuilder: (context, state) => const NoTransitionPage(child: PatientNotification()),

          ),

          GoRoute(
            path: '/patient/records/add',
            pageBuilder: (context, state) => const MaterialPage(child: PatientBooking(), fullscreenDialog: true), // Redirect old add record to new booking
          ),
          GoRoute(
            path: '/patient/records/:id',
            pageBuilder: (context, state) => MaterialPage(child: PatientRecordDetail(patientID: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/patient/show_qr',
            pageBuilder: (context, state) => const MaterialPage(child: PatientShowQR(), fullscreenDialog: true),
          ),
          /// --- Doctor Routes ---
          GoRoute(
            path: '/doctor/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorDashboard()),
          ),
          GoRoute(
            path: '/doctor/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorSchedule()),
          ),
          GoRoute(
            path: '/doctor/messages',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorMessages()),
          ),
          GoRoute(
            path: '/doctor/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorProfile()),
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => const MaterialPage(
                    child: DoctorEditProfile(),
                    fullscreenDialog: true
                ),
              ),
              GoRoute(
                path: 'help_center',
                pageBuilder: (context, state) => const MaterialPage(child: DoctorHelpCenter()),
                routes: [
                  GoRoute(
                    path: 'terms',
                    pageBuilder: (context, state) => const MaterialPage(child: TermsOfService()),
                  ),
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (context, state) => const MaterialPage(child: PrivacyPolicy()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/doctor/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorNotification()),
          ),
          GoRoute(
            path: '/doctor/records/:id',
            pageBuilder: (context, state) => MaterialPage(child: DoctorRecordDetail(title: 'Record ${state.pathParameters['id']}',  recordId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/doctor/scan_qr',
            pageBuilder: (context, state) => const MaterialPage(child: DoctorScanQR(), fullscreenDialog: true),
          ),

          /// --- Pharmacy Routes ---
          GoRoute(
            path: '/pharmacy/pending',
            pageBuilder: (context, state) => const NoTransitionPage(child: PharmacyPending()),
          ),
          GoRoute(
            path: '/pharmacy/filled',
            pageBuilder: (context, state) => const NoTransitionPage(child: PharmacyFilled()),
          ),
          GoRoute(
            path: '/pharmacy/inventory',
            pageBuilder: (context, state) => const NoTransitionPage(child: PharmacyInventory()),
          ),

          /// --- Admin Routes ---
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboard()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminUserManagement()),
          ),

          /// --- Receptionist Routes ---
          GoRoute(
            path: '/receptionist/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: ReceptionistDashboard()),
          ),
          GoRoute(
            path: '/receptionist/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ReceptionistProfile()),
          ),
          GoRoute(
            path: '/receptionist/triage/:id',
            pageBuilder: (context, state) => MaterialPage(child: ReceptionistTriageDetail(recordId: state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = UserManager.instance.isLoggedIn;
      final bool isLoggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/register';

      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) {
        final role = UserManager.instance.role;
        if (role == UserRole.patient) return '/patient/dashboard';
        if (role == UserRole.doctor) return '/doctor/dashboard';
        if (role == UserRole.pharmacy) return '/pharmacy/pending';
        if (role == UserRole.admin) return '/admin/dashboard';
        if (role == UserRole.receptionist) return '/receptionist/dashboard';
      }
      
      return null;
    },
    errorPageBuilder: (context, state) => const NoTransitionPage(
      child: Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      ),
    ),
  );
}
