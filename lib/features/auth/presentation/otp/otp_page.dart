import 'package:flutter/material.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.email, required this.password});

  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: Center(child: Text(email)),
    );
  }
}
