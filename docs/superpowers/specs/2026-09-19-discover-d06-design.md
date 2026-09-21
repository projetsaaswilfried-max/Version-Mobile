# Design : Découvrir D06 invitation

Date : 2026-09-19  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34)  
Réfs : PRD §3 / §8 / §18 / §21, screens-prd D06, mobile-addendum, D03–D05

## Décisions (approbation blanket session)

| Sujet | Choix |
|---|---|
| Approche | **B** : sheet invitation + RPC réelle |
| Gates | !VERIFIED (et pas staff) → `DiscoverVerifySheet` ; FREE/CANCELED quota 3/mois civil épuisé → `DiscoverPremiumSheet` ; ACTIVE/staff → envoi OK |
| UI | Bottom sheet : destinataire (nom), champ message optionnel, Envoyer / Annuler |
| Envoi | RPC `create_conversation_with_participant` uniquement |
| Après succès | Fermer sheet invitation (+ snackbar succès) ; pas de nav M01 |
| Favori | Hors slice (stub) |
| M03 accept/refuse | Hors slice (messagerie) |

## Flux

```
tap Invitation (fiche)
  if !canInviteVerified → DiscoverVerifySheet ; stop
  if !canInviteQuota → DiscoverPremiumSheet ; stop
  else → DiscoverInviteSheet.show(profileId, displayName)
         → Envoyer → RPC → Ok : pop + snackbar « Invitation envoyée »
         → Err : snackbar message Failure
```

## Helper

```dart
bool canInviteDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => isStaff || visitorVerified;

// Quota : FREE/CANCELED → count invitations ce mois < 3
// ACTIVE/staff → illimité
```

Comptage : conversations `PENDING` (ou créées) où le visiteur est initiator dans le mois civil courant ; confirmer schéma à l’impl. Si impossible de compter → permettre l’envoi et laisser le serveur/RLS refuser.

## Architecture

- Domain : helpers + usecase `SendDiscoverInvitation` / `CountMonthlyInvitations`
- Data : RPC + éventuel count
- UI : `discover_invite_sheet.dart` ; wire bouton Invitation dans `DiscoverProfileSheet`

## Hors scope

- Favori, deep link messagerie, accepter/refuser invitation, écrire dans chat ACCEPTED
