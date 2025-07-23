import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../widgets/leave_card.dart';

class LeaveStatusScreen extends StatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  State<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Accepted', 'Rejected', 'Pending'];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave Status'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSecondary,
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down),
                  borderRadius: BorderRadius.circular(10),
                  items: _filters
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedFilter = value!);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaves')
            .where('email', isEqualTo: userProvider.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No leave records found.'));
          }

          final allLeaves = snapshot.data!.docs;

          final filteredLeaves = _selectedFilter == 'All'
              ? allLeaves
              : allLeaves.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status']?.toLowerCase() ==
                _selectedFilter.toLowerCase();
          }).toList();

          if (filteredLeaves.isEmpty) {
            return const Center(child: Text('No records match selected status.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredLeaves.length,
            itemBuilder: (context, index) {
              final data = filteredLeaves[index].data() as Map<String, dynamic>;

              return LeaveCard(
                data: data,
                showActions: false,
              );
            },
          );
        },
      ),
    );
  }
}
