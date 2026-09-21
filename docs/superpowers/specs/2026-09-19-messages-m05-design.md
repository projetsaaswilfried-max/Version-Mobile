# Design : Messages M05 visionneuse image

Date : 2026-09-19  
PR : empilée sur [#36](https://github.com/BespokApps/agapeo-mobile/pull/36) (`feat/messages-m02-thread`)  
Réfs : screens-prd M05, PRD §8 (types média), spec M02
`docs/superpowers/specs/2026-09-19-messages-m02-design.md`

## Périmètre

Remplacer le snackbar « Média : bientôt » pour les messages **IMAGE** par une
visionneuse plein écran (fakes).

| Inclus | Hors slice |
|---|---|
| Tap tuile `IMAGE` → push `MessageImageViewerPage` | Vidéo / doc / vocal |
| Fond sombre, image centrée | Pinch-zoom, swipe galerie |
| Fermer : back AppBar + geste système | Download, share, signaler |
| Seed : `mediaUrl` sur messages image fake | Upload réel, URLs signées Supabase |

Vidéo / doc / vocal : snackbar « Média : bientôt » inchangé.

## Décisions

| Sujet | Choix |
|---|---|
| Navigation | Route push (pas dialog) |
| Image | `AppNetworkImage` + URL placeholder seed |
| Entité | `Message.mediaUrl` (nullable) |
| Zoom / galerie | Non dans ce slice |

## UI

- Scaffold fond sombre (token surface/background adapté, pas de couleur magique hors tokens)
- AppBar transparente / sombre avec fermeture
- Image centrée, contenue (box fit contain)

## Architecture

```
lib/features/messages/
  domain/entities/message.dart          # + mediaUrl
  data/repositories/seeded_…            # URL sur IMAGE
  presentation/thread/
    message_image_viewer_page.dart
    conversation_thread_page.dart       # onMediaTap IMAGE → push
```

## Tests

- Widget : tap IMAGE ouvre viewer ; tap VIDEO garde snackbar
- `flutter analyze` + `flutter test` messages

## Hors périmètre

M06–M07, player audio/vidéo, Supabase attachments.
