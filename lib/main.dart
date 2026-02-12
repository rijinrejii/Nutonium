// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/profile/presentation/screens/retailer_profile_setup_screen.dart';
import 'features/profile/presentation/screens/wholesaler_profile_setup_screen.dart';
import '../core/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutonium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, check their profile
          return ProfileChecker(userId: snapshot.data!.uid);
        }

        // User is not logged in, show role selection
        return const RoleSelectionScreen();
      },
    );
  }
}

class ProfileChecker extends StatelessWidget {
  final String userId;

  const ProfileChecker({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await firebase_auth.FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // User document doesn't exist, sign out
          firebase_auth.FirebaseAuth.instance.signOut();
          return const RoleSelectionScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = UserRole.fromString(userData['role'] as String);
        final isProfileComplete = userData['isProfileComplete'] as bool? ?? false;

        // If customer or profile is complete, go to main app
        if (role == UserRole.customer || isProfileComplete) {
          return const MainNavigationScreen();
        }

        // Profile not complete, show setup screen based on role
        switch (role) {
          case UserRole.retailer:
            return const RetailerProfileSetupScreen();
          case UserRole.wholesaler:
            return const WholesalerProfileSetupScreen();
          default:
            return const MainNavigationScreen();
        }
      },
    );
  }
}