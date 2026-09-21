# Messages Supabase A — liste Implementation Plan

**Goal:** Couper les fakes pour la liste M01 ; fil reste stub jusqu’à B.

**Spec:** `docs/superpowers/specs/2026-09-19-messages-supabase-a-list-design.md`

## Constraints

- Branche `feat/messages-supabase-a-list` depuis `feat/messages-m07-hide`
- Conventional Commits FR ; pas de cadratin
- `flutter test test/features/messages`

### Task 1

- [ ] `kUseFakeMessagesConversations = false`
- [ ] Améliorer message stub thread si besoin
- [ ] Test providers : flag false → pas Seeded par défaut (mock env ou test du const)
- [ ] Commit + PR empilée sur #39
- [ ] Hot restart ; vérifier liste réelle (compte connecté)
