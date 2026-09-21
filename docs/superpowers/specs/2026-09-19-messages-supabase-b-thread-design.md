# Design : Messages Supabase B — fil / send / invite / hide

Date : 2026-09-19  
PR : empilée sur [#40](https://github.com/BespokApps/agapeo-mobile/pull/40)  
Stack : A liste → **B fil** → C match → D médias

## Périmètre

| Inclus | Hors B |
|---|---|
| `fetchConversation` / `fetchMessages` via Supabase | Match (C) |
| `sendText` (insert `TEXT`) | Upload médias / signed URLs (D) |
| `acceptInvitation` / `declineInvitation` (status ACCEPTED / DECLINED) | Realtime |
| `hideConversation` (`hidden_at` sur participant) | |
| Mapping `Message` (type, content, deleted_at, sender) | Tuiles IMAGE avec URL réelle (placeholder / type only) |

Match methods restent en stub « slice C ».

## Décisions

| Sujet | Choix |
|---|---|
| Schéma | Best-effort (colonnes fallback comme M01) |
| Decline | `status = DECLINED` (liste filtre déjà DECLINED) |
| Hide | `conversation_participants.hidden_at = now()` |
| Send | Insert message ; pas d’attachement |

## Tests

Model mapping message ; repo impl avec fake remote ; analyze + test messages.
