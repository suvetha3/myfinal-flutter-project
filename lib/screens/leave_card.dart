import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;

  const LeaveCard({
    super.key,
    required this.data,
    this.onAccept,
    this.onReject,
    this.showActions = false,
  });

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      if (date is Timestamp) {
        return DateFormat('dd-MM-yyyy').format(date.toDate());
      } else if (date is String) {
        final parsed = DateTime.tryParse(date);
        if (parsed != null) {
          return DateFormat('dd-MM-yyyy').format(parsed);
        }
      }
    } catch (_) {}
    return 'Invalid date';
  }

  int _calculateDays(start, end) {
    if (start is Timestamp && end is Timestamp) {
      return end.toDate().difference(start.toDate()).inDays + 1;
    }
    return data['noOfDays'] ?? 0;
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Theme.of(context).colorScheme.tertiary;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveType = data['leaveType'] ?? 'Leave';
    final isCompOff = leaveType.toString().toLowerCase() == 'comp off';
    final isHalfDay = data['halfDay'] == true;
    final status = data['status'] ?? 'Pending';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${data['name'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Leave Type: $leaveType"),
            const SizedBox(height: 4),

            if (isCompOff) ...[
              Text("Worked On: ${_formatDate(data['workedOn'])}"),
              Text("Leave On: ${_formatDate(data['leaveOn'])}"),
            ] else if (isHalfDay) ...[
              Text("Half Day Leave on: ${_formatDate(data['leaveDate'])}"),
            ] else ...[
              Text("Start Date: ${_formatDate(data['startDate'])}"),
              Text("End Date: ${_formatDate(data['endDate'])}"),
              Text("No. of Days: ${_calculateDays(data['startDate'], data['endDate'])}"),
            ],

            Text("Reason: ${data['reason'] ?? ''}"),
            Text("Applied On: ${_formatDate(data['appliedOn'])}"),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: _statusColor(context, status),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (showActions && status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                    child: const Text("Accept"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ] else ...[
              if ((data['remarks'] ?? '').toString().trim().isNotEmpty)
                Text("Remarks: ${data['remarks']}", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              if ((data['approvedBy'] ?? '').toString().trim().isNotEmpty)
                Text("Approved By: ${data['approvedBy']}", style: const TextStyle(color: Colors.teal)),
            ],
          ],
        ),
      ),
    );
  }
}
