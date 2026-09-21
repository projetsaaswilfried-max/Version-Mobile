import 'package:agapeo/core/theme/app_colors.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/home/presentation/home_tab.dart';
import 'package:agapeo/features/home/presentation/widgets/home_floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes four icon destinations and reports selection', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeFloatingNavBar(
            selectedIndex: index,
            onSelect: (value) => index = value,
          ),
        ),
      ),
    );

    expect(find.text('Fil'), findsNothing);
    expect(find.byTooltip('Fil'), findsOneWidget);
    expect(find.byTooltip('Découvrir'), findsOneWidget);
    expect(find.byTooltip('Messages'), findsOneWidget);
    expect(find.byTooltip('Profil'), findsOneWidget);
    expect(find.byType(AnimatedPositioned), findsOneWidget);

    final inactiveIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byTooltip('Découvrir'),
        matching: find.byType(Icon),
      ),
    );
    expect(inactiveIcon.color, AppColors.light.muted);

    await tester.tap(find.byTooltip('Messages'));
    await tester.pump();
    expect(index, HomeTab.messages.index);
  });
}
