import 'package:agapeo/core/config/app_assets.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_svg.dart';
import 'package:agapeo/features/messages/presentation/thread/widgets/thread_composer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/voice_note_recorder_fake.dart';

Finder _svg(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppSvg && widget.assetPath == asset,
);

void main() {
  testWidgets('champ vide affiche le micro ; du texte affiche envoyer', (
    tester,
  ) async {
    final recorder = FakeVoiceNoteRecorder();
    addTearDown(recorder.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ThreadComposerBar(
            enabled: true,
            sending: false,
            onSend: (_) {},
            onAttach: () {},
            onSendVoice: (_, __) {},
            recorder: recorder,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Note vocale'), findsOneWidget);
    expect(_svg(AppAssets.icMic), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Salut');
    await tester.pump();

    expect(find.byTooltip('Envoyer'), findsOneWidget);
    expect(_svg(AppAssets.icSend), findsOneWidget);
  });

  testWidgets('micro lance l\'enregistrement ; poubelle annule', (
    tester,
  ) async {
    final recorder = FakeVoiceNoteRecorder();
    addTearDown(recorder.dispose);
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ThreadComposerBar(
            enabled: true,
            sending: false,
            onSend: (_) {},
            onAttach: () {},
            onSendVoice: (_, __) => sent++,
            recorder: recorder,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Note vocale'));
    await tester.pump();
    await tester.pump();

    expect(recorder.startCalls, 1);
    expect(find.byTooltip('Annuler'), findsOneWidget);
    expect(_svg(AppAssets.icTrash), findsOneWidget);
    expect(find.byTooltip('Envoyer la note vocale'), findsOneWidget);
    expect(_svg(AppAssets.icSend), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Annuler'));
    await tester.pump();
    await tester.pump();

    expect(recorder.cancelCalls, 1);
    expect(sent, 0);
    expect(find.byTooltip('Note vocale'), findsOneWidget);
  });

  testWidgets('stop envoie la note après au moins une seconde', (tester) async {
    final recorder = FakeVoiceNoteRecorder();
    addTearDown(recorder.dispose);
    String? sentPath;
    var sentDuration = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ThreadComposerBar(
            enabled: true,
            sending: false,
            onSend: (_) {},
            onAttach: () {},
            onSendVoice: (path, duration) {
              sentPath = path;
              sentDuration = duration;
            },
            recorder: recorder,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Note vocale'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('0:02'), findsOneWidget);

    await tester.tap(find.byTooltip('Envoyer la note vocale'));
    await tester.pump();

    expect(recorder.stopCalls, 1);
    expect(sentPath, recorder.lastStartPath);
    expect(sentDuration, 2);
  });

  testWidgets('micro refusé affiche un toast', (tester) async {
    final recorder = FakeVoiceNoteRecorder(hasPermissionResult: false);
    addTearDown(recorder.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ThreadComposerBar(
            enabled: true,
            sending: false,
            onSend: (_) {},
            onAttach: () {},
            onSendVoice: (_, __) {},
            recorder: recorder,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Note vocale'));
    await tester.pump();
    await tester.pump();

    expect(recorder.startCalls, 0);
    expect(
      find.text('Autorise le micro pour envoyer une note vocale.'),
      findsOneWidget,
    );
  });
}
