import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'battleshipspage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? loggedInUsername;

  Future<void> _handleRegister() async {
    final url = "http://165.227.117.48/register";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text,
        "password": _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Registration successful
      final responseData = jsonDecode(response.body);
      final message = responseData['message'];
      final accessToken = responseData['access_token'];

      // Save the access token locally
      await _saveTokenLocally(accessToken);

      print('Access Token: $accessToken');
      print('Message: $message' );
      
      setState(() {
        loggedInUsername = _usernameController.text;
      });
      // Navigate to the Battleships screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BattleshipsPage(username: loggedInUsername!, accessToken: accessToken)),
      );
    } else if (response.statusCode == 409) {
      // User already exists
      final errorMessage = jsonDecode(response.body)['error'];
      // Show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } else {
      // Registration failed for other reasons
      final errorMessage = jsonDecode(response.body)['error'];
      // Show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final url = "http://165.227.117.48/login";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text,
        "password": _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Login successful
      final responseData = jsonDecode(response.body);
      final message = responseData['message'];
      final accessToken = responseData['access_token'];

      // Save the access token locally
      await _saveTokenLocally(accessToken);
      print('Access Token: $accessToken');
      print('Message: $message' );

      setState(() {
        loggedInUsername = _usernameController.text;
      });

      // Navigate to the Battleships screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BattleshipsPage(username: loggedInUsername!, accessToken: accessToken,)),
      );
    } else if (response.statusCode == 401) {
      // Incorrect username or password
      final errorMessage = jsonDecode(response.body)['error'];
      // Show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } else {
      // Login failed for other reasons
      final errorMessage = jsonDecode(response.body)['error'];
      // Show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
            SizedBox(height: 8.0),
            TextButton(
              onPressed: _handleRegister,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
