import 'package:flutter/material.dart';
import '../service/auth.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _password1Controller = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    LoginServices loginServices = LoginServices();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LogInRegisterHeader(title: '',), // Boş title kaldırıldı
              const Header(title: 'Register'),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 10),
                  RegisterTextFieldFormName(
                    hintText: 'Surname',
                    label: 'Your Surname',
                    icon: Icons.account_box,
                    controller: _surnameController,
                    name: _surnameController.text,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFieldForm(
                hintText: 'username123',
                label: 'Username',
                icon: Icons.drive_file_rename_outline,
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
              TextFieldForm(
                hintText: 'abc@gmail.com',
                label: 'E-mail',
                icon: Icons.email,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(_password1Controller, 'Password', Icons.lock),
              const SizedBox(height: 20),
              _buildPasswordField(_password2Controller, 'Confirm Password', Icons.lock_outline, checkMatch: true),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await loginServices.register(
                      context,
                      _emailController,
                      _password1Controller,
                      _nameController,
                      _surnameController,
                      _usernameController,
                    );
                  }
                },
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, IconData icon, {bool checkMatch = false}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0),
        child: TextFormField(
          obscureText: true,
          controller: controller,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password!';
            } else if (value.length < 8) {
              return 'Password must be at least 8 characters long!';
            } else if (checkMatch && value.trim() != _password1Controller.text.trim()) {
              return 'Passwords do not match!';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
  final String name;

  const RegisterTextFieldFormName({
    super.key,
    required this.hintText,
    required this.label,
    required this.icon,
    required this.controller,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please fill this field!';
          }
          return null;
        },
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: label,
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

