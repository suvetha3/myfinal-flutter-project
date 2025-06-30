import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

import '../../provider/user_provider.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> attendanceList = [];
  String _selectedView = 'Day';


  bool _hasScanned = false;
  bool _isCheckOut = false;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final email = Provider.of<UserProvider>(context, listen: false).email;
    if (email == null || email.isEmpty) return;

    final attendanceCollection = FirebaseFirestore.instance.collection('attendance');

    if (_selectedView == 'Day') {
      final formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
      final docId = "$email-$formattedDate";

      final doc = await attendanceCollection.doc(docId).get();

      setState(() {
        attendanceList = doc.exists ? [doc.data()!..['date'] = formattedDate] : [];
      });
    } else {
      DateTime startDate;
      DateTime endDate;

      if (_selectedView == 'Week') {
        final weekDay = selectedDate.weekday;
        startDate = selectedDate.subtract(Duration(days: weekDay - 1)); // Monday
        endDate = selectedDate.add(Duration(days: 7 - weekDay)); // Sunday
      } else {
        // Month
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      }

      final snapshot = await attendanceCollection
          .where('employeeId', isEqualTo: email)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final docDateStr = doc.data()['date'];
        if (docDateStr == null) return false;
        final docDate = DateFormat('dd-MM-yyyy').parse(docDateStr);
        return docDate.isAtSameMomentAs(startDate) ||
            (docDate.isAfter(startDate) && docDate.isBefore(endDate)) ||
            docDate.isAtSameMomentAs(endDate);
      }).map((doc) => doc.data()..['date'] = doc.data()['date']).toList();

      setState(() {
        attendanceList = filtered;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await fetchAttendance();
    }
  }

  void _scanQRCode(String email, {required bool isCheckOut}) {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User email not available.")),
      );
      return;
    }

    _hasScanned = false;
    _isCheckOut = isCheckOut;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCheckOut ? "Scan QR for Check-Out" : "Scan QR for Check-In"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (BarcodeCapture capture) async {
              if (_hasScanned) return;
              _hasScanned = true;

              final code = capture.barcodes.first.rawValue;
              if (code != null && context.mounted) {
                Navigator.of(context).pop();
                await _onQRScanned(code, email, isCheckOut: isCheckOut);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onQRScanned(String qrCode, String email, {required bool isCheckOut}) async {
    try {
      final name = Provider.of<UserProvider>(context, listen: false).name ?? '';

      final decoded = jsonDecode(qrCode);
      final codeKey = decoded['key'];
      final date = decoded['date'];
      final locationName = decoded['location'];

      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      if (date != today) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This QR code is not valid for today.")),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('codes')
          .where('type', isEqualTo: 'companylocation')
          .where('key', isEqualTo: codeKey)
          .get();

      // print("Scanned QR: $qrCode");
      // print("Decoded Key: $codeKey, Date: $date, Location: $locationName");
      // print("Today: $today");

      if (codeKey == null || date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incomplete QR data.")),
        );
        return;
      }

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR code.")),
        );
        return;
      }

      final docData = snapshot.docs.first.data();
      final expectedLat = double.tryParse(docData['value'] ?? '');
      final expectedLon = double.tryParse(docData['flex1'] ?? '');

      if (expectedLat == null || expectedLon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid coordinates in QR code.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }

      final currentPosition = await Geolocator.getCurrentPosition();
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        expectedLat,
        expectedLon,
      );

      print("Expected Lat: $expectedLat, Lon: $expectedLon");
      print("Current Lat: ${currentPosition.latitude}, Lon: ${currentPosition.longitude}");
      print("Distance: $distance meters");

      if (distance > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not at the selected location.")),
        );
        return;
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('dd-MM-yyyy').format(now);
      final timeFormatted = DateFormat('hh:mm a').format(now);
      final docRef = FirebaseFirestore.instance.collection('attendance').doc('$email-$formattedDate');
      final doc = await docRef.get();

      if (!isCheckOut && doc.exists && (doc.data()?['checkInTime'] ?? '').toString().isNotEmpty) {
        final checkInTime = doc.data()?['checkInTime'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already checked in at $checkInTime")),
        );
        return;
      }

      if (isCheckOut) {
        if (!doc.exists || (doc.data()?['checkInTime'] ?? '').toString().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please check in before checking out.")),
          );
          return;
        }

        if ((doc.data()?['checkOutTime'] ?? '').toString().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Already checked out today.")),
          );
          return;
        }
      }

      if (isCheckOut) {
        await docRef.set({
          'checkOutTime': timeFormatted,
          'updatedBy': 'employee',
          'updatedOn': now.toIso8601String(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-out successful!")),
        );
      } else {
        await docRef.set({
          'employeeId': email,
          'employeeName': name,
          'date': formattedDate,
          'checkInTime': timeFormatted,
          'status': 'Present',
          'checkOutTime': '',
          'locationName': locationName,
          'createdBy': 'employee',
          'createdOn': now.toIso8601String(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-in successful!")),
        );
      }

      await fetchAttendance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Provider.of<UserProvider>(context).email ?? '';
    final formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _scanQRCode(email, isCheckOut: false),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Check-In (Scan QR)"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _scanQRCode(email, isCheckOut: true),
                  icon: const Icon(Icons.logout),
                  label: const Text("Check-Out (Scan QR)"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: ['Day', 'Week', 'Month'].map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _selectedView == option,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedView = option;
                      });
                      fetchAttendance();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Selected Date: $formattedDate", style: const TextStyle(fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Pick Date"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            attendanceList.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: attendanceList.length,
                itemBuilder: (context, index) {
                  final record = attendanceList[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                      title: Text("Date: ${record['date']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Check-In: ${record['checkInTime'] ?? '-'}"),
                          Text("Check-Out: ${record['checkOutTime'] ?? '-'}"),
                          Text("Status: ${record['status'] ?? '-'}"),
                          Text("Location: ${record['locationName'] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
                : const Text("No attendance data for selected date."),
          ],
        ),
      ),
    );
  }
}
