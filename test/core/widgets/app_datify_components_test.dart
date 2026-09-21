import 'package:agapeo/core/theme/app_colors.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_staff_badge.dart';
import 'package:agapeo/core/widgets/app_tag_chip.dart';
import 'package:agapeo/core/widgets/app_verified_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('verified badge exposes semantics and rose icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppVerifiedBadge()),
      ),
    );

    expect(find.bySemanticsLabel('Vérifié'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.verified)).color,
      AppColors.light.verified,
    );
  });

  testWidgets('staff badge shows Équipe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppStaffBadge()),
      ),
    );

    expect(find.text('Équipe'), findsOneWidget);
    expect(find.bySemanticsLabel('Équipe'), findsOneWidget);
  });

  testWidgets('tag wrap renders labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppTagWrap(labels: ['Foi', 'Famille'])),
      ),
    );

    expect(find.text('Foi'), findsOneWidget);
    expect(find.text('Famille'), findsOneWidget);
    expect(find.byType(AppTagChip), findsNWidgets(2));
  });
}
