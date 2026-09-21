# Design : Messages M02 fil (+ M03/M04 partiels, fakes)

Date : 2026-09-19  
PR : empilée sur [#35](https://github.com/BespokApps/agapeo-mobile/pull/35) (`feat/messages-m01`)  
Réfs : PRD §3 / §8, screens-prd M02–M04, design-inspiration (chat Orange),
spec M01 `docs/superpowers/specs/2026-09-19-messages-m01-design.md`

## Périmètre

Fil de conversation sur **fakes** (même `SeededMessagesRepository` / seed étendu), avec
états invitation et fil système dans la même PR.

| Inclus | Hors slice |
|---|---|
| Navigation liste → fil (`Navigator.push`) | Realtime, push, upload réel |
| Seed messages par `conversationId` fake | Visionneuse M05 (tap média = snackbar / no-op) |
| Bulles `TEXT` + tuiles `IMAGE` / `VIDEO` / `DOCUMENT` / `VOICE` (lecture seule) | Match M06, masquer M07 |
| Composer selon état : ACCEPTED (saisie + envoi local), PENDING entrant (Accepter / Refuser), PENDING sortant (attente), système (lecture seule) | Gate Premium réel (abo `ACTIVE`) |
| Accept → statut ACCEPTED + composer ; Refuse → retire la conv de la liste | Branchement Supabase messages |
| Soft-delete seed : « Message supprimé » | |

Tap ligne M01 : ouvre le fil (plus de snackbar « Conversation : bientôt »).

## Décisions

| Sujet | Choix |
|---|---|
| Découpage PR | Une PR thread empilée (M02 + M03/M04 partiels) |
| Data | Fakes only ; flag `kUseFakeMessagesConversations` reste `true` |
| Envoi | Texte seul, append local au seed en mémoire (session) |
| Médias | Affichage tuile, pas de player / picker |
| PENDING entrant | Barre Accepter / Refuser (pas de saisie) |
| PENDING sortant | Texte « En attente de réponse », pas de saisie |
| Système | Composer remplacé par « Les messages Agapeo sont en lecture seule » |
| Empty fil | « Pas encore de messages » |
| AppBar | Avatar + nom peer (ou « Agapeo ») ; pas de menu actions |

## UI

- Liste messages : plus récent en bas ; bulles moi / peer via tokens
- Types : texte ; image/vidéo (carte + libellé) ; doc (icône + nom) ; vocal (durée factice) ; système (ligne centrée)
- Composer / barre d’action selon statut conversation (voir tableau Inclus)

## Architecture

```
lib/features/messages/
  domain/entities/message.dart          # type, content, meta média, deleted…
  domain/repositories/…                 # + fetchMessages, sendText, accept/decline
  domain/usecases/…
  data/repositories/seeded_…            # seed messages + mutations locales
  presentation/thread/
    conversation_thread_page.dart
    conversation_thread_controller.dart
    widgets/ (bubbles, media tiles, invite bar, composer)
```

Liste M01 : `onTap` → `ConversationThreadPage(conversationId: …)` (passer aussi le résumé utile pour l’AppBar, ou le résoudre depuis le seed).

## Tests

- Domain : tri chronologique, soft-delete, modes composer / invite
- Widget : fil ACCEPTED (envoi local), PENDING (accept/refuse), système (pas de saisie)
- `flutter analyze` + `flutter test` messages

## Hors périmètre explicite

Realtime, pièces jointes réelles, accusés de lecture UI, « en train d’écrire », M05–M07, Supabase.
