import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/service/auth.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //login servisten fonksiyonlara ulaşmak amacıyla nesne oluşturdum
    LoginServices loginServices = LoginServices();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 60,
        children: [
          LogInRegisterHeader(title: 'Login'),
          Header(title: 'login'),
          TextFieldForm(
            hintText: 'Username123',
            label: 'Username',
            icon: Icons.account_box,
            controller: _emailController,
          ),
          TextFieldForm(
            hintText: '*******',
            label: 'Password',
            icon: Icons.password_sharp,
            controller: _passwordController,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary),
              onPressed: () async {
                await loginServices.login(
                    context, _emailController, _passwordController);
              },
              child: Text(
                '    Log in    ',
                style: TextStyle(fontSize: 20, color: Colors.white),
              )),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 28.0),
                  child: SizedBox(
                      width: 165, child: Text('If you don\'t have account')),
                ),
                SizedBox(
                    width: 77,
                    child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, '/register');
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        )))
              ],
            ),
          ),
        ],
      ),
    );

  }
}

class TextFieldForm extends StatelessWidget {
  final String hintText;
  final String label;
  final IconData icon;
  final TextEditingController controller;

  const TextFieldForm({
    super.key,
    required this.hintText,
    required this.label,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: label,
          icon: Icon(
            icon,
            size: 24,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onPrimary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class LogInRegisterHeader extends StatelessWidget {
  final String title;
  const LogInRegisterHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/Vector1.jpg'), fit: BoxFit.cover),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,

          fontSize: 30),
    );
  }
}
