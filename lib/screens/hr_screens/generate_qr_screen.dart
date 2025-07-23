import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateMainBranchQRScreen extends StatefulWidget {
  const GenerateMainBranchQRScreen({super.key});

  @override
  State<GenerateMainBranchQRScreen> createState() => _GenerateMainBranchQRScreenState();
}

class _GenerateMainBranchQRScreenState extends State<GenerateMainBranchQRScreen> {
  Map<String, Map<String, dynamic>> locationMap = {};
  String? selectedLocationId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyLocations();
  }

  Future<void> _loadCompanyLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('codes')
        .where('type', isEqualTo: 'companylocation')
        .where('active', isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      locationMap = {
        for (var doc in snapshot.docs) doc.id: doc.data(),
      };
      selectedLocationId = snapshot.docs.first.id;

      await _generateAndSaveNewKey();

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active company locations found.")),
      );
    }
  }

  Future<void> _generateAndSaveNewKey() async {
    if (selectedLocationId == null) return;

    final newKey = _generateRandomKey();

    // Save new key in Firestore
    await FirebaseFirestore.instance
        .collection('codes')
        .doc(selectedLocationId)
        .update({'key': newKey});

    // Fetch updated data
    final updatedDoc = await FirebaseFirestore.instance
        .collection('codes')
        .doc(selectedLocationId)
        .get();

    setState(() {
      locationMap[selectedLocationId!] = updatedDoc.data()!;
    });
  }

  String _generateRandomKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(25, (index) => chars[(now + index) % chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    final locationData = locationMap[selectedLocationId];

    final String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String? codeKey = locationData?['key'];
    final String? locationName = locationData?['longDesc'] ?? locationData?['shortDesc'] ?? 'Unknown';

    final qrPayload = jsonEncode({
      'key': codeKey,
      'date': date,
      'location': locationName,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Branch QR"),
        actions: [
          if (locationMap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButton<String>(
                      value: selectedLocationId,
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      iconEnabledColor: Theme.of(context).colorScheme.onSurface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      items: locationMap.entries.map((entry) {
                        final data = entry.value;
                        final name = data['longDesc'] ?? data['shortDesc'] ?? entry.key;
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) async {
                        setState(() {
                          selectedLocationId = newId;
                          isLoading = true;
                        });
                        await _generateAndSaveNewKey();
                        setState(() {
                          isLoading = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : locationMap.isEmpty
          ? const Center(child: Text("No data to display."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text("Date: $date", style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text("Location: $locationName", style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


