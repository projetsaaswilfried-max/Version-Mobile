# Design : Messages M07 masquer la discussion (fakes)

Date : 2026-09-19  
PR : empilée sur [#38](https://github.com/BespokApps/agapeo-mobile/pull/38) (`feat/messages-m06-match`)  
Réfs : PRD §8 (masquer vs bloquer), screens-prd M07

## Périmètre

| Inclus | Hors slice |
|---|---|
| Menu ⋯ AppBar fil → « Masquer la discussion » | Swipe liste M01 |
| Dialog de confirmation | Bloquer |
| OK → retire la conv du seed + pop fil + refresh liste | Réapparition auto au nouveau message |
| Applicable aussi au fil système | Supabase `hidden_at` |

## Décisions

| Sujet | Choix |
|---|---|
| Entrée | PopupMenu AppBar |
| Data | `hideConversation(id)` sur `SeededMessagesRepository` (retire liste + messages + match) |
| Copy dialog | Titre « Masquer la discussion ? » ; corps : masquage pour toi seulement, pas une suppression |
| Actions | Annuler / Masquer |

## Architecture

```
domain/repositories : + hideConversation
seeded_… : remove conv
presentation/thread : menu + dialog + controller.hide()
```

## Tests

Widget : ouvrir menu → confirm → page pop ; Annuler laisse le fil.

## Hors périmètre

M07 swipe, block, Supabase.
