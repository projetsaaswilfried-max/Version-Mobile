import '../entities/post_comment.dart';

class CommentThread {
  const CommentThread({required this.parent, required this.replies});

  final PostComment parent;
  final List<PostComment> replies;
}

List<CommentThread> groupCommentThreads(List<PostComment> comments) {
  final byId = {for (final comment in comments) comment.id: comment};
  final replies = <String, List<PostComment>>{};
  final roots = <PostComment>[];
  for (final comment in comments) {
    final rootId = _rootId(comment, byId);
    if (rootId == null) {
      roots.add(comment);
    } else {
      replies.putIfAbsent(rootId, () => []).add(comment);
    }
  }
  return [
    for (final parent in roots)
      CommentThread(parent: parent, replies: replies[parent.id] ?? const []),
  ];
}

PostComment replyTarget(PostComment comment, List<PostComment> comments) {
  final byId = {for (final item in comments) item.id: item};
  final rootId = _rootId(comment, byId);
  if (rootId == null) return comment;
  return byId[rootId] ?? comment;
}

int visibleReplyCount(
  int replyCount, {
  bool expanded = false,
  int preview = 0,
}) {
  if (expanded) return replyCount;
  if (preview <= 0) return 0;
  return preview < replyCount ? preview : replyCount;
}

String repliesToggleLabel({required int count, required bool expanded}) {
  if (expanded) return 'Masquer les réponses';
  if (count == 1) return 'Voir 1 réponse';
  return 'Voir les $count réponses';
}

String? _rootId(PostComment comment, Map<String, PostComment> byId) {
  var current = comment;
  final seen = <String>{current.id};
  while (true) {
    final parentId = current.parentId;
    if (parentId == null || !byId.containsKey(parentId)) return null;
    final parent = byId[parentId]!;
    final grandParentId = parent.parentId;
    if (grandParentId == null || !byId.containsKey(grandParentId)) {
      return parent.id;
    }
    if (!seen.add(parent.id)) return parent.id;
    current = parent;
  }
}
