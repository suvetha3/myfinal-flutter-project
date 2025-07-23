import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _role = '';
  String? _email = '';
  String? _name = '';

  String? get role => _role;

  String? get email => _email;

  String? get name => _name;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void clearUser() {
    _email = null;
    _name = null;
    _role = null;
    notifyListeners();
  }

  void updateUser({String? name, String? email, String? role}) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (role != null) _role = role;
    notifyListeners();
  }
}
