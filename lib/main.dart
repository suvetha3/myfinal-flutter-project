import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalproject/provider/theme_provider.dart';
import 'package:finalproject/provider/user_provider.dart';
import 'package:finalproject/screens/employee_screens/dashboard_employee.dart';
import 'package:finalproject/screens/hr_screens/dashboard_hr.dart';
import 'package:finalproject/screens/common_screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance Management System',
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: Scaffold(
        body: FutureBuilder(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .where('isLogin', isEqualTo: true)
                  .limit(1)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading user'));
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final user = snapshot.data!.docs.first;
              final name = user['name'];
              final email = user['email'];
              final role = user['role'];

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                userProvider.updateUser(name: name, email: email, role: role);
              });

              // Navigate based on role
              if (role == 'Hr') return const DashboardHr();
              if (role == 'Employee') return const DashboardEmployee();
            }
              // If not logged in
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
