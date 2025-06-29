import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/crud_service.dart';
import '../utils/pdf_generator.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CrudService _crud = CrudService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _holidays = [];

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  void _loadHolidays() {
    _crud.getItems('holidays').listen((items) {
      setState(() {
        _holidays = items;
      });
    });
  }

  Map<String, dynamic>? _getHoliday(DateTime day) {
    try {
      return _holidays.firstWhere((h) {
        final holidayDate = DateTime.parse(h['holidayDate']);
        return holidayDate.year == day.year &&
            holidayDate.month == day.month &&
            holidayDate.day == day.day;
      });
    } catch (e) {
      return null;
    }
  }

  int _getLeaveCountForMonth(DateTime month) {
    return _holidays.where((h) {
      final holidayDate = DateTime.parse(h['holidayDate']);
      return holidayDate.year == month.year && holidayDate.month == month.month;
    }).length;
  }

  void _showHolidayDialog(
    BuildContext context, {
    Map<String, dynamic>? holiday,
  }) {
    final nameCtrl = TextEditingController(text: holiday?['holidayName'] ?? '');
    final _formKey = GlobalKey<FormState>();
    DateTime selectedDate =
        holiday != null
            ? DateTime.parse(holiday['holidayDate'])
            : DateTime.now();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setInnerState) {
              return AlertDialog(
                title: Text(holiday != null ? 'Update Holiday' : 'Add Holiday'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          label: RequiredField('Holiday Name'),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a holiday name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Date: "),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(selectedDate),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final holidayData = {
                          'holidayName': nameCtrl.text.trim(),
                          'holidayDate': selectedDate.toIso8601String(),
                        };

                        if (holiday != null) {
                          await _crud.updateItem(
                            context: ctx,
                            collection: 'holidays',
                            id: holiday['id'],
                            data: holidayData,
                          );
                        } else {
                          await _crud.addItem(
                            context: ctx,
                            collection: 'holidays',
                            data: holidayData,
                          );
                        }
                        Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    child: Text(holiday != null ? 'Update' : 'Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveCount = _getLeaveCountForMonth(_focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Holiday Calendar",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export as PDF",
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                    buildPdf: () => PdfGenerator.generateHolidayPdf(
                title: 'Holidays List',
                data: _holidays,),),),
              );
            },
          ),
          SizedBox(width: 10,),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showHolidayDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate:
                    (day) =>
                        _selectedDay != null &&
                        day.year == _selectedDay!.year &&
                        day.month == _selectedDay!.month &&
                        day.day == _selectedDay!.day,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                holidayPredicate: (day) => _getHoliday(day) != null,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepPurple.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  holidayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onTertiary,
                    shape: BoxShape.circle,
                  ),
                  holidayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  weekendTextStyle:  TextStyle(color: Theme.of(context).colorScheme.error,),
                ),
                calendarBuilders: CalendarBuilders(
                  holidayBuilder: (context, day, focusedDay) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = focusedDay;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style:  TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Total Leaves in ${_focusedDay.month}-${_focusedDay.year}: $leaveCount",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Holiday List",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _holidays.isEmpty
                  ? const Center(child: Text("No holidays added yet."))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _holidays.length,
                    itemBuilder: (context, index) {
                      final holiday = _holidays[index];
                      final holidayDate = DateTime.parse(
                        holiday['holidayDate'],
                      );
                      final formattedDate = DateFormat('dd-MM-yyyy').format(holidayDate);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading:  Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(holiday['holidayName']),
                          subtitle: Text(formattedDate),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: "Edit Holiday",
                                 onPressed: () {
                                  _showHolidayDialog(
                                    context,
                                    holiday: holiday,
                                  );
                                },
                              ),
                              IconButton(
                                icon:  Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: "Delete Holiday",
                                onPressed: () async {
                                  final confirmDelete = await showDialog<
                                    bool
                                  >(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text("Delete Holiday"),
                                          content: const Text(
                                            "Are you sure you want to delete this holiday?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    ctx,
                                                    false,
                                                  ),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                                foregroundColor: Theme.of(context).colorScheme.onError,
                                              ),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    ctx,
                                                    true,
                                                  ),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirmDelete == true) {
                                    await _crud.deleteItem(
                                      collection: 'holidays',
                                      id: holiday['id'],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
