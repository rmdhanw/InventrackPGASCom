import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/auth/auth_bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class ConfirmResetPasswordPage extends StatefulWidget {
  final String oobCode; // Kode verifikasi dari Firebase

  const ConfirmResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ConfirmResetPasswordPage> createState() =>
      _ConfirmResetPasswordPageState();
}

class _ConfirmResetPasswordPageState extends State<ConfirmResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Menutup keyboard

      context.read<AuthBloc>().add(
            AuthEventConfirmResetPassword(
              oobCode: widget.oobCode,
              newPassword: passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.06),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your new password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password cannot be empty';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.03),
                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) async {
                    if (state is AuthStateSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Store mounted state before async operation
                      final isStillMounted = mounted;

                      await Future.delayed(const Duration(seconds: 2));

                      // Check if widget is still mounted before using context
                      if (isStillMounted) {
                        if (context.mounted) {
                          context.goNamed(Routes.login);
                        }
                      }
                    } else if (state is AuthStateError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (state is AuthStateLoading) ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: (state is AuthStateLoading)
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Change Password"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
