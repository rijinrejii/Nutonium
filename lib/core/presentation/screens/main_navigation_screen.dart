import 'package:flutter/material.dart';
import '../../../features/social/presentation/screens/social_screen.dart';
import '../../../features/cart/presentation/screens/cart_screen.dart';
import '../../../features/map/presentation/screens/map_screen.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../shared/widgets/navigation/top_bar.dart';
import '../../../shared/widgets/navigation/bottom_navigation.dart';
import '../../../features/camera/presentation/screens/camera_capture_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final GlobalKey<SocialScreenState> _socialScreenKey = GlobalKey<SocialScreenState>();

  late final List<Widget> _screens = [
    SocialScreen(key: _socialScreenKey),
    const CartScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Nutonium',
    'Cart',
    'Map',
    'Profile',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleQRPress() {
    // Implement QR code scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Scanner pressed')),
    );
  }

  Future<void> _handleCameraPress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(),
      ),
    );
  }

  void _handleMenuPress() {
    // Implement menu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu pressed')),
    );
  }

  void _handleSearchPress() {
    _socialScreenKey.currentState?.startSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: _titles[_currentIndex],
              // Show Search, QR and Camera only on Social page (index 0)
              onSearchPress: _currentIndex == 0 ? _handleSearchPress : null,
              onQRPress: _currentIndex == 0 ? _handleQRPress : null,
              onCameraPress: _currentIndex == 0 ? _handleCameraPress : null,
              // Show Menu only on Profile page (index 3)
              onMenuPress: _currentIndex == 3 ? _handleMenuPress : null,
            ),
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
