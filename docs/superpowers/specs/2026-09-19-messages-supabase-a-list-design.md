# Design : Messages Supabase A — liste réelle

Date : 2026-09-19  
PR : empilée sur [#39](https://github.com/BespokApps/agapeo-mobile/pull/39) (`feat/messages-m07-hide`)  
Stack : A liste → B fil/send/invite/hide → C match → D médias

## Périmètre

| Inclus | Hors A |
|---|---|
| `kUseFakeMessagesConversations = false` | Fetch/send messages, invite, hide (B) |
| Repo live `MessagesRepositoryImpl` + `SupabaseMessagesDataSource` | Match (C) |
| Liste M01 sur données réelles (session Supabase) | Médias / signed URLs (D) |
| Seed conservé pour tests widget/unit | |
| Fil ouvert : erreur claire si méthodes thread encore stubs | |

## Décisions

| Sujet | Choix |
|---|---|
| Flag | `false` par défaut en prod/dev |
| Tests | Overrides `SeededMessagesRepository` / `FakeMessagesRepository` inchangés |
| Stubs thread | Message d’échec lisible (pas de crash) |
| Schéma | Best-effort existant (`messages_schema.dart`) ; documenter échecs réels si besoin |

## Hors périmètre

Realtime, B/C/D.
