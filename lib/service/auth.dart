import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginServices extends ChangeNotifier{
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> login(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      User? user = userCredential.user;

      print(user?.email);
      print(user?.uid);
      Navigator.pushReplacementNamed(context, '/homepage');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }),
          content: Text('Login successfully', style: TextStyle(color: Colors.white),)));
    } on FirebaseAuthException catch (e) {
      print(e);
    }
  }

  Future<void> logOut(BuildContext context) async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }),
          content: Text(
            'Sign out successfully',
            style: TextStyle(color: Colors.white),
          )));
    } catch (e) {
      print(e);
    }
  }

  Future<void> register(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController) async {
    final key = GlobalKey<FormState>();
    if (key.currentState != null && key.currentState!.validate()) {
      key.currentState?.save();
    }
    try {
      var userSave = await _auth.createUserWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
      Navigator.pushNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }),
          content: Text('Register successfully', style: TextStyle(color: Colors.white),)));
    } catch (e) {
      print(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth= await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

}
