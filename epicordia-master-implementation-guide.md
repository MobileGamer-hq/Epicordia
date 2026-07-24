# Epicordia — Master Implementation Guide
*The single entry point for building Epicordia. This document indexes every companion document, and consolidates the database schema — which has been patched across three prior documents — into one final, authoritative version. Read this first; dive into the companion docs for full depth on any one area.*

---

## 1. What Epicordia is, in one paragraph

Epicordia is a fully offline, no-login, cross-platform (phone/tablet/desktop) Flutter app combining Milanote-style infinite-canvas visual boards, Notion-style structured notes/tasks ("one record, many views"), and a canvas-optional design so the same app works as a plain notes-and-tasks list for anyone who never wants to touch a board. It stores everything locally via Drift/SQLite, with no cloud sync by design — data portability comes from manual export/import and automatic local backups instead.

---

## 2. Document index — what's where

| Document | Contents | Read this when... |
|---|---|---|
| `offline-board-app-research-and-spec.md` | Original product research (Milanote/Notion/Samsung Notes analysis, community sentiment research, pillars, pin type overview, tech stack rationale) | You want the *why* behind the product decisions |
| `epicordia-app-flow.md` | Full navigation map, screen inventory, detailed user flows (daily use, Create flow, Quick Capture, search, calendar sync, backup) | You need to know how screens connect to each other |
| `epicordia-ai-design-document.md` | Functional/product spec — screen-by-screen behavior, pin type reference, task data model, cross-cutting rules | You're implementing a specific screen's behavior |
| `epicordia-ui-design-document.md` | Visual design system — colors (light/dark), typography, radius scale, components, motion/animation language | You're building or styling any UI component |
| `epicordia-figma-design-prompt.md` | Condensed design brief for generating UI mockups in Figma | You're producing visual mockups before/alongside development |
| `epicordia-card-and-content-spec.md` | Card anatomy per pin type, Markdown storage rules, the single-source-of-truth (no duplicates) principle | You're implementing how a card looks/stores its content |
| `epicordia-schema-corrections.md` | Six corrections to the original schema (nullable boardId, unified status field, cascade deletes, recurrence pre-generation, Markdown enforcement) | Historical record of *why* the schema changed — the result is already folded into §4 below |
| `epicordia-per-card-schema.md` | Exact `content` shape for every pin type, plus `parentFrameId`/`linkedBoardId`/`groupPinId` additions | You need the precise field layout for a specific pin type's data |
| `epicordia-connector-implementation.md` | Connector geometry (edge-intersection, Bézier curves, arrowheads), rendering approach, creation/selection interaction, coordinate conversion | You're implementing connectors/arrows specifically |
| `epicordia-board-screen-implementation.md` | Package research (why custom-built over `vyuh_node_flow`/`graph_flow`), full gesture/layer architecture, bending connectors, pan/zoom conventions, performance techniques | You're implementing the Canvas mode board screen itself |
| `antigravity-development-plan.md` | The 10-phase build order with Definition of Done + Gate Check per phase | You're sequencing the actual build |

**Recommended reading order for a build agent:** this document → `epicordia-ai-design-document.md` → `epicordia-app-flow.md` → `epicordia-ui-design-document.md` → `antigravity-development-plan.md` (start building) → the schema/connector/board-screen docs as each relevant phase comes up.

---

## 3. Core architecture (recap)

- **Storage:** Drift (type-safe Dart ORM) over SQLite, on-device, no server, no accounts.
- **Layers:** UI (Flutter widgets) → Repository (Riverpod, exposes Streams/Futures) → DAO (type-safe SQL) → `AppDatabase` (Drift/SQLite, single source of truth, `PRAGMA foreign_keys = ON`).
- **Reactivity:** every screen watches a Stream from its Repository — editing a task anywhere (its board, the Tasks tab, Today) is one write, reflected everywhere instantly, because there is exactly one row per note/task, not a copy per surface it appears on.
- **Canvas engine:** custom-built (not a third-party node-graph library) — pan/zoom/marquee-select plumbing adapted from a lightweight foundation package (e.g. `infinite_canvas`), with a purpose-built batched `CustomPainter` for connectors, since Milanote's free-edge-to-edge connector style doesn't fit the port-based model of the more feature-complete node-graph packages evaluated. Full rationale in `epicordia-board-screen-implementation.md` §1.

---

## 4. Final consolidated database schema

This is the authoritative schema — it supersedes the versions shown piecemeal in the original AI design document, the schema-corrections document, and the per-card-schema document. Where those documents explain the *reasoning* behind a field, this table is the answer.

### `Boards`
| Field | Type | Notes |
|---|---|---|
| `id` | PK | |
| `title` | text | |
| `parentBoardId` | nullable FK → `Boards.id` | Self-reference; powers nesting + breadcrumbs |
| `defaultViewMode` | enum: `canvas` / `list` / `focus` | Set at board creation |
| `kanbanEnabled` | bool, default `false` | Opt-in per board; does **not** change whether `Tasks.status` exists — only how Focus view groups it |
| `milestoneDate` | nullable date | One milestone per board |
| `createdAt`, `modifiedAt` | timestamps | |

### `Pins`
| Field | Type | Notes |
|---|---|---|
| `id` | PK | |
| `boardId` | **nullable** FK → `Boards.id` | Null = unfiled (Unsorted tray); no "inbox" board exists |
| `type` | enum | `note`, `task`, `tasklist`, `checklist`, `image`, `drawing`, `handwriting`, `link`, `file`, `audio`, `colorSwatch`, `heading`, `table`, `frame`, `board` |
| `x`, `y`, `w`, `h`, `zIndex`, `rotation` | nullable numerics | Null until actually placed on a canvas |
| `colorTag` | nullable | One of the six pin-tag colors from the UI doc |
| `content` | text | Markdown for `note`; JSON for structured types — exact shape per type in `epicordia-per-card-schema.md` §"Per pin type" |
| `parentFrameId` | nullable, self-referencing FK → `Pins.id` | Frame/Group membership |
| `linkedBoardId` | nullable FK → `Boards.id` | Only on `type = 'board'` pins — which child board this tile opens |
| `createdAt`, `modifiedAt` | timestamps | |

### `Tasks`
| Field | Type | Notes |
|---|---|---|
| `id` | PK | |
| `boardId` | **nullable** FK → `Boards.id` | Null = unfiled |
| `pinId` | nullable FK → `Pins.id` | Set once placed solo on a canvas |
| `groupPinId` | nullable FK → `Pins.id` | Set if this task is a member of a Task List pin — mutually exclusive with `pinId` at the application level |
| `title` | plain text | No Markdown — renders identically everywhere without a renderer |
| `notes` | **Markdown** text | Confirmed requirement, not arbitrary plain text |
| `dueDate` | nullable date | Hard deadline |
| `scheduledDate` | nullable date | "Plan to work on this" — always shown/edited as a separate field from `dueDate` |
| `priority` | enum/int | |
| `status` | enum: `notStarted` / `inProgress` / `done` | **Always present on every task**, regardless of `kanbanEnabled` — the single field the animated Status Control reads/writes; kanban columns are a grouped view of this same field, never a second field |
| `recurrenceRule` | nullable text (RRULE) | Set only on a recurrence "master" row |
| `recurrenceParentId` | nullable, self-referencing FK → `Tasks.id` | Set on generated occurrence rows, pointing back to their master; master rows are not themselves shown as due/actionable items |
| `calendarEventId` | nullable | Link to synced device calendar event |
| `createdAt`, `modifiedAt` | timestamps | |

### `TaskDependencies`
| Field | Type | Notes |
|---|---|---|
| `taskId` | FK → `Tasks.id`, `ON DELETE CASCADE` | |
| `dependsOnTaskId` | FK → `Tasks.id`, `ON DELETE CASCADE` | Cycle prevention (direct + transitive) enforced at the application layer before insert |

### `Connectors`
| Field | Type | Notes |
|---|---|---|
| `id` | PK | |
| `boardId` | FK → `Boards.id` | |
| `fromPinId`, `toPinId` | FK → `Pins.id` | A connector is an edge between two pins, never its own Pin row |
| `label` | nullable text | Short annotation on the arrow |
| `style` | enum: `straight` / `curved` | Default `straight` |
| `bendOffsetX`, `bendOffsetY` | nullable doubles | Manual curve override, relative to the auto-computed midpoint; `null` = fully automatic curve (see `epicordia-board-screen-implementation.md` §3) |

### `Attachments`
| Field | Type | Notes |
|---|---|---|
| `id` | PK | |
| `pinId` | FK → `Pins.id`, `ON DELETE CASCADE` | |
| `filePath`, `fileType` | text | Local file reference — the actual binary never lives in the database |
| `createdAt` | timestamp | |

### Cascade delete rules — consolidated
- Delete a **Board** → cascade-delete its Pins and its Tasks (both matched by `boardId`) → which in turn cascade-deletes their Attachments, Connectors, and TaskDependencies.
- Delete a **Frame** pin → do **not** delete its children — instead set their `parentFrameId` to `null` (un-group, don't destroy).
- Delete a **Task list** pin → cascade-delete every Task whose `groupPinId` points to it (they only exist as members of that list).
- Delete a recurring **master Task** → cascade-delete every Task whose `recurrenceParentId` points to it.
- Delete any **Task** (directly, or via any cascade above) → cascade-delete its TaskDependencies rows (as either `taskId` or `dependsOnTaskId`).

---

## 5. Screens (condensed — full detail in `epicordia-app-flow.md`)

Dashboard (landing) · Boards Hub · Board screen (Canvas/List/Focus) · Pin Editor (floating popover / side panel / bottom sheet, by weight) · Notes tab · Tasks tab · Calendar view · Create button + Type Selector → To-do list / Note / New Board creation pages · Search overlay · Settings · App Lock.

## 6. Design system essentials (condensed — full detail in `epicordia-ui-design-document.md`)

- **Primary:** `#2F53DB` (light) / `#6E96FF` (dark) — deliberately different values per mode for contrast.
- **Neutrals:** warm off-white (`#FAFAF8`) / near-black (`#101216`), never pure white/black.
- **Shape:** `radius-xs` (6px) → `radius-pill` (999px) semantic scale; every clickable icon in a uniform circular container.
- **Motion:** spring-based easing everywhere; floating anchored popovers for light interactions, side panels/sheets for medium, full modals reserved for heavy flows only; the animated Task Status Control (ring) replaces checkboxes entirely.
- **Create flow:** persistent pill "Create" button → custom floating Type Selector (To-do list / Note / Board) → morph transition into the matching creation page.

## 7. Build order (condensed — full detail in `antigravity-development-plan.md`)

Phase 0 Foundation → Phase 1 Schema (§4 above) → Phase 2 Core simple views (Dashboard, Notes/Tasks tabs, Quick Capture, Create flow, Zen mode) → Phase 3 Boards & Canvas engine → Phase 4 Project management depth (kanban opt-in, milestones, dependencies, recurrence) → Phase 5 Calendar sync & notifications → Phase 6 Remaining pin types & connectors (including bending) → Phase 7 Security & data portability → Phase 8 Cross-platform responsive polish → Phase 9 Release prep. Each phase has a hard Gate Check before the next begins — schema corrections found *after* Phase 1 was already built (documented in `epicordia-schema-corrections.md`) are the reason this discipline matters.

---

## 8. Handoff prompt for Antigravity

> Build Epicordia using this Master Implementation Guide as the primary reference, and its indexed companion documents for full depth on any specific area (§2 above tells you which document covers what). The database schema in §4 of this guide is final and authoritative — it supersedes any earlier partial version you may have already built; if your current schema differs, correct it to match §4 before proceeding with new feature work. Follow the phased build order in `antigravity-development-plan.md`, respecting each phase's Gate Check before moving to the next. Flag any ambiguity or conflict between documents rather than guessing.
