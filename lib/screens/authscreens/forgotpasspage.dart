import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStatePasswordReset) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password berhasil direset"),
              backgroundColor: Colors.green,
            ),
          );
          context.goNamed(Routes.login);
        } else if (state is AuthStateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF3762AB),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "RESET PASSWORD",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Image.asset("images/logoinventrack1.png",
                      width: MediaQuery.of(context).size.width * 0.5),
                  const SizedBox(height: 10),
                  const Text("INVENTRACK",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 30),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Masukkan email terdaftar dan password baru Anda",
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          _buildTextField(email, "Email", Icons.email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField(newPassword, "Password Baru", Icons.lock,
              obscureText: true),
          _buildTextField(confirmPassword, "Konfirmasi Password", Icons.lock,
              obscureText: true),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (email.text.isEmpty ||
                  newPassword.text.isEmpty ||
                  confirmPassword.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Semua field harus diisi"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword.text != confirmPassword.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password tidak cocok"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              context.read<AuthBloc>().add(
                    AuthEventResetPassword(
                      email.text,
                      newPassword.text,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text("Reset Password",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              context.goNamed(Routes.login);
            },
            child: const Text("Kembali ke Login",
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
