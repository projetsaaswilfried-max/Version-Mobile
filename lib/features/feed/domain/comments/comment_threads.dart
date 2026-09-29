import '../entities/post_comment.dart';

class CommentThread {
  const CommentThread({required this.parent, required this.replies});

  final PostComment parent;
  final List<PostComment> replies;
}

/// Groupe les commentaires par fil racine, réponses aplaties sous chaque
/// racine (pas d'indentation multi-niveaux à l'affichage).
///
/// Deux ordres différents, comme le web : les fils (commentaires racines)
/// du plus récent au plus ancien (lecture façon fil d'actu), mais à
/// l'intérieur d'un fil, les réponses (à n'importe quelle profondeur) du
/// plus ancien au plus récent (lecture façon conversation). Trié ici
/// explicitement plutôt que de dépendre de l'ordre de la requête - une
/// réponse-à-une-réponse doit toujours suivre son parent, quel que soit
/// l'ordre/horodatage en entrée.
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
  roots.sort(_byCreatedAtDesc);
  for (final children in childrenOf.values) {
    children.sort(_byCreatedAtAsc);
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

int _byCreatedAtAsc(PostComment a, PostComment b) {
  final aAt = a.createdAt;
  final bAt = b.createdAt;
  if (aAt == null && bAt == null) return 0;
  if (aAt == null) return 1;
  if (bAt == null) return -1;
  return aAt.compareTo(bAt);
}

int _byCreatedAtDesc(PostComment a, PostComment b) => _byCreatedAtAsc(b, a);

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
