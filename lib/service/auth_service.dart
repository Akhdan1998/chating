import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _user;

  User? get user {
    return _user;
  }

  AuthService() {
    _firebaseAuth.authStateChanges().listen(authStateChangesStreamListener);
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<bool> reauthenticateUser(String currentPassword) async {
    try {
      User? user = _firebaseAuth.currentUser;
      String email = user?.email ?? '';

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Error reauthenticating user: $e');
      return false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    User? user = _firebaseAuth.currentUser;
    await user?.updatePassword(newPassword);
  }

  Future<bool> login(String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user != null;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  Future<UserCredential> signup(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw Exception('Error during signup: $e');
    }
  }

  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      _user = null;
      return true;
    } catch (e) {
      print(e.toString());
    }
    return false;
  }

  void authStateChangesStreamListener(User? user) {
    if (user != null) {
      _user = user;
    } else {
      _user = null;
    }
  }
}