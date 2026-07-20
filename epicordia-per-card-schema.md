# Epicordia — Per-Card Schema
*Exact data shape for every card/pin type. Builds on `epicordia-schema-corrections.md` (nullable boardId, unified Task.status, cascade deletes, recurrence, Markdown content) and adds three new fields confirmed below.*

---

## New fields being added to the existing schema

| Table | New field | Purpose |
|---|---|---|
| `Pins` | `parentFrameId` (nullable, self-referencing FK → `Pins.id`) | Explicit membership in a Group/Frame pin. Set when a pin is dropped inside a frame's bounds, cleared when dragged out. Dragging the frame moves every pin whose `parentFrameId` matches it, in one operation — no bounds-recalculation needed at render time. |
| `Pins` | `linkedBoardId` (nullable FK → `Boards.id`) | Used only on `type = 'board'` pins — the tile's canvas position lives on the Pin row (`boardId` = parent board, `x`/`y` = tile position); `linkedBoardId` points to which child Board it opens. Kept in sync with that child board's `parentBoardId` — both should always agree on the same parent/child pair; write them together in one transaction whenever a board is nested or un-nested. |
| `Tasks` | `groupPinId` (nullable FK → `Pins.id`) | Membership in a "Task list" pin (multiple real tasks grouped visually in one card). Mutually exclusive with `pinId` at the application level — a task is either placed solo on the canvas (`pinId` set), grouped inside a Task list pin (`groupPinId` set), or neither (just sitting in a board's List/Focus view, or fully unplaced with `boardId = null`). Never both at once. |

Cascade rule additions: deleting a Frame pin should clear (not cascade-delete) its children's `parentFrameId` back to null, rather than deleting the child pins themselves — un-grouping, not destroying. Deleting a Task list pin, by contrast, should cascade-delete the Task rows whose `groupPinId` points to it, since those tasks only exist as members of that list.

---

## Per pin type

### Note
- **Storage:** `Pins` row, `type = 'note'`.
- **`content`:** Markdown text, plain string (confirmed in the schema-corrections doc) — no JSON wrapper needed since there's nothing else to store alongside it.
- **Nothing in `Attachments`** unless the note embeds a Markdown image reference to a locally-attached file (in which case that file is a normal `Attachments` row linked by `pinId`, and the Markdown text just references its relative path).

### Task card (a single, solo-placed task)
- **Storage:** `Tasks` row is the source of truth (title, `notes` Markdown, `dueDate`, `scheduledDate`, `priority`, `status`, `recurrenceRule`/`recurrenceParentId`, `calendarEventId`). A `Pins` row (`type = 'task'`) exists only to give it a canvas position; `Tasks.pinId` points to it.
- **`content`** on the Pin row: unused/empty — all real data lives on the Tasks row, reached via `Tasks.pinId = Pins.id`.
- A task with no `pinId` (not yet placed on any canvas) still has a `boardId` (or `null` if fully unsorted) and shows up correctly in List/Focus/Tasks-tab queries, which never depend on a Pin existing.

### Task list (grouped sub-tasks in one card)
- **Storage:** one `Pins` row (`type = 'tasklist'`) for the card's own position/size. Each sub-item is a real `Tasks` row with `groupPinId` set to that Pin's id, and `pinId = null` (it isn't independently placed — its position is implied by its place in the list).
- **`content`** on the Pins row: just the card's own metadata, e.g. `{"title": "Packing list"}` (an optional heading shown above the grouped items) — the items themselves are never duplicated into this JSON, they're queried live from `Tasks WHERE groupPinId = <this pin's id>`.
- Because these are real Tasks rows, each one appears in the global Tasks tab individually (with a board badge pointing back to the parent board), exactly like a solo task card — the only difference from a Task card is that its `groupPinId` (not `pinId`) is set.

### Checklist (lightweight — no due dates/reminders, e.g. a grocery list)
- **Storage:** a single `Pins` row (`type = 'checklist'`). Deliberately **not** using the Tasks table at all — these items never need due dates, priority, dependencies, or calendar sync, and must never appear in the global Tasks tab (per the earlier design decision that lightweight checklists are card-local only).
- **`content`:** JSON array, e.g.:
```json
{"items": [
  {"id": "a1", "text": "Milk", "done": false},
  {"id": "a2", "text": "Eggs", "done": true}
]}
```
- Each item still uses the same visual Status Control component in the UI, but toggling it just rewrites this JSON array in place — it never touches the Tasks table.

### Image
- **Storage:** `Pins` row (`type = 'image'`) + one `Attachments` row (`pinId` → this pin, `filePath`, `fileType`).
- **`content`:** `{"caption": "optional caption text"}` — empty object if no caption.

### Drawing / Sketch, and Handwriting
- **Storage:** `Pins` row (`type = 'drawing'` or `type = 'handwriting'`).
- **`content`:** JSON vector stroke data, e.g.:
```json
{"strokes": [
  {"points": [[12.0, 44.2, 0.6], [13.1, 44.9, 0.7]], "color": "#16181C", "widthPx": 2.5}
], "recognizedText": "optional, handwriting-type only"}
```
(each point is `[x, y, pressure]`; `pressure` defaults to `1.0` on devices without pressure sensitivity)
- **Size note:** inline JSON is fine for typical sketches; if a drawing's stroke data grows very large (long, detailed handwriting sessions), consider migrating that pin's content to a file-based attachment instead of the text column — flagging as a future optimization, not a v1 requirement.

### Link
- **Storage:** `Pins` row (`type = 'link'`).
- **`content`:**
```json
{"url": "https://...", "cachedTitle": "...", "cachedFavicon": "local/path/or/null", "cachedDescription": "..."}
```
- Cached fields are fetched once when online and reused offline; if never fetched (captured while offline), the pin falls back to displaying the raw URL until a fetch succeeds.

### Document/File
- **Storage:** `Pins` row (`type = 'file'`) + one `Attachments` row (`filePath`, `fileType`).
- **`content`:** `{"displayName": "optional override name"}` — falls back to the attachment's actual filename if not set.

### Audio / Voice memo
- **Storage:** `Pins` row (`type = 'audio'`) + one `Attachments` row (the audio file).
- **`content`:** `{"durationSeconds": 42}` — cached at recording time so the waveform/duration can render without decoding the audio file itself.

### Color swatch
- **Storage:** `Pins` row (`type = 'colorSwatch'`).
- **`content`:** `{"hex": "#3D68EE"}`.

### Heading / Divider
- **Storage:** `Pins` row (`type = 'heading'`, no card shell per the UI doc).
- **`content`:** `{"style": "heading", "text": "Section name"}` or `{"style": "divider"}` (no text).

### Table
- **Storage:** `Pins` row (`type = 'table'`).
- **`content`:**
```json
{"columns": ["Item", "Qty"], "rows": [["Thread", "3"], ["Zippers", "12"]]}
```

### Connector / Arrow
- **Storage:** its own `Connectors` row — never a `Pins` row (connectors aren't independently placeable objects, they're edges between two pins).
- **Fields:** `boardId`, `fromPinId`, `toPinId`, plus two small additions worth adding now rather than later: `label` (nullable text, short annotation on the arrow) and `style` (enum: `straight` / `curved`, default `straight`).

### Group / Frame
- **Storage:** `Pins` row (`type = 'frame'`).
- **`content`:** `{"label": "optional frame title"}` — membership is **not** stored here; it's derived from other pins' `parentFrameId` pointing at this pin's id (per the confirmed decision above).
- Resizing/dragging a frame updates its own `x`/`y`/`w`/`h`; the app logic then translates every child pin (`WHERE parentFrameId = thisFrame.id`) by the same delta, rather than recalculating containment from scratch each time.

### Board (nested board tile)
- **Storage:** `Pins` row (`type = 'board'`) on the **parent** board (`boardId` = parent board's id, `x`/`y` = tile position) with `linkedBoardId` pointing to the **child** Board's id. The child Board row separately has `parentBoardId` set to the parent — both fields are written together whenever a board is nested (drag-to-file) or un-nested, and should never disagree.
- **`content`:** unused/empty — the tile's title/thumbnail are derived live from the linked Board's own `title` and its current contents, not duplicated into the Pin.
- Breadcrumb queries use `Boards.parentBoardId` directly (simple, fast self-referencing lookups); rendering the tile on the canvas uses the Pin row for its position and `linkedBoardId` for which board to open on tap — two different jobs, two different fields, deliberately not merged into one.
