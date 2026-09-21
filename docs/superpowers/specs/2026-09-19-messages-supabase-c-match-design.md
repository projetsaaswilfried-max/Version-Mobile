# Design : Messages Supabase C — Match

Date : 2026-09-19  
PR : empilée sur [#41](https://github.com/BespokApps/agapeo-mobile/pull/41)  
Stack : A → B → **C match** → D médias

## Périmètre

| Inclus | Hors C |
|---|---|
| `fetchMatch` / `propose` / `accept` / `decline` / `cancel` via table `matches` | Découvrir `is_matched` sync UI |
| Mapping PENDING/ACCEPTED (+ `isIncoming` si proposer ≠ moi) | Emails / notifs |
| Best-effort colonnes (comme messagerie) | Médias (D) |

Decline = `CANCELLED` (ou equivalent) → bandeau `none`.

## Hypothèses schéma `matches`

- Lien : `conversation_id` (fallback : paire de profils via participants)
- Initiateur : `proposer_id` / `initiated_by` / `requester_id` / `created_by`
- `status` : `PENDING` / `ACCEPTED` / `CANCELLED`
- Un seul actif (PENDING ou ACCEPTED) par conversation

## Tests

Fake remote + mapping status ; analyze + test messages.
