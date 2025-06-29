import 'package:finalproject/screens/dashboard_hr.dart';
import 'package:finalproject/screens/forgot_password.dart';
import 'package:finalproject/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';
import 'dashboard_employee.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _validateLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      try {
        final userData = await FirestoreService().getUserDataByEmail(email);

        if (userData != null) {
          final storedPassword = userData['password'];
          if (storedPassword != password) {
            _showSnackBar("Incorrect password. Please try again.");
          } else {
            await FirestoreService().updateLoginStatus(email, true);
            final role = userData['role'];
            final name = userData['name'];

            Provider.of<UserProvider>(context, listen: false).setEmail(email);
            Provider.of<UserProvider>(context, listen: false).setRole(role);
            Provider.of<UserProvider>(context, listen: false).setName(name);

            Provider.of<UserProvider>(
              context,
              listen: false,
            ).updateUser(name: name, email: email, role: role);

            if (role == 'Hr') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DashboardHr()),
                (route) => false,
              );
            } else if (role == 'Employee') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DashboardEmployee()),
                (route) => false,
              );
            } else {
              _showSnackBar("Unknown role: $role");
            }
          }
        } else {
          _showSnackBar("Email not found. Please enter a valid email.");
        }
      } catch (e) {
        _showSnackBar("Error occurred. Maybe no data in database.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background_1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  //shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white24,
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 40),
                        TextFormField(
                          controller: emailController,
                          cursorColor: Colors.black38,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text('Email'),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.black38,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                                width: 1.2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            } else if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: Colors.black38,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text('Password'),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.black38,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black38,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                                width: 1.2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            } else if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*]).{6,}$',
                            ).hasMatch(value)) {
                              return 'Password must be atleast 6 characters, \n include upper/lower case, number & symbol';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassword(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _validateLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.cyan.shade600,
                            minimumSize: Size(140, 45),
                            shadowColor: Colors.black12,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
