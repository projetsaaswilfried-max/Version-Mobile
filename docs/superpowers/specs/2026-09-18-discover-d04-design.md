# Design : Découvrir D04 paywall + bannières

Date : 2026-09-18  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34) (même branche que D01)  
Réfs : PRD §3 / §7 / §11, screens-prd D04 / P02, design-inspiration (bottom sheet), D01

## Contexte

D01 livre la liste. Sur le web, un compte FREE / CANCELED non staff voit :
1. un sheet Premium à **chaque** chargement Découvrir ;
2. des bannières (profil incomplet / aperçu non vérifié / scores incomplets).

D04 porte ce chrome sur mobile, **sans** paiement réel (P01 plus tard).

## Décisions produit

| Sujet | Choix |
|---|---|
| Approche | **B** : sheet + bannières Découvrir |
| Qui voit le sheet | `subscription_status` ∈ {`FREE`, `CANCELED`} et pas staff ; pas `ACTIVE` ; pas `EXPIRED` (mur D01) |
| Quand | Après un load **réussi** de la liste : `loadInitial` et `refresh`. Pas sur `loadMore` (évite le spam scroll) ni sur empty/erreur/EXPIRED |
| UI sheet | Bottom sheet (pas dialog). Copy type web « Découvre tout Agapeo » + 4 formules PRD §11 + Quitter / Fermer |
| Tap formule | Stub : ferme le sheet (paiement = P01) |
| Bannière incomplet | Si profil §6 incomplet : « invisible dans Découvrir » + Compléter → onboarding existant |
| Bannière aperçu | Si visiteur non `VERIFIED` : texte masquage + « Vérifier mon profil » (push stub / écran vérif s'il existe, sinon snackbar) |
| Bannière scores | Si traits utiles au score manquants (foi / pourquoi mariage / valeurs / loisirs) : copy web + Compléter → onboarding |
| Bandeau shell S02 | Conservé tel quel ; pas de 4e doublon |
| D02 / D03 / D05 / D06 | Hors slice |

## Formules (PRD §11)

| Formule | Prix |
|---|---|
| 1 semaine | 2 335 FCFA |
| Mi-mois (15 jours) | 4 086 FCFA |
| Mensuel | 7 003 FCFA |
| Trimestriel | 17 507 FCFA |

## Architecture

```
lib/features/discover/presentation/
  widgets/discover_premium_sheet.dart
  widgets/discover_status_banners.dart
  discover_body.dart          # injecte bannières + schedule sheet
  discover_state.dart         # flags visitor (verified, premium, …)
```

Données : réutiliser `VisitorContext` (déjà chargé via `GetDiscoverPage`) + `profileCompletenessProvider` pour l’incomplet §6. Traits score : `visitor.traits` + champs déjà sur le profil visiteur.

Domain pur optionnel : `bool shouldShowDiscoverPremiumSheet({required String subscriptionStatus, required bool isStaff})`.

## États

| Condition | Sheet | Bannières |
|---|---|---|
| ACTIVE | non | aperçu / scores si besoin |
| FREE / CANCELED | oui après load OK | selon profil |
| EXPIRED | non (mur) | non |
| Loading / erreur | non | non |

## Tests

- Domain / helper : FREE → true, ACTIVE → false, EXPIRED → false, staff → false
- Widget : sheet présent après load FREE ; absent si ACTIVE ; Quitter ferme
- Widget : bannières selon flags ; Compléter appelle callback
- `flutter analyze` + `flutter test` ; `ios_dev.sh restart`

## Hors scope

- Checkout Chariow / SasPay
- D02 recherche / filtres
- Fiche, like, invitation
- Popup Premium **accueil** 1×/session (P02 home, pas D04)
