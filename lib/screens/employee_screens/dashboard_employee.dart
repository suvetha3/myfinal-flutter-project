import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';
import '../../provider/user_provider.dart';
import '../../services/firestore_service.dart';

import '../../widgets/weather_card.dart';
import 'attendance_view.dart';
import 'employee_leave_status.dart';
import 'leave_request_page.dart';
import '../common_screens/login_screen.dart';
import 'policies_screen.dart';
import '../common_screens/profile_screen.dart';
import '../common_screens/calendar_view.dart';

class DashboardItem {
  final String title;
  final String asset;
  final Widget screen;

  DashboardItem({required this.title, required this.asset, required this.screen});
}

class DashboardEmployee extends StatelessWidget {
  const DashboardEmployee({super.key});

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

    final List<DashboardItem> dashboardItems = [
      DashboardItem(title: 'My Profile', asset: 'assets/profile.png', screen: const ProfileScreen()),
      DashboardItem(title: 'My Attendance', asset: 'assets/attendance.png', screen: const MyAttendanceScreen()),
      DashboardItem(title: 'Apply Leaves', asset: 'assets/leave_apply.png', screen: LeaveRequestForm()),
      DashboardItem(title: 'My Leaves', asset: 'assets/leave.png', screen: LeaveStatusScreen()),
      DashboardItem(title: 'Policies', asset: 'assets/policies.png', screen: const PoliciesScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
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
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('assets/avatar.jpg'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userProvider.name ?? 'No Name',
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
                  ),
                  Text(
                    userProvider.email ?? 'No Email',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.home, color: colorScheme.primary),
              title: Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              onTap: () => Navigator.pop(context), // Already on dashboard
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
            child: Padding(
              padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 20),
          ...dashboardItems.map((item) => DashboardTile(
            title: item.title,
            asset: item.asset,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
          )),
        ],
      ),
    );
  }
}

class DashboardTile extends StatelessWidget {
  final String title;
  final String asset;
  final VoidCallback onTap;

  const DashboardTile({
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
