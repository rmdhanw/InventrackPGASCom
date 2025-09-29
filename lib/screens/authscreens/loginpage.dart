import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials(); // TAMBAHKAN: Panggil fungsi untuk memuat data
  }

  Future<void> _loadCredentials() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'email');
      final savedPassword = await _secureStorage.read(key: 'password');

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          email.text = savedEmail;
          password.text = savedPassword;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Handle error jika gagal membaca dari secure storage
      debugPrint("Error loading credentials: $e");
    }
  }

  Future<void> _saveCredentials() async {
    await _secureStorage.write(key: 'email', value: email.text);
    await _secureStorage.write(key: 'password', value: password.text);
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: 'email');
    await _secureStorage.delete(key: 'password');
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthStateAuthenticated) {
            if (_rememberMe) {
              _saveCredentials();
            } else {
              _clearCredentials();
            }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTabletOrLarger = constraints.maxWidth >= 600;

            return Container(
              width: double.infinity,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(color: Colors.blue),
              child: Center(
                child: SingleChildScrollView(
                  child: LoginCard(
                    formKey: _formKey,
                    emailController: email,
                    passwordController: password,
                    isTabletOrLarger: isTabletOrLarger,
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                    rememberMe: _rememberMe,
                    onRememberMeChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isTabletOrLarger;
  final double maxWidth;
  final double maxHeight;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  const LoginCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isTabletOrLarger,
    required this.maxWidth,
    required this.maxHeight,
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  @override
  Widget build(BuildContext context) {
    double containerWidth;
    double horizontalPadding;
    double borderRadius;
    double spacing;
    double logoSize;
    double buttonPadding;
    double fontSize;
    if (maxWidth > 1200) {
      containerWidth = 500;
      horizontalPadding = 40;
      borderRadius = 20;
      spacing = 24;
      logoSize = 180;
      buttonPadding = 40;
      fontSize = 32;
    } else if (maxWidth >= 600) {
      containerWidth = maxWidth * 0.6;
      horizontalPadding = 30;
      borderRadius = 16;
      spacing = 20;
      logoSize = maxWidth * 0.25;
      buttonPadding = 30;
      fontSize = 28;
    } else {
      containerWidth = maxWidth * 0.85;
      horizontalPadding = 20;
      borderRadius = 15;
      spacing = 16;
      logoSize = maxWidth * 0.4;
      buttonPadding = 20;
      fontSize = 24;
    }
    logoSize = logoSize.clamp(80, 200);
    final buttonWidth =
        (maxWidth < 360) ? containerWidth * 0.7 : containerWidth * 0.5;

    return Container(
      width: containerWidth,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: horizontalPadding * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: spacing),
            Text(
              "LOGIN",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(199, 3, 40, 80),
              ),
            ),
            SizedBox(height: spacing),
            Image.asset(
              'images/logoinventrack.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: spacing),
            _buildTextFormField(
              hintText: 'Email',
              icon: Icons.person,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!value.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            SizedBox(height: spacing * 0.8),
            _buildTextFormField(
              hintText: 'Password',
              icon: Icons.lock,
              controller: passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                if (value.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            SizedBox(height: spacing),
            CheckboxListTile(
              value: rememberMe,
              onChanged: onRememberMeChanged,
              title: const Text("Ingat Saya"),
              controlAffinity:
                  ListTileControlAffinity.leading, // Checkbox di kiri
              contentPadding: EdgeInsets.zero, // Hapus padding default
              dense: true,
            ),
            SizedBox(height: spacing * 0.5),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: (state is AuthStateLoading)
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                    AuthEventLogin(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                    ),
                                  );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        vertical: buttonPadding * 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius * 0.8),
                      ),
                    ),
                    child: (state is AuthStateLoading)
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: maxWidth < 360 ? 1.5 : 2,
                            ),
                          )
                        : const Text(
                            "LOGIN",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                );
              },
            ),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    final inputBorderRadius = maxWidth < 360 ? 15.0 : 20.0;
    final iconSize = maxWidth < 360 ? 18.0 : 24.0;
    final fontSize = maxWidth < 360 ? 14.0 : 16.0;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      validator: validator,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: fontSize),
        contentPadding: EdgeInsets.symmetric(
          vertical: maxWidth < 360 ? 12 : 16,
          horizontal: maxWidth < 360 ? 8 : 12,
        ),
        prefixIcon: Icon(
          icon,
          size: iconSize,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
        ),
      ),
    );
  }
}
