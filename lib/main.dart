import 'package:firebase_core/firebase_core.dart';
import 'package:medi_house/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/helpers/routers.dart';
import 'package:medi_house/helpers/UserManager.dart';
import 'package:medi_house/helpers/NotificationService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  await Supabase.initialize(
      url: 'https://hrsscqptpcfixkikbnxn.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhyc3NjcXB0cGNmaXhraWtibnhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3MzI1NzYsImV4cCI6MjA3OTMwODU3Nn0.QLdIXcuOqhEfGuq1XKccDfoonfHW7NXP5pnYnYlAd2s'
  );
  await UserManager.instance.loadUser();
  // Initialize Notification Service (background mostly, but good to init early)
  // We prefer doing this here or in AppShell. Doing here ensures it runs on startup.
  // Don't await this, so app starts even if notifications fail (common on Web without Service Worker).
  NotificationService().initialize().catchError((e) {
    debugPrint('NotificationService init failed: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MediHouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ).copyWith(
          background: const Color(0xFFF5F7FA),
          surface: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),

      routerConfig: MediRouter.router,
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
