import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../provider/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/pdf_generator.dart';
import 'generate_qr_screen.dart';

class AttendanceMasterScreen extends StatefulWidget {
  const AttendanceMasterScreen({super.key});

  @override
  State<AttendanceMasterScreen> createState() => _AttendanceMasterScreenState();
}

class _AttendanceMasterScreenState extends State<AttendanceMasterScreen> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  List<DateTime> getWeekDates(DateTime selectedDate) {
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<DateTime> getMonthDates(DateTime selectedDate) {
    final first = DateTime(selectedDate.year, selectedDate.month, 1);
    final last = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    return List.generate(last.day, (index) => first.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: "Generate QR",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GenerateMainBranchQRScreen(),
                ),
              );
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            onSelected: (value) async {
              final firestore = FirestoreService();
              final date = selectedDate;
              if (value == 'Daily') {
                final data = await firestore.getDailyAttendance(date);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PdfPreviewScreen(
                          buildPdf:
                              () => PdfGenerator.generateAttendancePdf(
                                title:
                                    'Daily Attendance (${DateFormat('dd-MM-yyyy').format(date)})',
                                data: data,
                              ),
                        ),
                  ),
                );
              } else if (value == 'Weekly') {
                final weekDates = getWeekDates(
                  selectedDate,
                );
                final allWeekData = await firestore.getDailyAttendanceForWeek(
                  weekDates,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PdfPreviewScreen(
                          buildPdf:
                              () => PdfGenerator.generateWeeklyAttendancePdf(
                                title:
                                    'Weekly Attendance (${DateFormat('dd-MM-yyyy').format(weekDates.first)} to ${DateFormat('dd-MM-yyyy').format(weekDates.last)})',
                                attendanceData: allWeekData,
                                weekDates: weekDates,
                              ),
                        ),
                  ),
                );
              } else if (value == 'Monthly') {
                final firestore = FirestoreService();
                final selected = selectedDate;
                final monthDates = List.generate(
                  DateTime(selected.year, selected.month + 1, 0).day,
                  (i) => DateTime(selected.year, selected.month, i + 1),
                );
                final data = await firestore.getMonthAttendance(selected);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PdfPreviewScreen(
                          buildPdf:
                              () => PdfGenerator.generateMonthlyAttendancePdf(
                                title:
                                    'Monthly Attendance (${DateFormat('MMMM yyyy').format(selected)})',
                                attendanceData: data,
                                monthDates: monthDates,
                              ),
                        ),
                  ),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'Daily',
                    child: Text('Export Daily'),
                  ),
                  const PopupMenuItem(
                    value: 'Weekly',
                    child: Text('Export Weekly'),
                  ),
                  const PopupMenuItem(
                    value: 'Monthly',
                    child: Text('Export Monthly'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd-MM-yyyy').format(selectedDate),
                  style: theme.textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Select Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.primaryContainer,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.secondaryContainer;
                      }
                      return null;
                    }),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Check In')),
                      DataColumn(label: Text('Check Out')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        users.map((userDoc) {
                          final user = userDoc.data() as Map<String, dynamic>;
                          final controller = AttendanceRowController(
                            userId: userDoc.id,
                            user: user,
                            selectedDate: selectedDate,
                          );
                          return DataRow(
                            cells: [
                              DataCell(Text(user['name'] ?? '')),
                              DataCell(
                                ChangeNotifierProvider.value(
                                  value: controller,
                                  child: const StatusCell(),
                                ),
                              ),
                              DataCell(
                                ChangeNotifierProvider.value(
                                  value: controller,
                                  child: const CheckInCell(),
                                ),
                              ),
                              DataCell(
                                ChangeNotifierProvider.value(
                                  value: controller,
                                  child: const CheckOutCell(),
                                ),
                              ),
                              DataCell(
                                ChangeNotifierProvider.value(
                                  value: controller,
                                  child: const ActionCell(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceRowController extends ChangeNotifier {
  final String userId;
  final Map<String, dynamic> user;
  final DateTime selectedDate;

  String status = '';
  TimeOfDay? checkIn;
  TimeOfDay? checkOut;
  bool isSaved = false;
  bool isEditable = true;

  late final String docId;

  late final StreamSubscription<DocumentSnapshot> _attendanceSubscription;

  AttendanceRowController({
    required this.userId,
    required this.user,
    required this.selectedDate,
  }) {
    docId = '${user['email']}-${DateFormat('dd-MM-yyyy').format(selectedDate)}';
    _loadData();
  }

  void _loadData() {
    _attendanceSubscription = FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            status = data['status'] ?? '';
            checkIn = _parseTime(data['checkInTime']);
            checkOut = _parseTime(data['checkOutTime']);
            isSaved = true;
            isEditable = false;
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _attendanceSubscription.cancel();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final dt = DateFormat.jm().parse(timeString);
    return TimeOfDay.fromDateTime(dt);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  void setStatus(String? newStatus) {
    if (newStatus != null) {
      status = newStatus;
      notifyListeners();
    }
  }

  void setCheckIn(TimeOfDay? time, BuildContext context) {
    if (checkOut != null && _isTimeAfter(time!, checkOut!)) {
      _showSnackbar(
        context,
        'Check-In time cannot be after Check-Out time. Resetting Check-In.',
      );
      checkIn = null;
    } else {
      checkIn = time;
    }
    notifyListeners();
  }

  void setCheckOut(TimeOfDay? time, BuildContext context) {
    if (checkIn != null && _isTimeAfter(checkIn!, time!)) {
      _showSnackbar(context, 'Check-Out time cannot be before Check-In time.');
      return;
    }
    checkOut = time;
    notifyListeners();
  }

  bool _isTimeAfter(TimeOfDay t1, TimeOfDay t2) {
    final dt1 = DateTime(0, 1, 1, t1.hour, t1.minute);
    final dt2 = DateTime(0, 1, 1, t2.hour, t2.minute);
    return dt1.isAfter(dt2);
  }

  void toggleEdit() {
    isEditable = true;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    final role = Provider.of<UserProvider>(context, listen: false).role;
    final data = {
      'employeeId': user['email'],
      'employeeName': user['name'],
      'status': status,
      'checkInTime': _formatTime(checkIn),
      'checkOutTime': _formatTime(checkOut),
      'date': DateFormat('dd-MM-yyyy').format(selectedDate),
      'createdBy': role,
      'createdOn': DateTime.now().toIso8601String(),
      'updatedBy': '',
      'updatedOn': '',
    };

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .set(data);
    isSaved = true;
    isEditable = false;
    notifyListeners();
    _showSnackbar(context, 'Attendance saved');
  }

  Future<void> update(BuildContext context) async {
    final role = Provider.of<UserProvider>(context, listen: false).role;
    final data = {
      'status': status,
      'checkInTime': _formatTime(checkIn),
      'checkOutTime': _formatTime(checkOut),
      'updatedBy': role,
      'updatedOn': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .update(data);
    isSaved = true;
    isEditable = false;
    notifyListeners();
    _showSnackbar(context, 'Attendance updated');
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class StatusCell extends StatelessWidget {
  const StatusCell({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AttendanceRowController>(
      builder: (context, ctrl, _) {
        return DropdownButton<String>(
          value:
              ['Present', 'Absent'].contains(ctrl.status) ? ctrl.status : null,
          onChanged: ctrl.isEditable ? ctrl.setStatus : null,
          hint: const Text('Select'),
          dropdownColor: colorScheme.surface,
          style: TextStyle(color: colorScheme.onSurface),
          iconEnabledColor: colorScheme.primary,
          items:
              ['Present', 'Absent']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
        );
      },
    );
  }
}

class CheckInCell extends StatelessWidget {
  const CheckInCell({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AttendanceRowController>(
      builder: (context, ctrl, _) {
        return GestureDetector(
          onTap:
              ctrl.isEditable
                  ? () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: ctrl.checkIn ?? TimeOfDay.now(),
                    );
                    if (time != null) ctrl.setCheckIn(time, context);
                  }
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ctrl.checkIn != null
                  ? MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(ctrl.checkIn!)
                  : 'Select',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        );
      },
    );
  }
}

class CheckOutCell extends StatelessWidget {
  const CheckOutCell({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AttendanceRowController>(
      builder: (context, ctrl, _) {
        return GestureDetector(
          onTap:
              ctrl.isEditable
                  ? () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: ctrl.checkOut ?? TimeOfDay.now(),
                    );
                    if (time != null) ctrl.setCheckOut(time, context);
                  }
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ctrl.checkOut != null
                  ? MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(ctrl.checkOut!)
                  : 'Select',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        );
      },
    );
  }
}

class ActionCell extends StatelessWidget {
  const ActionCell({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AttendanceRowController>(
      builder: (context, ctrl, _) {
        return Row(
          children: [
            if (!ctrl.isSaved)
              IconButton(
                icon: Icon(Icons.save, color: colorScheme.tertiary ),
                tooltip: 'Save',
                onPressed: () => ctrl.save(context),
              )
            else if (!ctrl.isEditable)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Edit',
                onPressed: ctrl.toggleEdit,
              )
            else
              IconButton(
                icon: Icon(Icons.update, color: colorScheme.secondary),
                tooltip: 'Update',
                onPressed: () => ctrl.update(context),
              ),
          ],
        );
      },
    );
  }
}


