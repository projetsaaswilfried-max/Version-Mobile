import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract class PostShareSheet {
  Future<bool> share(String text);
}

class SharePlusPostShareSheet implements PostShareSheet {
  const SharePlusPostShareSheet();

  @override
  Future<bool> share(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    return result.status != ShareResultStatus.dismissed;
  }
}

final postShareSheetProvider = Provider<PostShareSheet>(
  (_) => const SharePlusPostShareSheet(),
);
