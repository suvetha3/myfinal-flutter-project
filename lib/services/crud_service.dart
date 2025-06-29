import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class CrudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addItem({
    required BuildContext context,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final role = Provider.of<UserProvider>(context, listen: false).role;
    final docRef = _db.collection(collection).doc(data['email']);

    data['createdBy'] = role;
    data['createdOn'] = DateTime.now().toIso8601String();
    data['updatedBy'] = '';
    data['updatedOn'] = '';

    await docRef.set(data);
  }

  Future<void> updateItem({
    required BuildContext context,
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final role = Provider.of<UserProvider>(context, listen: false).role;

    final doc = await _db.collection(collection).doc(id).get();
    if (doc.exists) {
      final existing = doc.data()!;
      data['createdBy'] = existing['createdBy'];
      data['createdOn'] = existing['createdOn'];
    }

    data['updatedBy'] = role;
    data['updatedOn'] = DateTime.now().toIso8601String();

    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteItem({
    required String collection,
    required String id,
  }) async {
    await _db.collection(collection).doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getItems(String collection) {
    return _db.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getItem(String collection, String id) async {
    final doc = await _db.collection(collection).doc(id).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }
}
