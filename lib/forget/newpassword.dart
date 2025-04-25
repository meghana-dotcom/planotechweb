import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';
import 'package:planotech/forget/forgetotppassword.dart';
import 'package:planotech/screens/welcome_screen.dart';

class NewPasswordPage extends StatefulWidget {
  final String email;
  const NewPasswordPage({Key? key, required this.email}) : super(key: key);

  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passToggle = true;
  bool passToggle1 = true;
  String? _printedEmail;
  bool _isLoading = false; // Add this state variable

  @override
  void initState() {
    super.initState();
    if (widget.email.isNotEmpty) {
      _printedEmail = widget.email; // Assign email to _printedEmail
    }
    print('Email: ${widget.email}');
  }

  Future<void> updatePassword(String email, String password) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    print('email: $email'); // Print the email
    print('password: $password'); // Print the password
    try {
      String encodedEmail = Uri.encodeComponent(email);
      String encodedPassword = Uri.encodeComponent(password);
      print(encodedEmail);
      print(encodedPassword);
      var response = await http.post(
        Uri.parse(
            baseurl+'/pte/updatepassword?email=$encodedEmail&password=$encodedPassword'),
      );
      var responseData = jsonDecode(response.body);
      print(responseData);
      String message = responseData['message'];
      bool status = responseData['status'];

      if (status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green, // Green background for success
            content: Text(
              message,
              style: TextStyle(color: Colors.white), // White text
              textAlign: TextAlign.center,
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              message,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red, // Red background for error
          content: Text(
            'An error occurred: $e',
            style: TextStyle(color: Colors.white), // White text
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 64, 144, 209),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordOTP(email: ''),
              ),
            );
          },
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_printedEmail != null) // Display email conditionally
                    TextFormField(
                      controller: _passwordController,
                      obscureText: passToggle,
                      obscuringCharacter: '*',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your new password';
                        } else if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        } else if (value.length > 20) {
                          return 'Password must be less than 20 characters';
                        } else if (value.contains(' ')) {
                          return 'Password cannot contain spaces';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter your new password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: Color.fromARGB(255, 65, 63, 63),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              passToggle = !passToggle;
                            });
                          },
                          icon: Icon(
                            passToggle
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: passToggle1,
                    obscuringCharacter: '*',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your confirm password';
                      } else if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Enter confirm password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outlined,
                        color: Color.fromARGB(255, 65, 63, 63),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            passToggle1 = !passToggle1;
                          });
                        },
                        icon: Icon(
                          passToggle1 ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String email = widget.email;
                        String password = _passwordController.text;
                        updatePassword(email, password);
                      }
                    },
                    child: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 64, 144, 209),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
