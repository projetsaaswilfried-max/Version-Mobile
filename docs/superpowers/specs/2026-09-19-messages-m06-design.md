# Design : Messages M06 Match (fakes)

Date : 2026-09-19  
PR : empilée sur [#37](https://github.com/BespokApps/agapeo-mobile/pull/37) (`feat/messages-m05-image-viewer`)  
Réfs : PRD §9, screens-prd M06, specs M02/M05

## Périmètre

Bandeau Match sous l’AppBar d’un fil `ACCEPTED` (fakes), avec proposer /
accepter / refuser / annuler.

| Inclus | Hors slice |
|---|---|
| Bandeau états + CTAs | Emails / notifications félicitations |
| Seed match par `conversationId` | Effet Découvrir `is_matched` réel |
| Mutations locales | Table Supabase `matches` |
| Invisible si système ou invitation PENDING | M07 masquer |

Refus ou annulation → retour à « aucun match ».

## Décisions

| Sujet | Choix |
|---|---|
| Placement | Bandeau sous AppBar |
| Data | Dans `SeededMessagesRepository` (approche A) |
| États | `none` / `pending` (+ `isIncoming`) / `accepted` |
| Léa (`fake-accepted-1`) | Démarre à `none` |
| Fil système / PENDING invite | Pas de bandeau |

## UI bandeau

| État | Contenu |
|---|---|
| none | CTA « Proposer un match » |
| pending sortant | « En attente de réponse » + Annuler |
| pending entrant | Accepter / Refuser |
| accepted | « Vous êtes en couple » + Annuler |

## Architecture

```
domain/entities/conversation_match.dart
domain/match/match_banner_mode.dart   # mapping état → mode UI
domain/repositories/…                 # + fetch/propose/accept/decline/cancel
data/repositories/seeded_…            # map _matches
presentation/thread/widgets/thread_match_banner.dart
presentation/thread/conversation_thread_*.dart
```

## Tests

Domain transitions ; widget proposer/annuler ; entrant accept/refuse ; pas de bandeau système.

## Hors périmètre

M07, notifs, Supabase, Découvrir.
