import 'package:flutter/material.dart';
import 'package:crimereport/screens/splash_screen.dart';
import 'package:crimereport/screens/supabase_init.dart';
import 'package:crimereport/screens/student_dashboard.dart';
import 'package:crimereport/screens/course_registration.dart';
import 'package:crimereport/screens/attendance_history.dart';
import 'package:crimereport/screens/monitoring.dart';
import 'package:crimereport/screens/qr_generation.dart';
import 'package:crimereport/screens/course_details.dart';
import 'package:crimereport/screens/role_based.dart';
import 'package:crimereport/screens/lecturer_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const AttendanceApp());
}
class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Report Crimes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash',
      
      // Define static routes
      routes: {
        '/splash': (context) => SplashScreen(),
        '/role': (context) => RoleSelectionScreen(),
        //lecturer's route
        '/lecturer_dashboard': (context) => AdminDashboard(),
        '/monitoring': (context) => ReportTrackingScreen(),
        '/qr_generation': (context) => LecturerProfileScreen(),
        '/course': (context) => AdminReportManagementScreen(),
        //student's route
        '/courses': (context) => CrimeReportScreen(),
        '/history': (context) => ReportTracking(),
      },
      
      // Handle dynamic routes (e.g., passing user data)
      onGenerateRoute: (settings) {
        if (settings.name == '/student_dashboard') {
          final userData = settings.arguments as Map<String, dynamic>?; 
          return MaterialPageRoute(
            builder: (context) => UserDashboard(userData: userData ?? {}),
          );
        }     


        return null; // Default case
      },
    );
  }
}
