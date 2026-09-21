# Design : Feedback AppToast + confirmation déconnexion

Date : 2026-09-21  
Branche cible : `feat/feed-discover-messages` (ou `feat/feedback-toast-signout`)  
Réfs : `AppToast`, `AppConfirmDialog`, Failure domain, hub Profil / Suspendu / Abonnement expiré

## Problème

Les succès et erreurs passent encore souvent par `SnackBar` Material
(`ScaffoldMessenger`), alors que `AppToast` existe pour un feedback visible
même au-dessus des bottom sheets. La déconnexion s'exécute sans confirmation
sur toutes les surfaces qui l'offrent.

## Décisions produit (validées)

| Sujet | Choix |
|---|---|
| Canal feedback | **Erreurs et succès** via `AppToast` (`isError: true` / `false`) |
| Textes | Garder les libellés FR déjà clairs ; adoucir seulement les messages techniques / anglais / bruts |
| Erreurs inline formulaire | **Hors scope** (reste sous le champ / `saveError` local) |
| Déconnexion | Confirmation `AppConfirmDialog` sur **toutes** les pages qui appellent `signOut` |
| Approche | Helper central + migration des call sites SnackBar de feedback |

## Périmètre

### Inclus

- Remplacer les `SnackBar` de feedback (succès / erreur / « bientôt ») par `AppToast`
- Helper d'affichage (ex. wrapper mince autour de `AppToast.show`) si utile pour homogénéiser
- Helper `userFacingMessage` (Failure et/ou String) : ne réécrit que si le message
  semble technique (anglais, code Postgrest, stack-like, vide) → fallback FR générique
  aligné sur les défauts Failure (`NetworkFailure`, `ServerFailure`, `UnknownFailure`…)
- Confirmation déconnexion :
  - hub Profil (`ProfileTabPage`)
  - compte suspendu
  - abonnement expiré
- Copy confirm proposée :
  - titre : `Se déconnecter ?`
  - message : `Tu pourras te reconnecter à tout moment.`
  - confirm : `Déconnexion`
  - cancel : `Annuler`

### Hors scope

- Refonte des `Failure` / mapping repository (sauf consommation côté UI)
- Remplacer les erreurs affichées inline dans les formulaires
- Intercepteur global `ScaffoldMessenger`
- Nouveaux toasts pour des chemins qui n'avaient aucun feedback

## Call sites SnackBar connus (à migrer)

| Zone | Fichier | Nature |
|---|---|---|
| Auth Google | `google_auth_button.dart` | erreur |
| Deep link auth | `auth_deep_link_listener.dart` | erreur |
| Gate post-auth | `navigate_after_auth.dart` | erreur |
| Onboarding | `onboarding_flow_page.dart` | erreur |
| Compte save | `account_save_feedback.dart` | succès |
| Mon Profil | `my_profile_page.dart` | succès |
| Email / MDP | `change_email_page.dart`, `change_password_page.dart` | succès |
| Fil | `feed_body.dart`, `feed_comments_sheet.dart`, `post_detail_page.dart`, `feed_post_card.dart` | erreur / succès |
| Découvrir | `discover_body.dart`, `discover_search_page.dart`, `discover_invite_sheet.dart` | bientôt / succès / erreur |
| Messages | `conversation_thread_page.dart` | succès / bientôt |
| Safety | `profile_safety_sheet.dart`, `report_sheet.dart` (`confirmAndBlock`) | succès / erreur |

Les call sites qui utilisent déjà `AppToast` (ex. like / favori Découvrir) restent.

## Règles UX

1. Un seul toast à la fois (comportement actuel `AppToast._current`)
2. Succès : fond sombre (`isError: false`) ; erreur : fond error
3. Ne pas appeler `AppToast` pendant un `build` synchrone sans nécessité :
   le widget reporte déjà l'insertion au frame suivant
4. Après succès + `Navigator.pop`, afficher le toast **avant** ou juste après
   pop avec un `context` encore monté / root overlay (pattern actuel Discover /
   sheets) : préférer `context` de l'écran qui a le Scaffold parent si le sheet
   se ferme

## Confirmation déconnexion

Helper partagé (ex. `confirmAndSignOut(context, ref)`) :

1. `AppConfirmDialog.show(...)`
2. Si confirmé : `await ref.read(signOutProvider)()`
3. Navigation vers `WelcomePage` avec `pushAndRemoveUntil` (comportement actuel hub)
4. Erreur sign-out rare : `AppToast` erreur via `userFacingMessage`

Même helper (ou même copy) sur Suspendu / Abonnement expiré.

## Tests

- Widget / unit : `userFacingMessage` garde un FR clair, adoucit un message anglais / vide
- Hub (ou helper) : tap Déconnexion → dialog ; Annuler → pas de signOut ; Confirmer → Welcome
- Au moins un test de migration représentatif (ex. `account_save_feedback` / invite sheet)
  si les tests existants assertent `SnackBar`

## Docs

- Append décision courte (D27) : feedback transient = `AppToast` ; déconnexion toujours confirmée
- Pas de changement PRD produit majeur

## Hors décisions

- Icône / durée toast : inchangées (3 s, design actuel)
- Libellés succès existants (« Profil enregistré. », « Enregistré. », etc.) : conservés
