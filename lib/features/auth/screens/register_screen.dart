import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ww_button.dart';
import '../../../core/widgets/ww_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final pass = _password.text;
    final confirm = _confirm.text;

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: pass,
      );

      if (!mounted) return;
      Navigator.pop(context); // back to Login (AuthGate will switch after login)
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Registration failed';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WWTextField(
                    controller: _email,
                    label: 'Email',
                    hint: 'your.email@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  WWTextField(
                    controller: _password,
                    label: 'Password',
                    hint: '********',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  WWTextField(
                    controller: _confirm,
                    label: 'Confirm Password',
                    hint: '********',
                    obscureText: true,
                  ),
                  const SizedBox(height: 22),
                  WWButton(
                    text: _loading ? 'Creating...' : 'Create Account',
                    onPressed: _loading ? null : _register,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
