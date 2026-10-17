import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/auth_repository.dart';
import '../../state/session_provider.dart';
import '../../widgets/primary_button.dart';
import 'login_form_parts.dart';
import 'premium_login_form.dart';
import 'premium_login_presentation.dart';
export 'login_form_parts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.presentationBuilder});
  final LoginPresentationBuilder? presentationBuilder;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await context.read<SessionProvider>().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on AccountNotProvisionedException {
      setState(() => _errorMessage = 'Esta cuenta aún no está provisionada.');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _messageFor(e.code));
    } catch (e) {
      setState(
        () => _errorMessage = 'No se pudo iniciar sesión. Intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }

  LoginFormParts _parts() => LoginFormParts(
    email: TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(labelText: 'CORREO'),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Ingresa tu correo' : null,
    ),
    password: TextFormField(
      controller: _passwordController,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      decoration: const InputDecoration(labelText: 'CONTRASEÑA'),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
      onFieldSubmitted: (_) => _submit(),
    ),
    error: _errorMessage == null
        ? null
        : Text(
            _errorMessage!,
            style: AppTypography.bodyMd.copyWith(color: AppColors.critical),
          ),
    submit: PrimaryButton(
      label: _isSubmitting ? 'Ingresando…' : 'Iniciar sesión',
      onPressed: _isSubmitting ? null : _submit,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final parts = _parts();
    if (widget.presentationBuilder != null) {
      return Form(
        key: _formKey,
        child: widget.presentationBuilder!(context, parts),
      );
    }
    final timeline = PremiumLoginTimeline.maybeOf(context);
    return PremiumLoginPresentation(
      timeline: timeline,
      formBuilder: (fit) => Form(
        key: _formKey,
        child: PremiumLoginForm(
          parts: parts,
          progress: timeline?.progress ?? PremiumLoginTimeline.completed,
          translationScale: fit,
        ),
      ),
    );
  }
}
