import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:to_gram_grad_project/view/homepage.dart';

class LoginServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcı kaydı (Firebase Authentication + Firestore)
  Future<void> register(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController,
      TextEditingController nameController,
      TextEditingController surnameController,
      TextEditingController usernameController) async {
    try {
      // Önce email/şifre kontrolü yapalım
      if (emailController.text.trim().isEmpty || 
          passwordController.text.trim().isEmpty ||
          nameController.text.trim().isEmpty ||
          surnameController.text.trim().isEmpty ||
          usernameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Firebase Authentication kaydı
      var userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Kullanıcı bilgilerini Firestore'a kaydediyoruz
      if (userCredential.user != null) {
        try {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': nameController.text.trim(),
            'surname': surnameController.text.trim(),
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('Firestore kaydı başarılı: ${userCredential.user!.uid}'); // Debug için

          // Kayıt başarılı mesajı
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
            backgroundColor: Colors.green,
          ));

          // Kullanıcı giriş ekranına yönlendiriliyor
          Navigator.pushNamed(context, '/login');
        } catch (firestoreError) {
          print('Firestore kayıt hatası: $firestoreError');
          // Firestore kaydı başarısız olursa Authentication kaydını da silelim
          await userCredential.user?.delete();
          throw 'Kullanıcı bilgileri kaydedilemedi';
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Kayıt başarısız';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Bu email adresi zaten kullanımda';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        default:
          errorMessage = e.message ?? 'Bir hata oluştu';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      print('Genel kayıt hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kayıt sırasında bir hata oluştu: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Kullanıcı girişi
  Future<void> login(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController) async {
    try {
      // Firebase Auth işlemi
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print('Auth başarılı, uid: ${userCredential.user?.uid}'); // Debug için

      // Firestore'dan kullanıcı bilgilerini al
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      print('Firestore sorgusu yapıldı: ${userDoc.exists}'); // Debug için

      if (!userDoc.exists) {
        // Eğer kullanıcı Firestore'da yoksa, temel bilgileri ekleyelim
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Yeni sorgu yapalım
        userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['name'] ?? 'Kullanıcı';
      String userSurname = userData['surname'] ?? '';
      String displayName = userName + (userSurname.isNotEmpty ? ' $userSurname' : '');

      // Ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(uid: userCredential.user!.uid,)),
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Giriş başarılı!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Login hatası: $e'); // Debug için
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Giriş hatası: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Kullanıcı çıkışı
  Future<void> logOut(BuildContext context) async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Çıkış başarılı.'),
        backgroundColor: Colors.blue,
      ));

      // Giriş sayfasına yönlendirme
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print(e);
    }
  }

  /// Google ile giriş
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Kullanıcı iptal etti

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Firestore'da kullanıcı kaydı yoksa ekle
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        // Google hesabından isim bilgilerini al
        String? fullName = googleUser.displayName;
        String name = 'Google Kullanıcısı';
        String surname = '';
        
        if (fullName != null) {
          List<String> nameParts = fullName.split(' ');
          name = nameParts[0];
          if (nameParts.length > 1) {
            surname = nameParts.sublist(1).join(' ');
          }
        }

        // Username oluştur (email adresinin @ öncesi kısmını al)
        String username = googleUser.email.split('@')[0];

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': name,
            'surname': surname,
            'username': username,
            'email': googleUser.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Kullanıcı bilgilerini tekrar çek
        final updatedUserDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        final userData = updatedUserDoc.data() as Map<String, dynamic>;
        
        String displayName = '${userData['name']} ${userData['surname'] ?? ''}'.trim();

        // Giriş başarılı, ana sayfaya yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(uid:userCredential.user!.uid)),
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google ile giriş başarılı!'),
          backgroundColor: Colors.green,
        ));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Google giriş hatası: ${e.message}'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      print('Google giriş hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Beklenmeyen bir hata oluştu: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
