import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  String? selectedRole; // Menyimpan role yang dipilih

  final List<String> roles = ["Engineer", "Driver", "Security"];

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateSignUp) {
          context.goNamed(Routes.login);
        } else if (state is AuthStateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
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
                    "REGISTER YOUR ACCOUNT",
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
                  const SizedBox(height: 20),
                  const Text("Already have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  TextButton(
                    onPressed: () => context.goNamed(Routes.login),
                    child: const Text("Login",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
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
          _buildTextField(name, "Name", Icons.person),
          _buildDropdownRole(),
          _buildTextField(email, "Email", Icons.email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField(password, "Password", Icons.lock, obscureText: true),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (selectedRole == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a role"),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                context.read<AuthBloc>().add(
                      AuthEventSignUp(
                          email.text, password.text, name.text, selectedRole!),
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text("Sign Up",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRole() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: InputDecoration(
          labelText: "Role",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: roles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Row(
              children: [
                Icon(
                  role == "Engineer"
                      ? Icons.build
                      : role == "Driver"
                          ? Icons.local_shipping
                          : Icons.security,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                Text(role),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedRole = value;
          });
        },
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
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
