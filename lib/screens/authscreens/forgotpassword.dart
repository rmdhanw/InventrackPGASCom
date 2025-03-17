import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/auth/auth_bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:uni_links/uni_links.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPassPage> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() async {
    uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == "/resetpassword") {
        context.pushNamed(Routes.resetpassword);
      }
    }, onError: (error) {
      print("Error handling deep link: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your email to receive a confirmation email for password reset",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthStateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is AuthStateError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: (state is AuthStateLoading)
                      ? null
                      : () {
                          context.read<AuthBloc>().add(
                              AuthEventRequestResetConfirmation(
                                  emailController.text));
                        },
                  child: (state is AuthStateLoading)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Send Confirmation Email"),
                );
              },
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
