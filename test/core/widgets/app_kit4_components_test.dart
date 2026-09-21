import 'package:agapeo/core/theme/app_colors.dart';
import 'package:agapeo/core/theme/app_radius.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_empty_state.dart';
import 'package:agapeo/core/widgets/app_search_field.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('text fields use an outlined surface with visible focus', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AppTextField(hint: 'Email')));

    final theme = Theme.of(tester.element(find.byType(TextField)));
    final decoration = theme.inputDecorationTheme;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, AppColors.light.surface);

    final enabled = decoration.enabledBorder as OutlineInputBorder;
    expect(enabled.borderRadius, AppRadius.mdRadius);
    expect(enabled.borderSide.color, AppColors.light.border);

    final focused = decoration.focusedBorder as OutlineInputBorder;
    expect(focused.borderSide.color, AppColors.light.primary);
    expect(focused.borderRadius, AppRadius.mdRadius);
  });

  testWidgets('fields and body use the same typeface as the AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AppTextField(hint: 'Email')));

    final ctx = tester.element(find.byType(TextField));
    String face(String? family) => family?.split('_').first ?? '';
    final family = face(ctx.typography.title.fontFamily);
    expect(family, 'BricolageGrotesque');
    expect(face(ctx.typography.bodyLarge.fontFamily), family);
    expect(face(ctx.typography.bodyMedium.fontFamily), family);
    expect(face(ctx.typography.label.fontFamily), family);
    expect(
      face(tester.widget<TextField>(find.byType(TextField)).style?.fontFamily),
      family,
    );
  });

  testWidgets('text field shows an optional prefix icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTextField(hint: 'Email', prefixIcon: Icon(Icons.mail_outline)),
      ),
    );

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
  });

  testWidgets('search field uses a leading loupe and Rechercher hint', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppSearchField(onChanged: (_) {})));

    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('Rechercher'), findsOneWidget);
  });

  testWidgets('empty state shows disc, icon, title and detail', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppEmptyState(
          title: 'Aucune conversation',
          detail: 'Démarre une discussion depuis Découvrir.',
          icon: Icons.chat_bubble_outline,
        ),
      ),
    );

    expect(find.text('Aucune conversation'), findsOneWidget);
    expect(
      find.text('Démarre une discussion depuis Découvrir.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('empty state shows clay illustration instead of disc icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppEmptyState(
          title: 'Aucune conversation',
          illustrationAsset: 'assets/images/empty/empty_chat.png',
          icon: Icons.chat_bubble_outline,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
  });
}
