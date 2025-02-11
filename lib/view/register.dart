import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../service/auth.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _password1Controller = TextEditingController();
  TextEditingController _password2Controller = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();

  final key = GlobalKey<FormState>();
  String name = '';
  @override
  Widget build(BuildContext context) {
    LoginServices loginServices = LoginServices();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 60,
            children: [
              LogInRegisterHeader(),
              Header(title: 'Register'),
              SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RegisterTextFieldFormName(
                          hintText: 'Name',
                          label: 'Your Name',
                          icon: Icons.account_box,
                          controller: _nameController,
                          name: _nameController.text,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 1,
                          height: 44,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        RegisterTextFieldFormName(
                          hintText: 'Surname',
                          label: 'Your Surname',
                          icon: Icons.account_box,
                          controller: _surnameController,
                          name: _surnameController.text,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFieldForm(
                      hintText: 'username123',
                      label: 'username',
                      icon: Icons.drive_file_rename_outline,
                      controller: _usernameController,
                      name: _usernameController.text,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFieldForm(
                      hintText: 'abc@gmail.com',
                      label: 'e-mail',
                      icon: Icons.account_box,
                      controller: _emailController,
                      name: _emailController.text,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: '*******',
                            hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: Text(
                              'Password check',
                              style: TextStyle(
                                  color:
                                  Theme.of(context).colorScheme.onPrimary),
                            ),
                            icon: Icon(
                              Icons.password_sharp,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          controller: _password1Controller,
                          validator: (value) {
                            if (value!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Please fill al fields!')));
                            } else if (value.length < 8) {
                              return 'password must be taller than 8 digit';
                            } else {
                              return null;
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: '*******',
                            label: Text(
                              'Password check',
                              style: TextStyle(
                                  color:
                                  Theme.of(context).colorScheme.onPrimary),
                            ),
                            icon: Icon(
                              Icons.password_sharp,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          validator: (value) {
                            if (value != _password1Controller) {
                              return 'password check must be same with password';
                            } else {
                              return null;
                            }
                          },
                          controller: _password2Controller,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      elevation: 10,
                      backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () async {
                    await loginServices.register(
                        context, _emailController, _password1Controller);
                  },
                  child: Text(
                    '    Register    ',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 126,
                        child: Text(
                          'If you have account',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        )),
                    SizedBox(
                        width: 60,
                        child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            )))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextFieldForm extends StatelessWidget {
  final String hintText;
  final String label;
  final IconData icon;
  final TextEditingController controller;
  late String name;

  TextFieldForm(
      {super.key,
        required this.hintText,
        required this.label,
        required this.icon,
        required this.controller,
        required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0),
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please fill al fields!';
            }
            return null;
          },
          onSaved: (value) {
            name = value!;
          },
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
            TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            labelText: label,
            labelStyle:
            TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            icon: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.onPrimary)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterTextFieldFormName extends StatelessWidget {
  final String hintText;
  final String label;
  final IconData icon;
  final TextEditingController controller;
  late String name;

  RegisterTextFieldFormName(
      {super.key,
        required this.hintText,
        required this.label,
        required this.icon,
        required this.controller,
        required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: TextFormField(
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please fill all fields!';
          }
          return null;
        },
        onSaved: (value) {
          name = value!;
        },
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          suffixIcon: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          enabledBorder: UnderlineInputBorder(
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onPrimary)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
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
  const LogInRegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/Vector2.jpg'),fit: BoxFit.cover),
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
          color: Theme.of(context).colorScheme.primary,

          fontSize: 30),
    );
  }
}
