import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthStateLogin) {
            context.goNamed(Routes.home);
          } else if (state is AuthStateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: size.height,
          decoration: const BoxDecoration(color: Colors.blue),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: size.width * 0.8,
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'images/logoinventrack.png',
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                    ),
                    SizedBox(height: size.height * 0.02),
                    _buildTextField(
                      hintText: 'Username',
                      icon: Icons.person,
                      obscureText: false,
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: size.height * 0.02),
                    _buildTextField(
                        hintText: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                        controller: password,
                        keyboardType: TextInputType.none),
                    SizedBox(height: size.height * 0.02),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: (state is AuthStateLoading)
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(AuthEventLogin(
                                      email.text, password.text));
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.25,
                              vertical: size.height * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(size.width * 0.05),
                            ),
                          ),
                          child: (state is AuthStateLoading)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "LOGIN",
                                  style: TextStyle(color: Colors.white),
                                ),
                        );
                      },
                    ),
                    SizedBox(height: size.height * 0.015),
                    TextButton(
                      onPressed: () {
                        context.pushNamed(Routes.forgotpassword);
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushNamed(Routes.register);
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
