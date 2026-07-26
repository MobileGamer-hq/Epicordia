# Epicordia — Board Control (Pan, Zoom, Select & Toolbar Placement)

How navigating and interacting with the Canvas is controlled — the explicit toolbar tools, how touch gestures work alongside them, and why the toolbar needs to be repositionable rather than fixed.

---

## 1. Three explicit tool modes on the toolbar

Alongside the pin-creation tools already on the toolbar (Note, Task, Image, Draw, etc. — per the UI doc's pin tray), add three **mutually exclusive mode buttons**, visually grouped and separated from the creation tools:

| Tool | Icon | What it does |
|---|---|---|
| **Select** (default) | pointer/cursor | Tap a pin → its primary tap action (see the companion card-interaction doc). Drag a pin → moves it. Drag on empty canvas → marquee-selects (desktop) or pans (touch — see §2). |
| **Pan** (hand tool) | open hand | Any drag — including one that starts *on top of* a card — moves the camera instead of the card. Exists so a user can navigate a crowded board without any risk of accidentally nudging a pin. |
| **Zoom** | magnifying glass | Tap/click a point → zooms in, centered on that point. A small +/− toggle on the tool button itself (or a modifier click) zooms out instead. Distinct from the numeric zoom control already in the top bar (per the UI doc's board-screen chrome) — that one is a quick, precise percentage control; this tool is for quickly zooming into a specific spot by pointing at it. |

Selecting a mode is sticky (stays active until changed) — not a one-shot action — so a user who wants to pan-navigate a large board for a while doesn't have to re-select the Pan tool after every drag.

---

## 2. Touch gestures work independently of the selected tool

On phone and tablet, **two-finger gestures always pan/zoom, regardless of which toolbar tool is currently active**:
- Two-finger drag → pans.
- Pinch → zooms.

This means a touch user never strictly needs to touch the toolbar to navigate — the gestures are always live underneath whatever tool is selected. The toolbar's Select/Pan/Zoom modes exist for two real reasons even on touch devices:
1. **Precision/one-handed use** — e.g. explicitly switching to Pan so a single finger can navigate without any risk of dragging a card, useful when the other hand is busy or precision matters.
2. **Enabling marquee-select on touch** — a single-finger drag on empty canvas normally **pans** on touch (matching what a touch user expects from every other app), which means marquee/rubber-band multi-select isn't reachable through the default single-finger drag. Explicitly selecting the **Select** tool's drag-on-empty-canvas behavior (or a long-press-then-drag) is how a touch user deliberately opts into marquee selection when they want it.

### Platform gesture summary

| Action | Desktop (mouse/trackpad) | Touch (phone/tablet) |
|---|---|---|
| Pan | Trackpad two-finger scroll; middle-mouse or space+drag | Two-finger drag (always); single-finger drag in Select mode on empty canvas |
| Zoom | `Ctrl`/`Cmd` + scroll wheel; trackpad pinch | Pinch (always) |
| Marquee select | Left-mouse drag on empty canvas (Select mode, default) | Long-press-then-drag, or explicit Select-tool drag on empty canvas |
| Move a pin | Drag the pin (Select mode) | Drag the pin (Select mode) |
| Force-pan even over a pin | Pan tool active, or space+drag | Pan tool active |

---

## 3. Toolbar placement — bottom, left, or right (user-configurable)

The toolbar is **not fixed to the left edge**. It can be docked to the **bottom, left, or right**, chosen in Settings → Appearance (or via a quick drag-to-redock affordance directly on the toolbar's grip handle, for anyone who'd rather not dig into Settings).

**Why this matters, concretely:** a fixed left-side toolbar can sit directly under where a floating popover or side panel would naturally want to open for a card near that edge — exactly the collision the earlier board already ran into. Making placement configurable, combined with the collision-avoidance rule below, resolves it rather than just working around one specific case.

- **Sensible defaults:** bottom on phone (thumb reach, avoids a left-hand bias), left on tablet/desktop (matches the Milanote-inspired layout already established) — but every platform can be switched to any of the three positions.
- **Collision-avoidance rule (applies regardless of which position is chosen):** any floating popover or side panel must maintain clearance from the toolbar's occupied screen region. If a popover's naive anchor position (next to the tapped card, per the UI doc's §5.2 overlay system) would overlap the toolbar, it flips to anchor on the opposite side of the card instead, or shifts along the free axis — the same kind of collision-avoidance a tooltip library does automatically, just aware of one extra reserved region (the toolbar) in addition to the screen edges it already avoids.
- **Side panels specifically** (used for full content editing, per the companion card-interaction doc) dock to whichever screen edge is *not* occupied by the toolbar — if the toolbar is on the left, the side panel docks right, and vice versa; if the toolbar is on the bottom (phone), the content editor is a bottom sheet that temporarily covers the toolbar, which is acceptable there since a user isn't reaching for canvas tools while actively typing in a card.

---

## 4. Zoom bounds and camera behavior (recap, tied to the tools above)

- Clamp zoom to 25%–300% regardless of which tool drives the zoom (pinch, scroll, or the Zoom tool).
- "Zoom to fit" and the numeric zoom control remain in the top bar (per the existing board-screen chrome spec) as quick, always-available actions independent of the current toolbar mode.
- Auto-pan near the viewport edge while dragging a pin or a connector handle (per the board-screen implementation doc) applies regardless of toolbar position or active tool.
