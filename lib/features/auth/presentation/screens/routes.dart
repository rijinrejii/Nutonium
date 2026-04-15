import 'package:flutter/material.dart';
import '../../../../core/presentation/screens/main_navigation_screen.dart';
import 'otp_verification_screen.dart';
import 'universal_auth_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => UniversalAuthScreen(),
    '/otp': (context) => OtpVerificationScreen(email: ''),
    '/home': (context) => MainNavigationScreen(),
  };
}