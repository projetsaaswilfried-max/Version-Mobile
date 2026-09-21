import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_network_image.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:agapeo/features/messages/presentation/thread/message_image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('viewer affiche AppNetworkImage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MessageImageViewerPage(
          imageUrl: 'https://picsum.photos/seed/agapeo-m05/800/1200',
          title: 'Photo',
        ),
      ),
    );

    expect(find.byType(AppNetworkImage), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('tap IMAGE ouvre viewer ; VIDEO snackbar', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = SeededMessagesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [messagesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConversationThreadPage(conversationId: 'fake-accepted-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('thread-media-m3')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('thread-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('thread-media-m3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MessageImageViewerPage), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('thread-media-m4')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('thread-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('thread-media-m4')));
    await tester.pump();
    // AppToast insère son OverlayEntry au frame suivant (postFrameCallback).
    await tester.pump();

    expect(find.text('Média : bientôt'), findsOneWidget);
  });
}
