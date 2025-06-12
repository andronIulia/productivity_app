import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/screens/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Register successful');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      print('Register failed'); // TO DO exceptii
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
                  register();
                });
              },
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Text('Already have an account?'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
