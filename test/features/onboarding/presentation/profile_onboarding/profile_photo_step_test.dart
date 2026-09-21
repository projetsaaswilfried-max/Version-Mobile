import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_photo_grid.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/steps/profile_photo_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile photo step shows single empty frame', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfilePhotoStep()),
        ),
      ),
    );

    expect(find.byType(AppPhotoGrid), findsNothing);
    expect(find.text('Ajouter une photo'), findsOneWidget);
    expect(find.text('Caméra ou galerie'), findsOneWidget);
    expect(find.text('Photos'), findsNothing);
    expect(find.text('Prendre une photo'), findsNothing);
    expect(find.text('Selfie de vérification'), findsNothing);
  });

  testWidgets('empty frame opens camera/gallery sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfilePhotoStep()),
        ),
      ),
    );

    await tester.tap(find.text('Ajouter une photo'));
    await tester.pumpAndSettle();

    expect(find.text('Photo de profil'), findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
  });
}
