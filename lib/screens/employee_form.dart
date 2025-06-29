import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../widgets/common_widgets.dart';

class EmployeeForm extends StatefulWidget {
  final Employee? employee;
  final EmployeeService service;

  const EmployeeForm({super.key, this.employee, required this.service});

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController roleController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController designationController;
  late TextEditingController statusController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController jodController;

  DateTime? dob;
  DateTime? jod;
  List<String> designationList = [];
  List<String> genderList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;

    nameController = TextEditingController(text: emp?.name ?? '');
    roleController = TextEditingController(text: emp?.role ?? 'Employee');
    emailController = TextEditingController(text: emp?.email ?? '');
    passwordController = TextEditingController(text: emp?.password ?? '');
    phoneController = TextEditingController(text: emp?.phone ?? '');
    addressController = TextEditingController(text: emp?.address ?? '');
    designationController = TextEditingController(text: emp?.designation ?? '');
    statusController = TextEditingController(text: emp?.status ?? 'Active');
    genderController = TextEditingController(text: emp?.gender ?? 'Female');
    dobController = TextEditingController(
      text: emp?.dob != null ? DateFormat('dd-MM-yyyy').format(emp!.dob) : '',
    );
    jodController = TextEditingController(
      text: emp?.joiningDate != null ? DateFormat('dd-MM-yyyy').format(emp!.joiningDate) : '',
    );

    dob = emp?.dob;
    jod = emp?.joiningDate;

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    designationList = await widget.service.getDropdownOptions('designation');
    genderList = await widget.service.getDropdownOptions('gender');

    final emp = widget.employee;
    if (emp != null) {
      if (!designationList.contains(emp.designation)) designationList.add(emp.designation);
      if (!genderList.contains(emp.gender)) genderList.add(emp.gender);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final emp = Employee(
        id: widget.employee?.id ?? '',
        name: nameController.text.trim(),
        role: roleController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        dob: dob ?? now,
        address: addressController.text.trim(),
        designation: designationController.text.trim(),
        joiningDate: jod ?? now,
        status: statusController.text.trim(),
        gender: genderController.text.trim(),
        isLogin: widget.employee?.isLogin ?? false,
        createdBy: '',
        createdOn: now,
        updatedBy: '',
        updatedOn: now,
      );

      if (widget.employee == null) {
        await widget.service.addEmployee(context, emp);
      } else {
        await widget.service.updateEmployee(context, emp);
      }

      if (context.mounted) Navigator.pop(context, 'refresh');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    designationController.dispose();
    statusController.dispose();
    genderController.dispose();
    dobController.dispose();
    jodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : AlertDialog(
      title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ReusableTextField(
                controller: nameController,
                label: const RequiredField('Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: emailController,
                label: const RequiredField('Email'),
                validator: (val) => val != null && val.contains('@') ? null : 'Invalid email',
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: passwordController,
                label: const RequiredField('Password'),
                obscureText: true,
                validator: (val) => val != null && val.length >= 6 ? null : 'Min 6 characters',
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: phoneController,
                label: const RequiredField('Phone'),
                validator: (val) => val != null && val.length == 10 ? null : 'Enter 10-digit number',
              ),
              const FormSpacer(),
              ReusableDatePickerField(
                controller: dobController,
                label: 'Date of Birth',
                initialDate: dob ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onDatePicked: (picked) => dob = picked,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: addressController,
                label: const RequiredField('Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableDatePickerField(
                controller: jodController,
                label: 'Joining Date',
                initialDate: jod ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                onDatePicked: (picked) => jod = picked,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableDropdown(
                label: const RequiredField('Designation'),
                value: designationController.text.isNotEmpty ? designationController.text : null,
                items: designationList,
                onChanged: (value) => setState(() {
                  designationController.text = value ?? '';
                }),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: roleController,
                label: const RequiredField('Role'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableTextField(
                controller: statusController,
                label: const RequiredField('Status'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const FormSpacer(),
              ReusableDropdown(
                label: const RequiredField('Gender'),
                value: genderController.text.isNotEmpty ? genderController.text : null,
                items: genderList,
                onChanged: (value) => setState(() {
                  genderController.text = value ?? '';
                }),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveForm,
          child: Text(widget.employee == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
