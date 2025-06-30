import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/crud_service.dart';
import '../../widgets/common_widgets.dart';

class CodesMaster extends StatefulWidget {
  const CodesMaster({super.key});

  @override
  State<CodesMaster> createState() => _CodesMasterState();
}

class _CodesMasterState extends State<CodesMaster> {
  final CrudService _crudService = CrudService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _longDescController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _isActive = true;
  String _selectedType = 'leave';
  String _selectedFilterType = 'All';

  void _showForm({String? docId, Map<String, dynamic>? docData}) {
    final isEditing = docId != null;

    if (isEditing && docData != null) {
      _selectedType = docData['type'] ?? 'leave';
      _valueController.text = docData['value'] ?? '';
      _shortDescController.text = docData['shortDesc'] ?? '';
      _longDescController.text = docData['longDesc'] ?? '';
      _longitudeController.text = docData['flex1'] ?? '';
      _isActive = docData['active'] ?? true;
    } else {
      _selectedType = 'leave';
      _valueController.clear();
      _shortDescController.clear();
      _longDescController.clear();
      _longitudeController.clear();
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Code' : 'Add Code'),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReusableDropdown<String>(
                      label: const RequiredField('Type'),
                      value: _selectedType,
                      items: const ['leave', 'designation', 'gender', 'companylocation'],
                      onChanged: (val) {
                        if (val != null) setModalState(() => _selectedType = val);
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const FormSpacer(),

                    ReusableTextField(
                      controller: _valueController,
                      label: RequiredField(
                        _selectedType == 'leave'
                            ? 'Leave Type'
                            : _selectedType == 'designation'
                            ? 'Designation'
                            : _selectedType == 'gender'
                            ? 'Gender'
                            : 'Latitude',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const FormSpacer(),

                    if (_selectedType == 'companylocation') ...[
                      ReusableTextField(
                        controller: _longitudeController,
                        label: const RequiredField('Longitude'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const FormSpacer(),
                    ],

                    if (_selectedType == 'leave' || _selectedType == 'companylocation') ...[
                      ReusableTextField(
                        controller: _shortDescController,
                        label: const RequiredField('Short Description'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const FormSpacer(),
                      ReusableTextField(
                        controller: _longDescController,
                        label: const RequiredField('Long Description'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const FormSpacer(),
                    ],

                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (val) => setModalState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final existing = await FirebaseFirestore.instance
                  .collection('codes')
                  .where('type', isEqualTo: _selectedType)
                  .where('value', isEqualTo: _valueController.text.trim())
                  .get();

              if (!isEditing && existing.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This value already exists.')),
                );
                return;
              }

              final data = {
                'type': _selectedType,
                'value': _valueController.text.trim(),
                'shortDesc': _shortDescController.text.trim(),
                'longDesc': _longDescController.text.trim(),
                'flex1': _longitudeController.text.trim(),
                'active': _isActive,
              };

              if (isEditing) {
                await _crudService.updateItem(
                  context: context,
                  collection: 'codes',
                  id: docId,
                  data: data,
                );
              } else {
                await _crudService.addItem(
                  context: context,
                  collection: 'codes',
                  data: data,
                );
              }

              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes Master'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilterType,
                  icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: ['All', 'leave', 'designation', 'gender', 'companylocation']
                      .map((String type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                        color: _selectedFilterType == type
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFilterType = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => _showForm()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('codes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final filteredDocs = _selectedFilterType == 'All'
              ? docs
              : docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == _selectedFilterType).toList();

          if (filteredDocs.isEmpty) return const Center(child: Text('No data for selected type.'));

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.code, color: Colors.blue.shade700),
                    ),
                    title: Text(
                      data['type'] == 'companylocation'
                          ? '${(data['type'] ?? '').toString().toUpperCase()} - ${data['shortDesc'] ?? ''}'
                          : '${(data['type'] ?? '').toString().toUpperCase()} - ${data['value'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['shortDesc'] != null && data['shortDesc'].toString().trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text('Short Desc: ${data['shortDesc']}'),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text('Active: ${data['active'] == true ? 'Yes' : 'No'}'),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showForm(docId: doc.id, docData: data);
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this item?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _crudService.deleteItem(collection: 'codes', id: doc.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Item deleted successfully.'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
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
