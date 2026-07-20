# Epicordia — Schema Corrections
*Six confirmed fixes to the current Drift/SQLite schema, resolving mismatches with the product spec. Hand this to Antigravity alongside the existing schema to correct it — do not treat this as a from-scratch rebuild, it's a patch to what already exists.*

---

## 1. Remove the literal "inbox" Board — make `boardId` nullable instead

- Delete any hardcoded/seeded Board row used as an inbox (e.g. `id = 'inbox'`).
- `Pins.boardId` → make nullable. A Pin with `boardId = null` has no canvas position and is not rendered on any board's Canvas — it exists only to be picked up by the Unsorted tray query and the Notes/Tasks tabs.
- `Tasks.boardId` → make nullable, same rule.
- **Quick Capture** now simply inserts a Pin/Task with `boardId = null` (instead of `boardId = 'inbox'`). Filing an item onto a board later is an `UPDATE` setting `boardId` (and, once actually dragged onto a canvas, `x`/`y`/`pinId` as relevant) — never a copy/delete.
- **Unsorted tray query:** `SELECT * FROM pins WHERE boardId IS NULL AND type = 'note'` unioned with `SELECT * FROM tasks WHERE boardId IS NULL`, ordered by `createdAt`.

## 2. `Task.status` is one unified field, always present

- `Task.status` (Not started / In progress / Done) is set on every task regardless of whether its board has `kanbanEnabled`.
- `Board.kanbanEnabled` only changes how Focus view *groups/renders* that field (columns vs. a plain grouped list) — it must never gate whether the field itself exists or is populated, and there is no separate "kanban status" column.
- The Task Status Control (animated ring, UI doc §5.4) always reads/writes this same field, on every screen (Today, Notes/Tasks tabs, board List/Focus/Canvas).

## 3. Cascade delete must cover Tasks and TaskDependencies

Current cascade only handles `Board → Pins → Attachments/Connectors`. Extend it:
- Deleting a **Board** must also delete every **Task** with that `boardId` (in addition to its Pins).
- Deleting a **Task** (whether directly or via the board cascade above) must delete every **TaskDependency** row referencing it as either `taskId` or `dependsOnTaskId`.
- Implement via `ON DELETE CASCADE` on the relevant foreign keys (not manual application-side delete loops), consistent with the existing `PRAGMA foreign_keys = ON` approach already used for Pins.

## 4. Recurring tasks: pre-generate future occurrences

- Add `recurrenceParentId` (nullable FK to `Tasks.id`) to the Tasks table.
- A recurring task is defined once as a **master row** holding `recurrenceRule` (RRULE) and a template due date/time — the master row itself is not shown as a due/actionable item.
- A background process generates concrete **occurrence rows** (real `dueDate`, `recurrenceParentId` set to the master's id) for a rolling window — generate the next N occurrences (suggest N = 10, or a 90-day window, whichever is fewer) — and tops this window up periodically (e.g. on app launch, and whenever the generated window runs low) so the user never runs out of future instances without needing to manually regenerate.
- Completing/editing a single occurrence only affects that occurrence row, not the master or other occurrences — editing "this one" vs. "this and all future" is a UX decision to design explicitly later (flagging this now so it isn't accidentally decided by default behavior).
- Deleting the master row should cascade-delete its generated occurrence rows (extend rule #3's cascade approach to include `recurrenceParentId`).

## 5. `Note.content` and `Task.notes` must be Markdown text

- Both fields are Markdown-formatted plain text, not arbitrary/unstructured text — per the content spec doc, this is what makes exported data portable and human-readable outside the app.
- The editor bound to these fields must be a live-rendering Markdown editor (WYSIWYG-over-Markdown), not a raw-text box with a separate preview toggle.
- This does not change storage type (still a text column) — it's a content-format contract the UI and any import/export code must honor, not a schema-level change.

## 6. Confirm: `Pins.content` JSON convention stays as-is
No change requested here — flexible `content` column (plain text for notes, JSON for structured types like drawings/links) remains the right trade-off. Just make sure Markdown text (fix #5) is what actually gets written into `content` for `type = 'note'` Pins, since that field is shared across multiple pin types with different formats.

---

### Quick summary for the agent
Apply all six fixes above to the existing schema and repositories — this is a correction pass, not a rewrite. Re-run the Phase 1 unit tests from the development plan after applying these (cycle detection, cascade deletes, reactive queries) and add new tests specifically for: nullable `boardId` behavior, cascade delete of Tasks/TaskDependencies, and recurrence occurrence generation/cascade.
