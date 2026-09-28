import '../entities/post_comment.dart';

class CommentThread {
  const CommentThread({required this.parent, required this.replies});

  final PostComment parent;
  final List<PostComment> replies;
}

/// Groupe les commentaires par fil racine, réponses aplaties sous chaque
/// racine (pas d'indentation multi-niveaux à l'affichage).
///
/// L'ordre des réponses suit l'arbre (parent direct, puis immédiatement ses
/// propres réponses) plutôt qu'un simple tri par `created_at` global -
/// sinon une réponse-à-une-réponse peut apparaître avant la réponse à
/// laquelle elle répond dès que son `created_at` n'est pas strictement
/// postérieur (ex. données de test, horodatages égaux au jour près).
List<CommentThread> groupCommentThreads(List<PostComment> comments) {
  final byId = {for (final comment in comments) comment.id: comment};
  final childrenOf = <String, List<PostComment>>{};
  final roots = <PostComment>[];
  for (final comment in comments) {
    final parentId = comment.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(comment);
    } else {
      childrenOf.putIfAbsent(parentId, () => []).add(comment);
    }
  }
  List<PostComment> flattenReplies(String parentId) {
    final result = <PostComment>[];
    for (final child in childrenOf[parentId] ?? const []) {
      result.add(child);
      result.addAll(flattenReplies(child.id));
    }
    return result;
  }
  return [
    for (final root in roots)
      CommentThread(parent: root, replies: flattenReplies(root.id)),
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
