import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_settings_group.dart';
import 'package:agapeo/core/widgets/app_settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('settings row shows icon, label and chevron', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppSettingsRow(
          label: 'Confidentialité',
          icon: Icons.lock_outline,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Confidentialité'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('settings group shows a section title', (tester) async {
    await tester.pumpWidget(
      wrap(const AppSettingsGroup(title: 'Compte', children: [Text('Enfant')])),
    );

    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Enfant'), findsOneWidget);
  });

  testWidgets('danger row hides chevron', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppSettingsRow(
          label: 'Supprimer mon compte',
          icon: Icons.delete_outline,
          danger: true,
          showChevron: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Supprimer mon compte'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('compact row keeps label and icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppSettingsRow(
          label: 'Mon Profil',
          icon: Icons.person_outline,
          compact: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Mon Profil'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
