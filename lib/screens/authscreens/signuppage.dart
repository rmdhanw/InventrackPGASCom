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
  String? selectedRole;
  String? selectedHandle;

  final List<String> roles = [
    "Manager RO",
    "Office",
    "Engineer",
    "Driver",
    "Security"
  ];
  final List<String> handles = ["user", "admin", "super admin"];

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
          _buildDropdown(
            label: "Role",
            value: selectedRole,
            items: roles,
            onChanged: (value) => setState(() => selectedRole = value),
            iconMapper: (role) {
              switch (role) {
                case "Manager RO":
                  return Icons.person;
                case "Office":
                  return Icons.work;
                case "Engineer":
                  return Icons.build;
                case "Driver":
                  return Icons.local_shipping;
                default:
                  return Icons.security;
              }
            },
          ),
          _buildDropdown(
            label: "Handle",
            value: selectedHandle,
            items: handles,
            onChanged: (value) => setState(() => selectedHandle = value),
          ),
          _buildTextField(email, "Email", Icons.email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField(password, "Password", Icons.lock, obscureText: true),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (selectedRole == null || selectedHandle == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a role and handle"),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                context.read<AuthBloc>().add(
                      AuthEventSignUp(
                        email.text,
                        password.text,
                        name.text,
                        selectedRole!,
                        selectedHandle!,
                      ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData Function(String)? iconMapper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                if (iconMapper != null)
                  Icon(iconMapper(item), color: Colors.blueAccent),
                if (iconMapper != null) const SizedBox(width: 10),
                Text(item),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
