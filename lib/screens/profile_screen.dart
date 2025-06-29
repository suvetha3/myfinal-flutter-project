import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../provider/user_provider.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late Map<String, TextEditingController> controllers;
  Map<String, List<String>> dropdownOptions = {'gender': [], 'designation': []};
  bool _dropdownsLoaded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownValues();
  }

  Future<void> _loadDropdownValues() async {
    final genderSnap = await FirebaseFirestore.instance
        .collection('codes')
        .where('type', isEqualTo: 'gender')
        .where('active', isEqualTo: true)
        .get();

    final designationSnap = await FirebaseFirestore.instance
        .collection('codes')
        .where('type', isEqualTo: 'designation')
        .where('active', isEqualTo: true)
        .get();

    setState(() {
      dropdownOptions['gender'] = genderSnap.docs.map((doc) => doc['value'] as String).toList();
      dropdownOptions['designation'] = designationSnap.docs.map((doc) => doc['value'] as String).toList();
      _dropdownsLoaded = true;
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      controllers.forEach((_, controller) => controller.dispose());
    }
    super.dispose();
  }

  String _parseDateToIso(String formattedDate) {
    try {
      final parsed = DateFormat('dd-MM-yyyy').parse(formattedDate);
      return parsed.toIso8601String();
    } catch (_) {
      return formattedDate;
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final email = userProvider.email ?? "N/A";

    final updatedData = {
      'name': controllers['name']!.text.trim(),
      'phone': controllers['phone']!.text.trim(),
      'designation': controllers['designation']!.text.trim(),
      'gender': controllers['gender']!.text.trim(),
      'dob': _parseDateToIso(controllers['dob']!.text.trim()),
      'joiningDate': _parseDateToIso(controllers['joiningDate']!.text.trim()),
      'updatedOn': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.collection('users').doc(email).update(updatedData);

    userProvider.updateUser(
      name: controllers['name']!.text.trim(),
      email: email,
      role: userProvider.role ?? '',
    );

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _confirmAndSaveProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Are you sure you want to save the changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final email = userProvider.email ?? "N/A";

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(email).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !_dropdownsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final role = userData['role'] ?? 'N/A';

          if (!_isInitialized) {
            controllers = {
              'name': TextEditingController(text: userData['name'] ?? ''),
              'phone': TextEditingController(text: userData['phone'] ?? ''),
              'designation': TextEditingController(text: userData['designation'] ?? ''),
              'gender': TextEditingController(text: userData['gender'] ?? ''),
              'dob': TextEditingController(text: _formatDate(userData['dob'])),
              'joiningDate': TextEditingController(text: _formatDate(userData['joiningDate'])),
            };
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/avatar.jpg'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                  label: Text(_isEditing ? 'Cancel' : 'Edit Profile', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInlineField('Name', 'name'),
                        _buildInlineField('Phone', 'phone'),
                        _buildInlineField('Designation', 'designation'),
                        _buildInlineField('Gender', 'gender'),
                        _buildInlineField('DOB', 'dob'),
                        _buildInlineField('Joining Date', 'joiningDate'),
                        _buildReadonlyField('Email', userData['email'] ?? 'N/A'),
                        _buildReadonlyField('Role', role),
                      ],
                    ),
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: _confirmAndSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInlineField(String label, String key) {
    final isDropdown = dropdownOptions.containsKey(key);
    final isDateField = key == 'dob' || key == 'joiningDate';

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            isDropdown
                ? DropdownButtonFormField<String>(
              value: controllers[key]!.text.isNotEmpty ? controllers[key]!.text : null,
              items: dropdownOptions[key]!
                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) controllers[key]!.text = newValue;
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            )
                : isDateField
                ? ReusableDatePickerField(
              controller: controllers[key]!,
              label: label,
              initialDate: DateTime.tryParse(_parseDateToIso(controllers[key]!.text)) ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              onDatePicked: (pickedDate) {
                controllers[key]!.text = DateFormat('dd-MM-yyyy').format(pickedDate);
              },
            )
                : TextField(
              controller: controllers[key],
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 2,
                child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: Text(controllers[key]!.text)),
          ],
        ),
      );
    }
  }


  Widget _buildReadonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateValue);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dateValue.toString();
    }
  }
}
