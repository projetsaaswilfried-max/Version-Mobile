import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_birth_date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens sheet with CupertinoDatePicker on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: AppBirthDateField(
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
  });
}
