import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class PdfGenerator {

  //holidays
  static Future<Uint8List> generateHolidayPdf({
    required String title,
    required List<Map<String, dynamic>> data,
  }) async {
    final pdf = pw.Document();

    final headers = ['S.No', 'Holiday Name', 'Date'];
    final rows = data.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final item = entry.value;
      final date = DateTime.parse(item['holidayDate']);
      final formattedDate =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
      return [i.toString(), item['holidayName'], formattedDate];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  //attendance
  static Future<Uint8List> generateAttendancePdf({
    required String title,
    required List<Map<String, dynamic>> data,
  }) async {
    final pdf = pw.Document();

    final headers = ['S.No', 'Employee Name', 'Status'];

    final rows = data.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final item = entry.value;
      final status = item['status'] ?? '-';
      return [i.toString(), item['employeeName'] ?? '-', status];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );
     return pdf.save();

  }

  //weekly
  static Future<Uint8List> generateWeeklyAttendancePdf({
    required String title,
    required List<Map<String, dynamic>> attendanceData,
    required List<DateTime> weekDates,
  }) async {
    final pdf = pw.Document();


    final employees = <String, String>{}; // email -> name
    for (var record in attendanceData) {
      employees[record['employeeId']] = record['employeeName'];
    }

    //headers
    final headers = ['S.No', 'Name'] +
        weekDates.map((date) => DateFormat('dd-MM-yy\n   EEE').format(date)).toList();


    final rows = employees.entries.map((entry) {
      final email = entry.key;
      final name = entry.value;

      final weekStatus = weekDates.map((date) {
        final formattedDate = DateFormat('dd-MM-yyyy').format(date);
        final day = date.weekday;


        final record = attendanceData.firstWhere(
              (item) => item['employeeId'] == email && item['date'] == formattedDate,
          orElse: () => {},
        );

        if (record.isNotEmpty) {
          return record['status'] ?? '-';
        } else if (day == DateTime.saturday || day == DateTime.sunday) {
          return 'Holiday';
        } else {
          return '-';
        }
      }).toList();

      return [
        (employees.keys.toList().indexOf(email) + 1).toString(),
        name,
        ...weekStatus,
      ];
    }).toList();


    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 9),
            cellAlignment: pw.Alignment.center,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );
    return pdf.save();

  }

  //monthly
  static Future<Uint8List> generateMonthlyAttendancePdf({
    required String title,
    required List<Map<String, dynamic>> attendanceData,
    required List<DateTime> monthDates,
  }) async {
    final pdf = pw.Document();


    final employees = <String, String>{};
    for (var record in attendanceData) {
      employees[record['employeeId']] = record['employeeName'];
    }

    //headers
    final headers = ['S.No', 'Name'] +
        monthDates.map((date) => DateFormat('dd').format(date)).toList();

    //rows
    final rows = employees.entries.map((entry) {
      final email = entry.key;
      final name = entry.value;

      final monthStatus = monthDates.map((date) {
        final formattedDate = DateFormat('dd-MM-yyyy').format(date);
        final day = date.weekday;

        final record = attendanceData.firstWhere(
              (item) => item['employeeId'] == email && item['date'] == formattedDate,
          orElse: () => {},
        );

        if (record.isNotEmpty) {
          final status = record['status'];
          if (status == 'Present') return 'P';
          if (status == 'Absent') return 'A';
          return '-';
        } else if (day == DateTime.saturday || day == DateTime.sunday) {
          return 'H'; // Weekend Holiday
        } else {
          return '-';
        }
      }).toList();

      return [
        (employees.keys.toList().indexOf(email) + 1).toString(),
        name,
        ...monthStatus,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 9),
            cellAlignment: pw.Alignment.center,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              pw.Text('Marked as: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('P - Present,  A - Absent,  H - Holiday,  -  Not Marked'),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

}


//preview screen
class PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() buildPdf;

  const PdfPreviewScreen({super.key, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: PdfPreview(
        build: (format) => buildPdf(),
        canChangeOrientation: true,
      ),
    );
  }
}