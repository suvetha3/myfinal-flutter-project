import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'leave_card.dart';


class LeaveMasterPage extends StatelessWidget {
  const LeaveMasterPage({super.key});

  Future<void> _updateStatus({
    required BuildContext context,
    required String docId,
    required String status,
    required String remarks,
  }) async {
    final user = Provider.of<UserProvider>(context, listen: false);

    await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
      'status': status,
      'remarks': remarks,
      'approvedBy': user.email ?? 'Unknown',
      'updatedBy': user.email ?? 'Unknown',
      'updatedOn': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Leave request $status')),
    );
  }

  Future<void> _showRemarksDialog({
    required BuildContext context,
    required String docId,
    required String status,
  }) async {
    final TextEditingController remarksController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter remarks for $status'),
          content: TextField(
            controller: remarksController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter remarks here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateStatus(
                  context: context,
                  docId: docId,
                  status: status,
                  remarks: remarksController.text.trim(),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<String> selectedStatus = ValueNotifier<String>('All');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Master'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Center(
              child: ValueListenableBuilder<String>(
                valueListenable: selectedStatus,
                builder: (context, value, _) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black),
                        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                          DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedStatus.value = val;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .orderBy('appliedOn', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No leave requests found."));
                }

                return ValueListenableBuilder<String>(
                  valueListenable: selectedStatus,
                  builder: (context, statusFilter, _) {
                    final filteredDocs = statusFilter == 'All'
                        ? docs
                        : docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status']?.toLowerCase() == statusFilter.toLowerCase();
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text("No leave requests match this filter."),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return LeaveCard(
                          data: data,
                          showActions: data['status']?.toLowerCase() == 'pending',
                          onAccept: () => _showRemarksDialog(
                            context: context,
                            docId: doc.id,
                            status: 'Accepted',
                          ),
                          onReject: () => _showRemarksDialog(
                            context: context,
                            docId: doc.id,
                            status: 'Rejected',
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
