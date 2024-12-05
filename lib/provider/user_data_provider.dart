import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  Stream<Map<String, dynamic>> get userStream {
    User? user = _auth.currentUser;
    print(user?.uid);
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  void updateUserData(Map<String, dynamic>? newUserData) {
    _userData = newUserData;
    notifyListeners();
  }
}
