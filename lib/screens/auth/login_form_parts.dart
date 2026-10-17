import 'package:flutter/material.dart';

/// Presentation slots only: ownership, validation and submit remain in LoginScreen.
class LoginFormParts {
  const LoginFormParts({
    required this.email,
    required this.password,
    required this.submit,
    this.error,
  });
  final Widget email, password, submit;
  final Widget? error;
}

typedef LoginPresentationBuilder = Widget Function(
  BuildContext context,
  LoginFormParts parts,
);
