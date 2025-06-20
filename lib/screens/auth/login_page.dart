import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/notifications.dart';
import 'package:productivity_app/screens/auth/register_page.dart';
import 'package:productivity_app/screens/home_page.dart';

class LoginPage extends StatefulWidget {
  final Notifications notifications;
  const LoginPage({super.key, required this.notifications});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  //late final Notifications notifications;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Login successful');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(notifications: widget.notifications),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print('Login failed'); // TO DO exceptii
    }
  }

  @override
  Widget build(BuildContext content) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Spacer(),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Enter email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(hintText: 'Enter password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  login();
                });
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            RegisterPage(notifications: widget.notifications),
                  ),
                );
              },
              child: Text("Don't have an account?"),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
