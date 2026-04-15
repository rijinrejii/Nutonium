import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutonium/shared/widgets/navigation/bottom_navigation.dart';
import 'package:nutonium/shared/widgets/navigation/top_bar.dart';

void main() {
  testWidgets('navigation shell renders market header and cart badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TopBar(
                title: 'Nutonium Market',
                subtitle: 'Offers, events, and live stock signals.',
                onSearchPress: () {},
                onQrPress: () {},
                onCameraPress: () {},
                onMenuPress: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: 1,
            onTap: (_) {},
            cartCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('Nutonium Market'), findsOneWidget);
    expect(
      find.text('Offers, events, and live stock signals.'),
      findsOneWidget,
    );
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
