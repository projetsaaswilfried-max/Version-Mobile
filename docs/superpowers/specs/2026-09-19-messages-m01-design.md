# Design : Messages M01 liste des discussions

Date : 2026-09-19  
PR : [#35](https://github.com/BespokApps/agapeo-mobile/pull/35) (base Découvrir #34)  
Réfs : PRD §3 / §8, screens-prd M01, mobile-addendum §2, design-inspiration (bottom sheet plus tard)

## Périmètre

Remplacer le placeholder Messages par la **liste des conversations** du membre connecté.

| Inclus | Hors slice |
|---|---|
| Liste triée (dernier message / activité) | M02 fil chat |
| Recherche locale sur nom / aperçu | Realtime Postgres Changes (M01b) |
| Badge non-lus | Accept/refuse invitation (M03) |
| Badge / libellé `PENDING` (invitation) | Match M06, masquer M07 |
| Empty « Aucune conversation » | Push |
| Mur EXPIRED si abo expiré (aligné Découvrir) | |

## Décisions

| Sujet | Choix |
|---|---|
| Approche | Feature `messages/` Clean Architecture légère |
| Data | Temporaire : `SeededMessagesRepository` (fakes). Plus tard : participants + `hidden_at` null + peer + dernier message + unread |
| EXPIRED | Mur plein écran (copy messages) ; pas de liste |
| Tap ligne | Snackbar `Conversation : bientôt` (M02) |
| Recherche | Filtre client sur displayName / preview |
| Refresh | Pull-to-refresh ; pas de realtime dans M01 |

## UI

- AppBar / titre Messages
- Champ recherche
- Liste : avatar, nom, preview (1 ligne), heure relative, badge unread, chip Invitation si PENDING et destinataire
- Empty : « Aucune conversation » + texte démarrer depuis Découvrir
- Skeleton / erreur + Réessayer

## Architecture

```
lib/features/messages/
  domain/entities/conversation_summary.dart
  domain/repositories/messages_repository.dart
  domain/usecases/get_conversations.dart
  data/…
  presentation/messages_list_page.dart (ou body)
  di/messages_providers.dart
```

Brancher `MessagesTabPage` → body liste.

## Tests

Domain parsing/unread ; widget empty / liste / EXPIRED / search ; analyze + test.
