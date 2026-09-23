import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile_photo.dart';
import 'package:agapeo/features/profile/presentation/my_profile/widgets/my_profile_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<MyProfilePhoto> photos,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MyProfilePhotoGrid(
            photos: photos,
            readOnly: true,
            showRemoveButtons: true,
            onAdd: () {},
            onRemoveAt: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows "En attente" for a PENDING photo', (
    tester,
  ) async {
    await pump(
      tester,
      photos: const [
        MyProfilePhoto(
          id: 'p1',
          publicUrl: 'https://cdn/a.jpg',
          moderationStatus: 'PENDING',
        ),
      ],
    );

    expect(find.text('En attente'), findsOneWidget);
  });

  testWidgets('shows "Refusée" for a REJECTED photo', (tester) async {
    await pump(
      tester,
      photos: const [
        MyProfilePhoto(
          id: 'p1',
          publicUrl: 'https://cdn/a.jpg',
          moderationStatus: 'REJECTED',
        ),
      ],
    );

    expect(find.text('Refusée'), findsOneWidget);
  });

  testWidgets('no badge for an APPROVED photo', (tester) async {
    await pump(
      tester,
      photos: const [
        MyProfilePhoto(
          id: 'p1',
          publicUrl: 'https://cdn/a.jpg',
          moderationStatus: 'APPROVED',
        ),
      ],
    );

    expect(find.text('En attente'), findsNothing);
    expect(find.text('Refusée'), findsNothing);
  });
}
