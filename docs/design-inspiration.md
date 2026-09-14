# Inspiration design — mobile

Sources visuelles à parcourir pour habiller les écrans mobile. **Le
comportement produit reste celui du [PRD](./Agapeo-Mobile-PRD.md)** — ce
fichier ne documente que la direction visuelle/interaction, pas de nouvelle
règle métier. Objectif : partir du flow web (parité fonctionnelle, voir
[mobile-addendum.md](./mobile-addendum.md)) mais dessiner des écrans qui se
sentent natifs — pas un site web redimensionné.

> **Contradiction à surveiller.** Le PRD §1 est explicite : *« Pas de swipe
> façon Tinder — Découvrir est une liste triée par compatibilité, pas une
> pile de cartes. »* Plusieurs sources ci-dessous (Datify, Orange Dating App)
> sont bâties autour du swipe de cartes. À piocher pour la carte de profil, les
> transitions, la messagerie, le livestream — **jamais pour restructurer
> Découvrir en pile swipable**, sauf décision produit explicite qui
> contredirait le PRD (à consigner dans [decisions.md](./decisions.md) si ça
> arrive).

---

## Sources

| Source | Lien | Type | À regarder pour |
|---|---|---|---|
| Datify — Dating App UI Kit | [Figma](https://www.figma.com/design/3m9BN6GTnX3Aniu7IHWOVV/Datify---Dating-App-UI-Kit--Preview-?node-id=4527-37251&p=f&t=vvTD1XF4ozuNR4zv-0) | UI kit payant (preview) | Cartes de profil, composants (chips de tags, badges de vérification), micro-interactions. **Pas** la structure swipe de Découvrir. |
| Orange Dating App (Flutter/Laravel) | [CodeCanyon](https://codecanyon.net/item/orange-dating-app-with-livestream-chat-gifts-payouts-flutter-laravel-full-app/41005672) | Template Flutter complet | Écrans de chat temps réel (texte/image/vidéo), UI de stories/posts, flux de paiement par pièces/cadeaux — transposable à la logique Premium/FCFA d'Agapeo. Swipe + livestream + coins hors périmètre PRD (§1, §22), à ignorer pour la structure. |
| Dating Mobile App Design | [Behance](https://www.behance.net/gallery/252935713/Dating-Mobile-App-Design) | Case study visuel | Ton général « premium, épuré » pour la découverte de profil et la messagerie. Pas de détail de palette/typo extrait automatiquement — à ouvrir directement. |
| Dating App — Free UI Kit | [Figma Community](https://www.figma.com/community/file/1105813760130731100/dating-app-free-ui-kit) | UI kit gratuit (communautaire) | Base de composants rapide (boutons, champs, cartes) à dupliquer/adapter aux tokens `core/theme` — jamais copier les couleurs telles quelles, toujours repasser par la charte Agapeo. |
| Nestle — Best Dating App UI Kit | [Figma](https://www.figma.com/design/v62qO6bhzB9K6cMdQ2rT2Y/Nestle-%E2%80%93-Best-Dating-App-UI-Kit-%7C-Modern---Clean-Figma-Mobile-App-Design--Community-?node-id=1-2&p=f&t=VMnqTJ2owvEiljsG-0) | UI kit communautaire | Direction « moderne, clean » — onboarding, formulaires multi-étapes (à rapprocher de l'assistant en 3–5 étapes du PRD §5). |
| Dating App UI Kit — Community | [Figma](https://www.figma.com/design/Eh6EP1OPOKXRuSHD29mKVE/Dating-App-UI-Kit---Community--Community-?node-id=113-7674&p=f&t=sEubynAStBtBxMfn-0) | UI kit communautaire | Variantes d'écrans de profil et de paramètres — utile pour habiller les 8 onglets "Mon Compte" (PRD §14). |

Les fichiers Figma ne sont pas exploitables par outil automatisé (accès
authentifié/rendu JS) — à parcourir manuellement dans l'éditeur.

---

## Écrans Agapeo à repenser en priorité (mapping PRD → inspiration)

| Écran Agapeo | Réf. PRD | Ce qu'on adapte du web | Ce qu'on regarde dans les sources |
|---|---|---|---|
| Découvrir (liste, pas swipe) | §7 | Structure liste + sections "Recommandée" / "Autres" | Carte de profil (Datify), badges vérifié/staff |
| Fiche profil complète | §6, §7 | Champs, masquage progressif | Mise en page profil détaillé, galerie photo (toutes sources) |
| Messagerie (invitation → accepté) | §8 | Statuts PENDING/ACCEPTED, bulles, accusés de lecture | Écrans de chat (Orange Dating App), indicateur "en train d'écrire" |
| Onboarding multi-étapes | §5 | 3–5 étapes, jamais bloquant | Formulaires par étapes, barre de progression (Nestle kit) |
| Vérification selfie | §6 | Capture caméra live obligatoire | Écrans de capture/consentement (à défaut dans ces kits génériques — probablement à concevoir spécifiquement) |
| Premium / paywall | §11 | Formules, popups de relance | Écrans de paywall/pricing (toutes sources) |
| Mon Compte (8 onglets) | §14 | Structure par onglets | Écrans de paramètres/profil (Community kit) |

---

## Ce qu'on ne prend jamais

- Le swipe de cartes en pile pour Découvrir (contredit PRD §1).
- Les mécaniques de coins/cadeaux/livestream (hors périmètre PRD §22).
- Les couleurs/typo brutes des kits — toujours repasser par `core/theme`
  (charte Agapeo : #E83E75 / #FE72B3, Bricolage Grotesque).
