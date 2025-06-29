import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class Employee {
  final String id;
  final String name;
  final String role;
  final String email;
  final String password;
  final String phone;
  final DateTime dob;
  final String address;
  final String designation;
  final DateTime joiningDate;
  final String status;
  final String gender;
  final bool isLogin;
  final String createdBy;
  final DateTime createdOn;
  final String updatedBy;
  final DateTime updatedOn;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.password,
    required this.phone,
    required this.dob,
    required this.address,
    required this.designation,
    required this.joiningDate,
    required this.status,
    required this.gender,
    required this.isLogin,
    required this.createdBy,
    required this.createdOn,
    required this.updatedBy,
    required this.updatedOn,
  });

  factory Employee.fromUser(String id, Map<String, dynamic> user) {
    DateTime _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          try {
            return DateFormat('dd-MM-yyyy').parseStrict(value);
          } catch (e) {
            debugPrint('Invalid date format: $value');
            return DateTime.now(); // fallback
          }
        }
      }

      return DateTime.now(); // fallback
    }

    return Employee(
      id: id,
      name: user['name'] ?? '',
      role: user['role'] ?? '',
      email: user['email'] ?? '',
      password: user['password'] ?? '',
      phone: user['phone'] ?? '',
      dob: _parseDate(user['dob']),
      address: user['address'] ?? '',
      designation: user['designation'] ?? '',
      joiningDate: _parseDate(user['joiningDate']),
      status: user['status'] ?? '',
      gender: user['gender'] ?? '',
      isLogin: user['isLogin'] ?? false,
      createdBy: user['createdBy'] ?? '',
      createdOn: _parseDate(user['createdOn']),
      updatedBy: user['updatedBy'] ?? '',
      updatedOn: _parseDate(user['updatedOn']),
    );
  }

  Map<String, dynamic> toUser() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'password': password,
      'phone': phone,
      'dob': dob.toIso8601String(),
      'address': address,
      'designation': designation,
      'joiningDate': joiningDate.toIso8601String(),
      'status': status,
      'gender': gender,
      'isLogin': isLogin,
      'createdBy': createdBy,
      'createdOn': createdOn.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedOn': updatedOn.toIso8601String(),
    };
  }

  Employee copyWith({
    String? id,
    String? name,
    String? role,
    String? email,
    String? password,
    String? phone,
    DateTime? dob,
    String? address,
    String? designation,
    DateTime? joiningDate,
    String? status,
    String? gender,
    bool? isLogin,
    String? createdBy,
    DateTime? createdOn,
    String? updatedBy,
    DateTime? updatedOn,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      designation: designation ?? this.designation,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      isLogin: isLogin ?? this.isLogin,
      createdBy: createdBy ?? this.createdBy,
      createdOn: createdOn ?? this.createdOn,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedOn: updatedOn ?? this.updatedOn,
    );
  }
}
