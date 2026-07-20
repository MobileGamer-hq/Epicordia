# Epicordia — Card, Note & Task Content Spec
*How individual cards look and behave on a board, how Notes and Tasks are actually stored (Markdown), and the single-source-of-truth rule that keeps a note/task appearing on its board and in the global Notes/Tasks tabs without ever becoming two copies of the same thing.*

---

## 1. The core principle: one record, many places it's shown

A Note or a Task is stored **exactly once**, as a single row in the local database. Its board placement (which board, and its `x`/`y`/`width`/`height`/`zIndex` on that board's canvas) is just a handful of fields on that same row — not a separate copy living in a separate "board" structure.

- The **Board screen (Canvas/List/Focus)**, the **Notes tab**, and the **Tasks tab** are three different *queries* over the same underlying table, not three different data stores.
- Editing a note's text (or a task's status, due date, anything) from any one of those three places updates that one row — the change is instantly visible everywhere else via Drift's reactive streams, with no sync step and no "which copy is newer" question, because there is only ever one copy.
- A note/task with no board (`boardId = null`) simply doesn't have meaningful `x`/`y` yet and is skipped by Canvas rendering — it still shows up in the Notes/Tasks tabs and in the Unsorted tray. Assigning it to a board later is an update to that same row (`boardId` set, a placement position assigned), never a copy-and-delete.
- **"Remove from board" vs. "Delete" are two different, clearly separate actions** everywhere in the UI: "Remove from board" clears `boardId`/position (the note/task now lives only in Unsorted + the global tabs); "Delete" removes the row entirely. This distinction must be visible in every context menu/floating popover that offers either action — never merge them into one ambiguous "Remove" button.

### Architecture note (refines the schema in the AI Design Document / dev plan)
Earlier documents described a generic `Pin` table holding all board content polymorphically, with `Task` as a separate table joined to it. To make the "one record, many views" rule airtight, **Note and Task should carry their own board-placement fields directly** (`boardId`, `x`, `y`, `width`, `height`, `zIndex`, all nullable) rather than being wrapped by a separate `Pin` row. Purely structural, canvas-only elements that never need to appear in a flat Notes/Tasks tab — Image, Link, Drawing, Audio, File, Color swatch, Heading/Divider, Connector, Frame, Table — can stay as their own pin-type tables, since nothing outside a board ever needs to list "every Image" or "every Connector" the way it needs to list every Note and every Task. *(Flag for later: this is a small, worthwhile refinement to the schema section of the other documents — happy to sync those once you confirm this direction.)*

---

## 2. Card anatomy — how each card looks and behaves on a board

All cards share a base shell: `surface-card` background, 1px `border-subtle`, `radius-m` (16px) corners, 16px padding, and the pin's assigned color tag shown as a slim left-edge stripe (not a full-card tint, to keep the board calm — the reserved semantic colors like warning/error are the only exception, per the UI design doc).

### 2.1 Note card
- **Collapsed (default) state on Canvas/List:** shows a rendered preview of the note's Markdown content — headings appear as actual bold larger text, bullet lists as real bullets, bold/italic rendered live — truncated to roughly 4–6 lines with a soft fade at the bottom if longer.
- **Expanded (Pin Editor) state:** a live Markdown editor — what you type renders formatted immediately (WYSIWYG-over-Markdown, not a raw-text/preview toggle), so the user never has to think about "Markdown" as a concept; it's simply how the text is stored underneath.
- If a user types their own literal checklist inside a note's text (e.g. writing `- [ ] pack the car`), that renders as a small **static, non-animated** checkbox glyph — this is the user's own written content being formatted as Markdown, not the app's task-tracking feature, and must look visually distinct (plain square, no color fill, no animation) from the Task Status Control described below, so the two are never confused.
- Color tag shown as the left-edge stripe; tapping the stripe opens the color-picker floating popover.

### 2.2 Task card
- **Title** in Body Strong, with the **Task Status Control** (the animated ring — see the UI design doc §5.4) to its left, never a checkbox.
- Below the title, a row of small pill chips shown only when set: due date (in the error/warning color if overdue/due soon), scheduled date (shown in a neutral tone, visually distinct from due date so the two are never confused at a glance), priority, and a "blocked" chip (with a small lock icon) if the task has unmet dependencies — tapping the blocked chip opens a floating popover listing exactly which task(s) it's waiting on.
- If the task has a longer description, it's stored and edited the same way as a note's content — a Markdown field, rendered live, truncated in the collapsed card view.
- If `Board.kanbanEnabled` is true, the card additionally shows nothing extra visually beyond its position in a column — the column *is* the status, so there is no redundant "status label" text duplicating what the ring and column already show.

### 2.3 Task list / lightweight checklist card
- A single card containing multiple sub-items, each with its own small Task Status Control (compact 16px ring) and its own title — visually a stack of mini task rows inside one card shell, not one ring for the whole card.
- Progress is additionally summarized at the top of the card in Caption text, e.g. "2 of 5 done" — text-based, not a progress bar, to keep the card visually calm.

### 2.4 Other pin types (brief visual notes)
- **Image:** the image fills the card edge-to-edge above an optional caption row; no internal padding around the image itself (padding applies only to the caption).
- **Link:** favicon + site name as a small Caption-style line above the link's title (Body Strong) and a one-line description if available; the whole card is tappable to open the link, with a small external-link icon in the top-right corner of the card signaling it leaves the app.
- **Drawing/Handwriting:** rendered as the actual vector strokes at card size (not a flattened raster thumbnail), so it stays crisp at any zoom level on Canvas.
- **Audio:** a waveform graphic (static, generated from the recording) with a circular play button (per the UI doc's circular-icon-container rule) and duration in Caption text.
- **Color swatch:** the card is simply a solid block of the chosen color with its hex value in small Caption text at the bottom, in whichever text color (light/dark) keeps it legible against that swatch.
- **Heading/Divider:** no card shell at all — just styled text (Heading style) or a thin rule, sitting directly on the canvas background, since it's a layout aid, not content.
- **Table:** a compact grid rendered inside the standard card shell, horizontally scrollable if it exceeds the card's width rather than shrinking text to fit.

---

## 3. Markdown storage spec

Storing Note content and Task descriptions as **plain Markdown text** (not a proprietary rich-text/JSON blob) is what makes Epicordia's data genuinely portable and human-readable outside the app — directly serving the "data ownership" principle from the product research.

| Field | Format | Notes |
|---|---|---|
| `Note.content` | Markdown string | Headings (`#`/`##`), bold/italic, bullet/numbered lists, links, and user-typed literal checklists are all just standard Markdown syntax stored as one text field. |
| `Task.description` | Markdown string | Same rules as `Note.content` — a task's longer notes field is edited with the same live-rendering Markdown editor component. |
| `Task.title` | Plain text (no Markdown) | Titles stay plain so they render identically everywhere (chips, rows, notifications) without needing a Markdown renderer just to show a title. |
| Embedded images/files referenced from a note | Standard Markdown image/link syntax (`![caption](local-relative-path)`, `[label](local-relative-path)`) | Keeps the note portable as a single text file if ever exported, with attachments referenced by relative path rather than embedded as opaque blobs. |

### Task completion in Markdown terms (storage/export only — not the live UI)
Internally and in any exported/flattened output (e.g. a board exported as a `.md` file, or a task list copied as text), a task's status is represented using standard GitHub-flavored Markdown task syntax, since that's the universal, tool-interoperable plain-text convention:
- Not started → `- [ ] Task title`
- Done → `- [x] Task title`
- In progress has no standard Markdown equivalent, so it's represented in exported text with a small inline tag, e.g. `- [ ] Task title (in progress)`, rather than inventing a non-standard checkbox character that other Markdown tools wouldn't understand.

**This is purely a storage/export convention — it does not change the live UI rule that tasks are always shown with the animated Status Control, never a plain checkbox on screen.** The Markdown checklist syntax only becomes visible if the user exports their data or opens the underlying file in another tool.

### Optional export front-matter
When exporting a board or note to a standalone `.md` file, a small YAML front-matter block at the top carries metadata that plain Markdown can't express on its own:
```
---
dueDate: 2026-07-20
scheduledDate: 2026-07-18
priority: high
board: "Spring Streetwear"
tags: [materials]
---
```
This keeps exported files opening cleanly as plain text in any Markdown-aware app (Obsidian, a text editor, etc.), while preserving Epicordia-specific metadata for round-tripping back into Epicordia later via Import.

---

## 4. How Notes and Tasks look in their global tabs (outside a board)

Both tabs reuse the exact same row/card components already defined for Board List view (§2.1/§2.2 above) — this is deliberate, so a note or task looks and behaves identically whether you're viewing it on its board or in its global tab.

### 4.1 Notes tab row
- Same collapsed Markdown-rendered preview as the board card (§2.1), shown as a full-width row or a grid card (user-togglable).
- A small **board badge** to the right of the title — e.g. a pill reading "Spring Streetwear" or "Unsorted" — showing where the note lives; tapping the badge navigates straight to that board with the note highlighted (per the app-flow doc's search/navigation behavior).
- Last-modified timestamp in Caption/`text-tertiary`.

### 4.2 Tasks tab row
- Same Task Status Control + title + due/scheduled/priority/blocked chips as the board card (§2.2).
- Same board badge pattern as Notes, so a flat Tasks-tab view never loses the context of which project a task belongs to.
- Filter/sort controls at the top (by board, due date, priority, status, blocked state) — filtering here never mutates the underlying data, only the view.

### 4.3 The no-duplicates guarantee, stated plainly
- There is never a second row created when a note/task "appears" in a tab — the tab is a live query, not a copy operation.
- Deleting a note/task from its Tasks/Notes tab deletes the same row the board was rendering — it disappears from the board too, instantly, with no separate "sync" step.
- Renaming, editing, completing, or moving a note/task from any of its three surfaces (board, Notes/Tasks tab, Dashboard's Today/Unsorted sections) is the same single write, visible everywhere else the moment it happens.
