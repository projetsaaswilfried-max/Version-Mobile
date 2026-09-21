# Design : Profil C02–C16 pages compte

Date : 2026-09-19  
Branche : `feat/profile-c01`  
Réfs : PRD §§3, 6, 8, 14–15, screens-prd C00–C16

## Périmètre

Rendre **fonctionnelles** toutes les sorties encore stub du hub Profil.

| Inclus | Hors lot |
|---|---|
| C02 Ma Foi (get/save) | Checkout Premium P01–P07 |
| C03 Plus d'infos (get/save, hors matching) | N01 push natif, Q3 |
| C05 Mes Favoris (liste, recherche, retirer) | Quota photos 10 |
| C06 Qui s'intéresse (compte toujours, identités si ACTIVE) | Selfie anti-usurpation avancé |
| C07 Confidentialité (switches présents en base) | `go_router` |
| C08 hub Compte & Sécurité | |
| C09 soumission vérif (caméra live, pas galerie) | |
| C10 email, C11 mot de passe | |
| C12 export JSON (partage, jamais email) | |
| C13 comptes bloqués + débloquer | |
| C15 suppression (confirm + RPC/delete, puis sortie) | |
| C16 photos vérifié : ajout caméra + selfie | |
| Aperçu « profil public » (soi, sans `record_profile_view`) | Fiche D03 tierce (réutilisée depuis C05/C06) |
| C04 / C01 / C14 déjà en place | |

## Décisions

| Sujet | Choix |
|---|---|
| Architecture | Un repo `ProfileAccountRepository` dans `profile/` (pas d'import Discover sauf ouverture D03 depuis listes) |
| Colonnes optionnelles | Best-effort comme C01 : sonde, masque le champ si absent |
| Confession | Éditable dans C02 (`church_denomination`) |
| Tags C03 | Virgules, plafonds 10 qualités / 12 passions / 12 valeurs |
| C06 identités | `ACTIVE` ou staff : noms réels. Sinon masque 2 caractères + flou + sheet Premium existant |
| C05 tap | `DiscoverProfileSheet` (fiche réelle) |
| C09 | Profil complet requis ; selfie **caméra uniquement** ; photos `DRAFT` → `PENDING` ; insert `verification_requests` |
| C11 | `UpdatePassword` auth déjà là |
| C16 | Page dédiée depuis C08. `VERIFIED` : nouvel ajout = caméra + selfie, pas C01 |
| Après save formulaires | Snackbar, pop, `invalidate(profileFieldsProvider)` + hub `loadInitial` |

## UI commune

AppBar + retour. Skeleton / erreur + Réessayer. Enregistrer sticky. Empty states avec une phrase + CTA. Confirmations en bottom sheet. Tokens only.
