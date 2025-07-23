import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<Map<String, dynamic>?> getUserDataByEmail(String email) async {
    try {
      final checkEmail =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (checkEmail.docs.isNotEmpty) {
        return checkEmail.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateLoginStatus(String email, bool isLogin) async {
    try {
      final checkdata =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (checkdata.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(checkdata.docs.first.id)
            .update({'isLogin': isLogin});
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Failed to update login status: $e');
    }
  }

  Future<void> updateUserPassword(String email, String newPassword) async {
    final userRef =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (userRef.docs.isNotEmpty) {
      await _firestore.collection('users').doc(userRef.docs.first.id).update({
        'password': newPassword,
      });
    } else {
      throw Exception('User not found');
    }
  }

  Future<bool> checkLoginStatus() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('isLogin', isEqualTo: true)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<List<String>> getDropdownOptions(String fieldName) async {
    try {
      final snapshot =
          await _firestore
              .collection('codes')
              .where('type', isEqualTo: fieldName)
              .where('active', isEqualTo: true)
              .get();

      return snapshot.docs.map((doc) => doc['value'].toString()).toList();
    } catch (e) {
     // print('Error getting dropdown options for $fieldName: $e');
      return [];
    }
  }

  Future<void> removeDropdownOption(String type, String value) async {
    try {
      final snapshot =
          await _firestore
              .collection('codes')
              .where('type', isEqualTo: type)
              .where('value', isEqualTo: value)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        await _firestore
            .collection('codes')
            .doc(snapshot.docs.first.id)
            .delete();
      }
    } catch (e) {
      //print('Error removing option: $e');
      throw Exception('Failed to remove dropdown option');
    }
  }

  Future<void> editDropdownOption(
    String type,
    String oldValue,
    String newValue,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('codes')
              .where('type', isEqualTo: type)
              .where('value', isEqualTo: oldValue)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        await _firestore.collection('codes').doc(snapshot.docs.first.id).update(
          {'value': newValue},
        );
      }
    } catch (e) {
      //print('Error editing option: $e');
      throw Exception('Failed to edit dropdown option');
    }
  }

  //daily report
  Future<List<Map<String, dynamic>>> getDailyAttendance(DateTime date) async {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    final querySnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: formattedDate)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyAttendanceForWeek(List<DateTime> weekDates) async {
    List<Map<String, dynamic>> allData = [];
    for (var date in weekDates) {
      final dailyData = await getDailyAttendance(date);
      allData.addAll(dailyData);
    }
    return allData;
  }

  Future<List<Map<String, dynamic>>> getMonthAttendance(DateTime monthDate) async {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: DateFormat('dd-MM-yyyy').format(firstDay))
        .where('date', isLessThanOrEqualTo: DateFormat('dd-MM-yyyy').format(lastDay))
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }


  //weekly report
  Future<List<Map<String, dynamic>>> getWeekAttendance(DateTime startDate) async {
    final endDate = startDate.add(const Duration(days: 5));

    final formattedStart = DateFormat('dd-MM-yyyy').format(startDate);
    final formattedEnd = DateFormat('dd-MM-yyyy').format(endDate);

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: formattedStart)
        .where('date', isLessThanOrEqualTo: formattedEnd)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
