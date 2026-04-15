import 'package:flutter/material.dart';
import '../../data/usecases/google_sign_in_usecase.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F7F2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 45.0,
                backgroundColor: Colors.green.shade800,
                child: const Icon(
                  Icons.store,
                  size: 50.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome to Nutonium",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Select how you want to join",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              RoleOption(
                title: "Customer",
                subtitle: "Shop and discover products",
                icon: Icons.shopping_bag,
                onTap: () => navigateToSignIn(context, "Customer"),
              ),
              const SizedBox(height: 10),
              RoleOption(
                title: "Retailer",
                subtitle: "Sell products from your shop",
                icon: Icons.store,
                onTap: () => navigateToSignIn(context, "Retailer"),
              ),
              const SizedBox(height: 10),
              RoleOption(
                title: "Wholesaler/Startup",
                subtitle: "Distribute products in bulk",
                icon: Icons.apartment,
                onTap: () => navigateToSignIn(context, "Wholesaler/Startup"),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final user = await GoogleSignInUseCase().execute();
                  if (user != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed in as ${user.displayName}')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Google sign-in failed.')),
                    );
                  }
                },
                icon: const Icon(Icons.g_mobiledata),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void navigateToSignIn(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignInScreen(role: role),
      ),
    );
  }
}

class RoleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.green.shade800,
              size: 36,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  final String role;

  const SignInScreen({required this.role, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F7F2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role == "Customer"
                    ? Icons.shopping_bag
                    : role == "Retailer"
                        ? Icons.store
                        : Icons.apartment,
                size: 70.0,
                color: Colors.green.shade800,
              ),
              const SizedBox(height: 20),
              Text(
                "$role Sign In",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your credentials to continue",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (role == "Customer") ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = await GoogleSignInUseCase().execute();
                    if (user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Signed in as ${user.displayName}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Google sign-in failed.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text("Sign in with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                )
              ] else ...[
                TextField(
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    prefix: const Text("IN +91 "),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Send OTP"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}