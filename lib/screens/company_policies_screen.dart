import 'package:flutter/material.dart';
import '../services/crud_service.dart';
import '../widgets/common_widgets.dart';

class CompanyPolicyScreen extends StatefulWidget {
  const CompanyPolicyScreen({super.key});

  @override
  State<CompanyPolicyScreen> createState() => _CompanyPolicyScreenState();
}

class _CompanyPolicyScreenState extends State<CompanyPolicyScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final CrudService _crudService = CrudService();
  final String _collection = 'policies';
  String? _editingDocId;

  Future<void> _addOrUpdatePolicy() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) return;

    final data = {
      'title': title,
      'desc': desc,
    };

    if (_editingDocId == null) {
      await _crudService.addItem(context: context, collection: _collection, data: data);
    } else {
      await _crudService.updateItem(context: context, collection: _collection, id: _editingDocId!, data: data);
    }

    _clearForm();
  }

  void _editPolicy(Map<String, dynamic> doc) {
    _titleController.text = doc['title'];
    _descController.text = doc['desc'];
    setState(() => _editingDocId = doc['id']);
  }

  void _cancelEdit() => _clearForm();

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    setState(() => _editingDocId = null);
  }

  Future<void> _deletePolicy(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this policy?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.error,))),
        ],
      ),
    );

    if (confirm == true) {
      await _crudService.deleteItem(collection: _collection, id: docId);
    }
  }

  void _viewPolicy(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc['title']),
        content: SingleChildScrollView(child: Text(doc['desc'])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Policies')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Form Section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingDocId == null ? 'Add Policy' : 'Edit Policy',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const FormSpacer(),
                      ReusableTextField(
                        controller: _titleController,
                        label: const RequiredField('Policy Title'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a policy title' : null,
                      ),
                      const FormSpacer(),
                      TextFormField(
                        controller: _descController,
                        maxLines: 5,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          label: RequiredField('Policy Description'),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a policy description';
                          }
                          return null;
                        },
                      ),
                      const FormSpacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_editingDocId != null)
                            TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _addOrUpdatePolicy();
                              }
                            },
                            icon: Icon(_editingDocId == null ? Icons.add : Icons.save),
                            label: Text(_editingDocId == null ? 'Add Policy' : 'Update Policy'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'List of Policies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _crudService.getItems(_collection),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data ?? [];
                  if (docs.isEmpty) return const Center(child: Text("No policies found."));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        child: ListTile(
                          leading: const Icon(Icons.description, size: 32),
                          title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(doc['desc'], maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewPolicy(doc);
                                  break;
                                case 'edit':
                                  _editPolicy(doc);
                                  break;
                                case 'delete':
                                  _deletePolicy(doc['id']);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: ListTile(leading: Icon(Icons.visibility), title: Text('View Policy')),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Policy')),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(leading: Icon(Icons.delete), title: Text('Delete Policy')),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
