# Filtres Découvrir D02+ Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or executing-plans.

**Goal:** Recherche + sheet filtres réels pour ACTIVE/staff ; filtre client sur vivier D01.

**Spec:** `docs/superpowers/specs/2026-09-19-discover-filters-design.md`

## Tasks

### Task 1: DiscoverQuery + filter domain
- Entity `DiscoverQuery` + `filterDiscoverProfiles(list, query)`
- Tests matching case-insensitive contains
- Commit `feat(discover): query et filtre client D02+`

### Task 2: Controller + UI
- State `query` ; loadInitial applique filtre après page
- `DiscoverFiltersSheet` ; wire search bar unlocked
- Tests
- Commit `feat(discover): sheet filtres et recherche D02+`

## Hors plan
- Filtres serveur exhaustifs, tous champs §6
