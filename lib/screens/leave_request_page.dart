import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import '../services/crud_service.dart';
import '../widgets/common_widgets.dart';

class LeaveRequestForm extends StatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _crudService = CrudService();

  String? _selectedLeaveType;
  String _shortDesc = '';
  String _longDesc = '';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _workedOn;
  DateTime? _leaveOn;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _workedOnController = TextEditingController();
  final TextEditingController _leaveOnController = TextEditingController();
  final TextEditingController _halfDayController = TextEditingController();

  bool _isHalfDay = false;
  int? _noOfDays;
  final String _status = 'Pending';

  final List<String> _leaveTypes = [];
  final Map<String, Map<String, String>> _leaveTypeDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchLeaveTypes();
  }

  Future<void> _fetchLeaveTypes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('codes')
        .where('type', isEqualTo: 'leave')
        .where('active', isEqualTo: true)
        .get();

    setState(() {
      _leaveTypes.clear();
      for (var doc in snapshot.docs) {
        _leaveTypes.add(doc['value']);
        _leaveTypeDetails[doc['value']] = {
          'shortDesc': doc['shortDesc'] ?? '',
          'longDesc': doc['longDesc'] ?? '',
        };
      }
    });
  }

  void _calculateLeaveDays() {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date')),
        );
        return;
      }
      final difference = _endDate!.difference(_startDate!).inDays + 1;
      setState(() {
        _noOfDays = difference > 0 ? difference : null;
      });
    }
  }

  Future<void> _confirmAndSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to submit this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );

    if (confirmed == true) _submit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave type')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isCompOff = _selectedLeaveType?.toLowerCase() == 'comp off';

    final formatter = DateFormat('yyyy-MM-dd');
    final data = {
      'email': userProvider.email,
      'name': userProvider.name,
      'leaveType': _selectedLeaveType,
      'shortDesc': _shortDesc,
      'longDesc': _longDesc,
      'reason': _reasonController.text.trim(),
      'appliedOn': formatter.format(DateTime.now()),
      'approvedBy': '',
      'halfDay': _isHalfDay,
      'status': _status,
      'createdBy': userProvider.email,
      'createdOn': DateTime.now().toIso8601String(),
    };

    if (_isHalfDay) {
      data['leaveDate'] = formatter.format(_startDate!);
      data['noOfDays'] = 0.5;
    } else if (isCompOff) {
      data['workedOn'] = formatter.format(_workedOn!);
      data['leaveOn'] = formatter.format(_leaveOn!);
    } else {
      data['startDate'] = formatter.format(_startDate!);
      data['endDate'] = formatter.format(_endDate!);
      data['noOfDays'] = _noOfDays ?? 0;
    }

    await FirebaseFirestore.instance.collection('leaves').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave request submitted')),
    );

    _formKey.currentState!.reset();
    _reasonController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _workedOnController.clear();
    _leaveOnController.clear();
    _halfDayController.clear();

    setState(() {
      _selectedLeaveType = null;
      _shortDesc = '';
      _longDesc = '';
      _startDate = null;
      _endDate = null;
      _workedOn = null;
      _leaveOn = null;
      _isHalfDay = false;
      _noOfDays = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompOff = _selectedLeaveType?.toLowerCase() == 'comp off';

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Request')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('Leave Form', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: InputDecoration(
                        label: RequiredField('Leave Type'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _leaveTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLeaveType = val;
                          _shortDesc = _leaveTypeDetails[val!]?['shortDesc'] ?? '';
                          _longDesc = _leaveTypeDetails[val]?['longDesc'] ?? '';
                          _startDate = null;
                          _endDate = null;
                          _workedOn = null;
                          _leaveOn = null;
                          _isHalfDay = false;
                          _noOfDays = null;
                        });
                      },
                      validator: (value) => value == null ? 'Select leave type' : null,
                    ),

                    const SizedBox(height: 10),

                    if (!isCompOff)
                      CheckboxListTile(
                        title: const Text('Half Day'),
                        value: _isHalfDay,
                        onChanged: (value) {
                          setState(() {
                            _isHalfDay = value!;
                            _startDate = null;
                            _endDate = null;
                            _noOfDays = null;
                          });
                        },
                      ),

                    if (_isHalfDay)
                      ReusableDatePickerField(
                        controller: _halfDayController,
                        label: 'Leave Date',
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDatePicked: (picked) => _startDate = picked,
                        validator: (value) => value == null || value.isEmpty ? 'Select leave date' : null,
                      )
                    else if (isCompOff) ...[
                      ReusableDatePickerField(
                        controller: _workedOnController,
                        label: 'Worked On',
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDatePicked: (picked) => _workedOn = picked,
                        validator: (value) => value == null || value.isEmpty ? 'Select worked on date' : null,
                      ),
                      const SizedBox(height: 10),
                      ReusableDatePickerField(
                        controller: _leaveOnController,
                        label: 'Leave On',
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDatePicked: (picked) => _leaveOn = picked,
                        validator: (value) => value == null || value.isEmpty ? 'Select leave on date' : null,
                      ),
                    ] else ...[
                      ReusableDatePickerField(
                        controller: _startDateController,
                        label: 'Start Date',
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDatePicked: (picked) {
                          _startDate = picked;
                          _calculateLeaveDays();
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Select start date' : null,
                      ),
                      const SizedBox(height: 10),
                      ReusableDatePickerField(
                        controller: _endDateController,
                        label: 'End Date',
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDatePicked: (picked) {
                          _endDate = picked;
                          _calculateLeaveDays();
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Select end date' : null,
                      ),
                      if (_noOfDays != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No. of Leave Days: $_noOfDays',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        label: RequiredField('Reason'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Enter reason' : null,
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: _confirmAndSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
