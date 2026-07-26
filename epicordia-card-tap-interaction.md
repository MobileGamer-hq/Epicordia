# Epicordia — Card Tap Interaction (No Double-Click)

Removes the double-click-to-edit requirement entirely. The core principle: **a tap edits/acts, a drag moves/selects** — the two gestures are disambiguated by movement (a pointer-down-then-up with minimal movement is a tap; a pointer-down-then-move-past-a-threshold is a drag), not by counting clicks. This is the same disambiguation every modern touch/pointer interface uses, and it means a single tap can safely do something meaningful immediately, since a drag is a distinctly different gesture, not "a slower double-click."

---

## 1. The two fundamental gestures

- **Tap** (pointer down → up, minimal movement, short duration): triggers that card's **primary action** — see the per-type table below for what that is.
- **Drag** (pointer down → moves past a small threshold before release): **always selects and moves** the card, regardless of type — this never conflicts with the tap action because the two are mutually exclusive outcomes of the same initial touch.
- **Long-press** (held past a short duration without moving): opens the card's **context menu** (duplicate, delete, color tag, "remove from board") as a floating popover — this replaces whatever right-click/kebab-menu access existed before, and works identically on touch and desktop (desktop also gets this via right-click).

No card type needs a double-click for anything, anywhere in the app.

---

## 2. Primary tap action, per card type

Cards split into three natural groups: **content-authoring** types (tapping should drop you straight into editing, since that's virtually always why you tapped it), **consumption/reference** types (tapping should perform the obvious real-world action — open, play, visit — with editing reached through a small explicit control instead), and **structural** types (tapping does whatever makes structural sense for that type).

### Content-authoring — tap opens direct editing
| Card | Tap behavior |
|---|---|
| **Note** | Enters live Markdown editing immediately, cursor placed where tapped — no intermediate popup at all. |
| **Task card** | Tapping the **status ring** toggles status (a distinct, smaller tap target — see §3). Tapping **anywhere else** on the card opens the task's editor (title, description, dates, priority) as a side panel/bottom sheet, directly, one tap. |
| **Task list** | Tapping the card's **header/title** opens a light rename popover. Tapping a **sub-item's status ring** toggles that item. Tapping a **sub-item's text** edits that item's title inline, in place — no separate screen for a simple rename. |
| **Checklist (lightweight)** | Tapping an **item's ring** toggles it. Tapping **item text** edits it inline. Tapping the card's "add item" row creates a new blank, immediately-editable row. |
| **Heading/Divider** | Tapping heading text edits it inline, directly on the canvas — matches how a heading behaves inside a Note, just standalone. |
| **Table** | Tapping a **cell** edits that cell's value inline (real spreadsheet-style editing). Tapping the table's **border/margin** selects the whole pin for moving/resizing without entering cell-edit mode. |

### Consumption/reference — tap performs the real-world action; editing is a small explicit control
| Card | Tap behavior | How to edit its metadata instead |
|---|---|---|
| **Image** | Opens a larger preview/lightbox. | A caption field is editable directly within that lightbox — not a separate edit mode. |
| **Link** | Opens the link (in-app browser or externally, per platform convention). | A small edit icon on the card (visible on hover/selection, not hidden behind a gesture) opens a light popover to change the URL/title. |
| **Document/File** | Opens the file in the system's viewer. | Same small edit-icon popover pattern as Link, for renaming/display name. |
| **Audio/Voice memo** | Plays/pauses the recording. | Same small edit-icon popover pattern, for renaming. |
| **Drawing/Sketch** | Opens the drawing canvas in edit mode immediately — this one *is* content-authoring in spirit even though it's listed here for contrast; tapping = keep drawing, no separate "view then edit" step. |
| **Handwriting** | Same as Drawing — tap opens the ink editor directly. |

*(Drawing and Handwriting are edge cases: they're authoring types, but visually closer to "view a thing" like Image at rest — listed here to make that distinction explicit rather than leaving it ambiguous.)*

### Structural — tap does the structurally correct thing
| Card | Tap behavior |
|---|---|
| **Board (nested)** | Opens the child board (this was never a double-click case — unchanged). |
| **Color swatch** | Opens a light floating color-picker popover directly — picking a color *is* the edit, so there's no separate "view vs. edit" distinction to make here. |
| **Connector/Arrow** | Selects it, opening its light floating popover (edit label/style/delete) — already speced this way in the connector-implementation doc; no change needed, confirming it stays consistent with this document's model. |
| **Group/Frame** | Tapping the frame's **label/header** renames it inline. Tapping **empty space inside its bounds** (not on a child pin) selects the frame itself. Tapping a **child pin** defers entirely to that pin's own tap rule above — the frame never intercepts. |
| **Column** | Tapping the column's **header** renames it inline. Tapping a **card within it** defers to that card's own tap rule. A dedicated "add card" affordance sits at the bottom of the stack. |

---

## 3. Distinguishing tap zones within one card (the Task card case)

Task cards are the clearest case of a single card needing two different tap outcomes depending on *where* it's tapped:
- The **status ring** is a distinct, slightly larger-than-visual tap target (per accessibility touch-target sizing already established — minimum 44×44px), so tapping it precisely toggles status without needing to also open the full editor.
- Tapping **anywhere else on the card's body** (the title text, the metadata chips, the empty padding) opens the full editor.
- This pattern — one small, precise "quick action" zone plus one large "open full editor" zone covering the rest of the card — is the general solution any card with a similar quick-action-plus-full-edit need should follow, not something special-cased only for tasks.

---

## 4. Selecting without editing

Since a tap now often opens an editor directly, selecting a card *without* entering edit mode (e.g., to reposition it, delete it via the toolbar, or include it in a multi-select) happens through the gestures that were never ambiguous with tapping in the first place:
- **Drag** a card → selects and moves it (§1) — this is how a single card gets selected for repositioning, with no edit surface opening at all, since a drag never triggers the tap action.
- **Marquee-select** (drag on empty canvas, per the board-control document) → selects multiple cards for a bulk action, again without opening any individual card's editor.
- **Long-press** → context menu, offering delete/duplicate/etc. without needing to open the editor first.

This means the removal of double-click doesn't remove the ability to "just select" a card — it moves that capability onto drag and long-press, which were already distinct, unambiguous gestures, rather than overloading a second meaning onto a plain tap.
