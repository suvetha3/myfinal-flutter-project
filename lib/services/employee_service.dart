import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import 'crud_service.dart';
import 'firestore_service.dart';

class EmployeeService {
  final CrudService _crudService = CrudService();
  final String collectionName = 'users';
  final FirestoreService _firestoreService = FirestoreService();

  // Get employees
  Stream<List<Employee>> getEmployees() {
    return _crudService.getItems(collectionName).map((list) {
      return list
          .map((data) => Employee.fromUser(data['email'], data))
          .toList();
    });
  }

  // Add employee
  Future<void> addEmployee(BuildContext context, Employee emp) async {
    await _crudService.addItem(
      context: context,
      collection: collectionName,
      data: emp.toUser(),
    );
  }

  // Update employee
  Future<void> updateEmployee(BuildContext context, Employee emp) async {
    await _crudService.updateItem(
      context: context,
      collection: collectionName,
      id: emp.id,
      data: emp.toUser(),
    );
  }

  // Delete employee
  Future<void> deleteEmployee(String id) async {
    await _crudService.deleteItem(collection: collectionName, id: id);
  }

  Future<List<String>> getDropdownOptions(String type) async {
    return await _firestoreService.getDropdownOptions(type);
  }
}
