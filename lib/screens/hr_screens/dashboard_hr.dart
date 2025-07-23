import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/theme_provider.dart';
import '../../provider/user_provider.dart';
import '../../services/firestore_service.dart';

import '../../widgets/weather_card.dart';
import '../common_screens/calendar_view.dart';
import '../common_screens/chat_screen.dart';
import 'employee_master_screen.dart';
import 'attendance_master.dart';
import 'leave_master.dart';
import 'calendar_screen.dart';
import 'codes_page.dart';
import 'company_policies_screen.dart';
import '../common_screens/login_screen.dart';
import '../common_screens/profile_screen.dart';

class DashboardHr extends StatelessWidget {
  const DashboardHr({super.key});

  void logoutUser(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm != true) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await FirestoreService().updateLoginStatus(userProvider.email ?? '', false);
    userProvider.clearUser();
    Provider.of<ThemeProvider>(context, listen: false).setThemeMode(ThemeMode.system);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dashboardItems = [
      _DashboardItem('Employee Master', 'assets/employee.png', const EmployeeMasterScreen()),
      _DashboardItem('Attendance Master', 'assets/attendance.png', const AttendanceMasterScreen()),
      _DashboardItem('Leave Calendar', 'assets/calendar.png', const CalendarScreen()),
      _DashboardItem('Leave Master', 'assets/leave_apply.png', const LeaveMasterPage()),
      _DashboardItem('Code Master', 'assets/code.png', const CodesMaster()),
      _DashboardItem('Company Policies', 'assets/policies.png', const CompanyPolicyScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title:  Text('Welcome')),
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  const CircleAvatar(radius: 35, backgroundImage: AssetImage('assets/avatar.jpg')),
                  const SizedBox(height: 12),
                  Text(userProvider.name ?? 'No Name',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary)),
                  Text(userProvider.email ?? 'No Email',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.home, color: colorScheme.primary),
              title: Text('Home', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person, color: colorScheme.onSurface),
              title: Text('Profile', style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text('Logout', style: TextStyle(color: colorScheme.error)),
              onTap: () => logoutUser(context),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text('Select Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final currentMode = themeProvider.themeMode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.brightness_auto,
                            color: currentMode == ThemeMode.system ? colorScheme.primary : Colors.grey),
                        onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
                      ),
                      IconButton(
                        icon: Icon(Icons.light_mode,
                            color: currentMode == ThemeMode.light ? Colors.orange : Colors.grey),
                        onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                      IconButton(
                        icon: Icon(Icons.dark_mode,
                            color: currentMode == ThemeMode.dark ? Colors.blueGrey : Colors.grey),
                        onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const WeatherCard(),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Holiday Calendar', style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  CalendarViewWidget(
                    role: userProvider.role ?? 'N/A',
                    employeeEmail: userProvider.email ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...dashboardItems.map((item) => DashboardCard(
            title: item.title,
            asset: item.asset,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
          )),
        ],
      ),
      floatingActionButton: Tooltip(
        message: "How can I help you?",
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen()),
            );
          },
          backgroundColor: Colors.deepPurple,
          shape: const CircleBorder(),
          child: const Icon(Icons.smart_toy_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String asset;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(asset, height: 60, width: 60),
              const SizedBox(width: 20),
              Expanded(child: Text(title, style: textTheme.titleLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String asset;
  final Widget screen;

  _DashboardItem(this.title, this.asset, this.screen);
}
