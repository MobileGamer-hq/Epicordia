# Epicordia — AI Design Document
*Functional & structural specification, written for an AI build agent (Antigravity). Pairs with `epicordia-app-flow.md` (navigation) and `epicordia-ui-design-document.md` (visual system). Build order and quality gates are in `antigravity-development-plan.md` — this document defines *what* to build; that one defines *in what order and how to verify it*.*

---

## 1. Product summary

Epicordia is a fully offline, no-login, cross-platform (phone/tablet/desktop) Flutter app combining:
- **Milanote-style infinite canvas boards** — freeform, nestable, drag-and-drop pins.
- **Notion-style "one record, many views"** — the same task/note surfaces on its board, in global Notes/Tasks tabs, and in Calendar/Today.
- **A simple mode that never requires the canvas** — every board also renders as a plain List or a Focus (task-only) view; two global tabs (Notes, Tasks) work as stand-alone list apps.

Core non-negotiables: works 100% offline, no account/login ever, data stored locally, responsive across phone/tablet/desktop as equally first-class targets.

---

## 2. Screen-by-screen functional spec

### 2.1 Dashboard (Home) — the landing screen
Sections, top to bottom (order can adapt per breakpoint, but all sections present on every device):
1. **Today strip** — tasks due today/overdue, each with a tappable animated status control (not a checkbox — see UI doc §5.4), tap the row to open.
2. **Boards** — all top-level boards as cards, with an **Important/Urgent** grouping surfaced above the general list. A board is flagged Important/Urgent automatically if it has an overdue task, a milestone within the next 3 days, or a blocked task chain nearing its dependency deadline — plus a manual "pin as important" override the user can set per board.
3. **Calendar Heatmap** — a GitHub-contributions-style grid showing activity density (notes/tasks created or completed) per day over the last ~3–6 months; tapping a day jumps to that day's Calendar view.
4. **Mini calendar** — current month, dots on days with due tasks/events; "View full calendar" opens the Calendar screen.

Functional rules:
- Every section reads live from the same underlying Drift data — no separate "dashboard cache" that can drift out of sync.
- Empty states matter here specifically: a brand-new install shows a friendly first-board/first-task prompt instead of blank sections.

### 2.2 Boards Hub
- Grid or list (user-togglable) of every top-level board.
- Each board card shows: title, a live thumbnail/preview matching its **default view mode**, item count, and last-modified time.
- New boards are created via the global **Create** button (§2.11) — there is no separate local "+ New board" control here; tapping it opens the Type Selector pre-focused on the Board option.

### 2.11 Create button & Type Selector
A single, deliberate, always-visible creation entry point — separate in purpose from Quick Capture (§2.7): Quick Capture is for capturing a stray thought instantly with zero decisions; Create is for intentionally starting a specific thing.
- The Create button opens a **custom floating popover** (never a native OS dropdown, per UI doc §5.2/§4.9) offering three choices: **To-do list**, **Note**, **Board**.
- Selecting one animates directly into the matching creation page (continuity/morph transition, not a plain screen swap): a To-do list creation page, a Note creation page, or the New Board page (title, Canvas/List default, kanban opt-in toggle).
- A newly created to-do list or note can be assigned to a board at creation time, or left unfiled — in which case it appears in the Unsorted tray exactly like a Quick Capture item, using the same underlying null-`boardId` mechanism (§2.7).
- A newly created board opens directly onto itself (empty), ready for the user to start adding pins.

### 2.3 Board screen
- One screen, three renderers driven by `Board.defaultViewMode`/user-selected mode: **Canvas**, **List**, **Focus**.
- **Canvas**: infinite pan/zoom; pins placed by `x,y`; drag-drop from the pin tray; multi-select via marquee/shift-click; snapping guides; nested board pins open child boards; connectors drawn between pins; frames group pins so dragging a frame moves its contents.
- **List**: same pins, reflowed top-to-bottom in manual/last-edited order; tasks render as rows with the animated status control (§5.4 of the UI doc) in place of a checkbox; notes as stacked cards; images as thumbnails with captions; drawings as thumbnail previews.
- **Focus**: task pins only. If `Board.kanbanEnabled` is true, shown as To Do/Doing/Done columns — these columns are simply a grouped view of each task's status-control state (§5.4 of the UI doc), not a separate field. If false, shown as a plain grouped list (by scheduled/due date) with the same status control, no columns.
- Breadcrumb bar always reflects the nesting path and supports jumping to any ancestor directly, not just one level back.
- Switching between Canvas/List/Focus must never create, delete, or duplicate data — only change rendering.

### 2.4 Pin Editor
- Type-specific form/editor (see pin type table in §3). Overlay weight follows the UI doc's §5.2 system: quick edits (status, priority, due date, color tag) open as a **floating popover anchored to the pin**, not a full editor; opening a pin's full content (editing a note's text, a task's description, a drawing) opens the **medium-weight** side panel on tablet/desktop (board stays visible behind it) or bottom sheet on phone.
- Every pin editor supports: delete, duplicate, change color/tag, and (for task pins) all task-specific fields from §4.
- Closing the editor auto-saves (no separate "Save" button required for simple edits — this reinforces the zero-friction principle); destructive actions (delete) always require a confirm step, shown as a floating popover, not a full-screen alert.

### 2.5 Notes tab / Tasks tab
- Flat, cross-board lists. Notes: searchable, inline-editable. Tasks: filterable by board, due date, priority, kanban stage (only for kanban-enabled boards), blocked/unblocked state, and scheduled date.
- These are true stand-alone experiences — a user should be able to use only these two tabs plus Quick Capture and never open a board, per the "canvas is optional" pillar.

### 2.6 Calendar view
- Month/week grid combining: task due dates, task scheduled/start dates (visually distinct from due dates — see §4), board milestones, and synced device-calendar events.
- Two-way sync: app tasks with due dates push to the device calendar; device events pulled in are shown read-only unless explicitly converted into an Epicordia task.

### 2.7 Quick Capture (Zen mode)
- Single text field + Save. No board picker, no metadata fields visible at capture time.
- A small toggle (e.g. a checkbox icon) lets the user mark it as a task vs. a note at the moment of capture, but nothing else is exposed here — everything else is added later from the Unsorted tray.
- Never lands in a hidden "Inbox board" the user has to learn to navigate into. Instead, captured items appear directly as small unfiled cards in the **Unsorted tray** (a shelf on the Dashboard, mirrored by the existing Unsorted counter badge on Boards Hub/Board screens) — see UI doc §4.6a. From there, an item is filed by dragging it onto a board thumbnail or by tapping it for a floating "Move to board…" popover. There is no separate Inbox screen to visit.

### 2.8 Search
- Full-text (SQLite FTS5) across note content, task titles/notes, and board titles.
- Results grouped by type (Boards / Notes / Tasks) with the parent board shown for context; selecting a result navigates per §3.5 of the App Flow doc.

### 2.9 Settings
Sections: Appearance (theme, accent), Default view mode, App Lock, Calendar sync, Notifications, Backup & Data (manual export/import, automatic backup schedule/retention, last-backup timestamp), Storage usage, About.

### 2.10 App Lock
- If enabled, gates the Dashboard behind PIN or biometric on cold start and on resume-from-background after a configurable timeout.
- Must not block emergency access to data via the OS-level file system in a way that would prevent the user's own manual export — app lock is a privacy screen, not encryption-at-rest (state clearly whether encryption is separately implemented; if not, document that explicitly rather than implying false security).

---

## 3. Full pin type reference

| Pin type | Core fields | Renders in Canvas | Renders in List | Renders in Focus |
|---|---|---|---|---|
| Board (nested) | title, thumbnail, childBoardId | Tile/folder card | Row with chevron to open | — |
| Note | rich text, color | Sticky card | Stacked card | — |
| Task card | see §4 | Card with animated status control | Row with animated status control | Column card or grouped row |
| Task list | multiple sub-items, each with its own status control | Grouped card | Grouped rows | Individual tasks flattened |
| Image | local file path, caption | Resizable image card | Thumbnail + caption | — |
| Drawing/Sketch | vector stroke data | Freeform overlay-capable card | Thumbnail preview | — |
| Handwriting | vector stroke data, optional recognized text | Ink card | Thumbnail + recognized text if available | — |
| Link | URL, cached title/favicon | Preview card | Row with favicon | — |
| Document/File | local file path, type | Thumbnail + open-in-system-viewer | Row with icon | — |
| Audio/Voice memo | local file path, duration | Waveform card | Row with play button | — |
| Color swatch | hex/RGB | Small swatch card | Swatch chip | — |
| Heading/Divider | text or none | Section label | Section header | — |
| Checklist (lightweight) | items, each with its own status control, no full task metadata | Simple list card | Rows | — |
| Connector/Arrow | fromPinId, toPinId | Drawn line/arrow | Not applicable (canvas-only concept) | — |
| Group/Frame | contained pin IDs, bounds | Resizable container | Not applicable | — |
| Table | rows/columns of cells | Grid card | Rendered as a simple table | — |

---

## 4. Task data model (functional view — see dev plan for schema types)

- `title`, `notes` (free text)
- `dueDate` — a hard deadline
- `scheduledDate` — separate "plan to work on this" date; UI must always label these distinctly and never let one silently double as the other
- `priority`
- `status`/kanban stage — a 3-state field (Not started / In progress / Done) always present and always shown via the animated **status control** (UI doc §5.4), never a plain checkbox. When `Board.kanbanEnabled` is true, this exact field is what places the task in its To Do/Doing/Done column — kanban is a grouped view of this field, not a separate one.
- `recurrenceRule` — in-app recurrence, independently generates future instances
- `calendarEventId` — link to a synced device calendar event, nullable
- `dependencies` — list of task IDs this task depends on; a task with unmet dependencies is **blocked**: visually greyed/locked on Canvas, badge in Focus/List/Tasks tab; completing a blocked task is prevented with a clear inline message pointing to the blocking task(s)
- Cycle prevention is enforced at creation time — the UI must not allow saving a dependency that would create a cycle (direct or transitive)

---

## 5. Cross-cutting functional rules

- **Offline-only, no network dependency for core function.** Link-preview fetching and calendar sync are the only features that touch the network/OS services; both degrade gracefully offline (link shows as plain URL text; calendar sync simply queues until connectivity/permission is available).
- **No account, no login, ever** — nothing in any flow should ask for an email, password, or cloud sign-in.
- **Data portability is a first-class feature, not an afterthought** — manual export/import and automatic local backups exist specifically because there's no cloud safety net.
- **Every screen must be reachable and fully usable via touch, mouse+keyboard, and stylus input** — no interaction should be exclusive to one input method (e.g. drag-drop pin placement must have a non-drag fallback, such as tap-to-place, for accessibility and for devices without reliable drag support).
- **Reactive data everywhere** — since Drift provides reactive streams, no screen should require manual pull-to-refresh to see data changed elsewhere (e.g. completing a task in Focus view must instantly reflect in Today, Tasks tab, and Dashboard without navigating away and back).
