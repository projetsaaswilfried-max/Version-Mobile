# Design : surfaces store encore faisables

Date : 2026-09-19  
Branche : `feat/profile-c01`  
Réfs : PRD §§8, 11–15, 22, screens-prd N01 / L01–L10 / P01, addendum §3–5

## Périmètre

Tout ce qui n’attend pas Q2 (SasPay), Q3 (émetteur APNs) ni Q4 (Universal Links dashboard).

| Inclus | Hors lot |
|---|---|
| N01 liste + filtres + tout marquer lu | Push natif X04 |
| L04 Signaler (profil, post, message) | Checkout SasPay / Chariow |
| L05 Bloquer depuis fiche / fil | Upload vocal / vidéo chat |
| L01–L03 Support (1 OPEN, texte ; image optionnelle) | `go_router` |
| L06–L10 pages légales in-app (liens web) | Selfie anti-usurpation avancé |
| P01 Mon Plan (statut + tarifs, sans initiation paiement) | |
| Favori Découvrir : mêmes paires que C05 (`profile_id` d’abord) | |
| Quota photos 2 gratuit / 10 Premium (C01) | |
| Realtime fil de conversation (INSERT messages) | |

## Décisions

| Sujet | Choix |
|---|---|
| Architecture | Features `notifications/`, `safety/` (signalement + blocage), `support/`, `premium/` |
| Colonnes | Best-effort comme C01 / Favoris |
| Motifs L04 | Liste PRD §15, bottom sheet, détails optionnels |
| Blocage | Insert `blocks` + confirmation sheet ; immédiat côté UI (pop fiche / masquer fil) |
| Support EXPIRED | Mur existant ; pas d’entrée support |
| P01 CTA | « Paiement bientôt dans l’app » tant que Q2 n’est pas tranché |
| N01 badge | Compte non lus réel (plus le `0` en dur) |
| L10 | Lien `LegalUrls.childSafety` + liste depuis Compte & Sécurité |

## Hors reco (inchangé)

Q1 / V1 Découvrir, V2 / V3 RLS, IAP stores.
