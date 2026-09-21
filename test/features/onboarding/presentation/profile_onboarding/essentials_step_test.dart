import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_gender_cards.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('O01 uses AppGenderCards not ChoiceChip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    expect(find.text('Parle-nous de toi'), findsOneWidget);
    expect(find.text('Autre'), findsNothing);
    expect(find.byType(AppGenderCards), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });
}
