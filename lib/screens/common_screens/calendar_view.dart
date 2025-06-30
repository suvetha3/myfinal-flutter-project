import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/crud_service.dart';

class CalendarViewWidget extends StatefulWidget {
  final String role;
  final String employeeEmail;

  const CalendarViewWidget({
    super.key,
    required this.role,
    required this.employeeEmail,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  final CrudService _crud = CrudService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _holidays = [];
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadHolidays();
    _loadLeaves();
  }

  void _loadHolidays() {
    _crud.getItems('holidays').listen((items) {
      if (mounted) {
        setState(() {
          _holidays = items;
        });
      }
    });
  }

  void _loadLeaves() {
    _crud.getItems('leaves').listen((items) {
      final filtered = items.where((leave) {
        final status = (leave['status'] ?? '').toString().toLowerCase();
        final email = (leave['email'] ?? '').toString().toLowerCase();
        final currentUserEmail = widget.employeeEmail.toLowerCase().trim();

        return (status == 'accepted' || status == 'approved') &&
            (widget.role.toLowerCase() == 'hr' || email == currentUserEmail);
      }).toList();

      if (mounted) {
        setState(() {
          _leaves = filtered;
        });
      }
    });
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    List<Map<String, String>> events = [];

    for (var holiday in _holidays) {
      DateTime? holidayDate = _convertToDate(holiday['holidayDate']);
      if (holidayDate != null && _isSameDay(holidayDate, day)) {
        events.add({
          'label': "Holiday: ${holiday['holidayName']}",
          'color': 'green',
        });
      }
    }

    for (var leave in _leaves) {
      String leaveType = leave['leaveType'] ?? 'Leave';
      String name = leave['name'] ?? leave['updatedBy'] ?? 'Unknown';

      DateTime? start = _convertToDate(leave['startDate']);
      DateTime? end = _convertToDate(leave['endDate']);
      DateTime? leaveOn = _convertToDate(leave['leaveOn']);
      DateTime? workedOn = _convertToDate(leave['workedOn']);

      if (start != null && end != null) {
        if (!day.isBefore(start) && !day.isAfter(end)) {
          events.add({
            'label': "$name - $leaveType",
            'color': 'orange',
          });
        }
      } else if (leaveOn != null && _isSameDay(leaveOn, day)) {
        events.add({
          'label': "$name - $leaveType",
          'color': 'orange',
        });
      } else if (workedOn != null && _isSameDay(workedOn, day)) {
        events.add({
          'label': "$name - $leaveType",
          'color': 'orange',
        });
      }
    }

    return events;
  }

  DateTime? _convertToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
          _selectedDay != null && _isSameDay(day, _selectedDay!),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final events = _getEventsForDay(day);

              Color? eventColor;
              String? eventType;
              if (events.isNotEmpty) {
                final colorKey = events.first['color'];
                eventType = colorKey;
                if (colorKey == 'green') eventColor = Theme.of(context).colorScheme.tertiary;
                if (colorKey == 'orange') eventColor = Theme.of(context).colorScheme.secondary;
              }

              final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              final isHoliday = eventType == 'green';

              return Container(
                height: 50,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHoliday
                            ? Colors.indigo
                            : isWeekend
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    if (events.isNotEmpty)
                      Text(
                        events.first['label']!.split(":").last.trim(),
                        style: TextStyle(
                          fontSize: 9,
                          color: eventColor ?? Colors.deepPurple,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.deepPurple.shade200,
              shape: BoxShape.circle,
            ),
            selectedDecoration:  BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            weekendTextStyle:  TextStyle(color: Theme.of(context).colorScheme.error,),
            defaultTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),

            outsideTextStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.grey,
            ),
            disabledTextStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white30
                  : Colors.grey.shade400,
            ),

          ),
        ),
        const SizedBox(height: 10),
        if (_selectedDay != null)
          ..._getEventsForDay(_selectedDay!).map((event) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              event['label'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: event['color'] == 'green'
                    ? Theme.of(context).colorScheme.tertiary
                    : event['color'] == 'indigo'
                    ? Colors.indigo
                    : Colors.black,
              ),
            ),
          )),
      ],
    );
  }
}
