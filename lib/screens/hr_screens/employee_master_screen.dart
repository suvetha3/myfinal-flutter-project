import 'package:finalproject/screens/hr_screens/employee_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee_model.dart';
import '../../services/employee_service.dart';

class EmployeeMasterScreen extends StatefulWidget {
  const EmployeeMasterScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeMasterScreen> createState() => _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends State<EmployeeMasterScreen> {
  final EmployeeService _employeeService = EmployeeService();

  Future<void> _deleteEmployee(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this employee?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _employeeService.deleteEmployee(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Employee deleted')));
    }
  }

  Future<void> _openAddEditDialog({Employee? employee}) async {
    final result = await showDialog(
      context: context,
      builder:
          (_) => EmployeeForm(employee: employee, service: _employeeService),
    );
    if (result == 'refresh') {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    //final role = Provider.of<UserProvider>(context).role;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Master',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Employee',
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Employee>>(
        stream: _employeeService.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              final isHr = emp.role == 'Hr';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),

                  ),
                  title: Text(emp.name, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Id: ${emp.id}', style: Theme.of(context).textTheme.bodyMedium),
                      Text('DOB: ${DateFormat('dd-MM-yyyy').format(emp.dob)}', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        'Joining Date: ${DateFormat('dd-MM-yyyy').format(emp.joiningDate)}'
                          , style: Theme.of(context).textTheme.bodyMedium
                      ),
                      Text('Designation: ${emp.designation}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openAddEditDialog(employee: emp);
                      } else if (value == 'delete') {
                        _deleteEmployee(emp.id);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.blue),
                            title: Text('Edit'),
                          ),
                        ),
                        if (!isHr)
                           PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                              title: Text('Delete'),
                            ),
                          ),
                      ];
                    },
                    icon: const Icon(Icons.more_vert),
                  ),


                ),
              );
            },
          );
        },
      ),
    );
  }
}
