import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!EmailValidator.validate(value.trim())) {
      return 'Invalid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
