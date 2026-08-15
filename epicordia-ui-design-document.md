# Epicordia — UI Design Document
*Visual design system for the AI build agent. Pairs with `epicordia-app-flow.md` (navigation) and `epicordia-ai-design-document.md` (functional spec).*

**Design direction in one line:** Notion's calm, content-first clarity + Milanote's tactile, card-based spatial layout — a single clean blue accent, warm neutral surfaces, and generous whitespace, so it reads as professional and effortless on a phone, a tablet, or a desktop, without ever feeling like three different apps.

---

## 1. Color system

### Why this palette
Research consistently shows: (a) blue remains the strongest "trust + focus" signal for productivity tools and is the world's most broadly preferred color; (b) pure white (`#FFFFFF`) backgrounds increasingly read as cold/impersonal for long work sessions — a warm, very slightly off-white surface reduces eye fatigue; (c) mid-tone greys (~`#808080`) fail accessibility as text/borders, so the grey scale below deliberately skips that dead zone; (d) every text/background pairing below is chosen to clear WCAG AA (4.5:1 for body text, 3:1 for large text/UI elements).

### 1.1 Primary — Epicordia Blue
A clean, slightly cool royal blue — trustworthy without being corporate-flat, and distinct from the many indigo/violet "AI-brand" palettes so it reads as a calm productivity tool, not a hype-tech one.

| Token | Hex | Use |
|---|---|---|
| `blue-50` | `#EEF3FF` | Subtle tinted backgrounds, selected-row highlight |
| `blue-100` | `#DCE6FF` | Hover backgrounds, badge fills |
| `blue-200` | `#B7CCFF` | Heatmap level 1 (light activity) |
| `blue-300` | `#8FAEFF` | Heatmap level 2 |
| `blue-400` | `#5C87F7` | Heatmap level 3, secondary buttons (dark mode) |
| `blue-500` | `#3D68EE` | Heatmap level 4 (max activity), links |
| `blue-600` | `#2F53DB` | **Primary accent — light mode** (buttons, active nav item, toggle-on states) |
| `blue-700` | `#243FB0` | Pressed/active state, primary text-on-light for links needing extra contrast |
| `blue-800` | `#1C3186` | Dark-mode surface tints, deep accents |
| `blue-900` | `#152660` | Rarely used; darkest anchor for gradients/illustrations only |
| `blue-400 (dark-mode primary)` | `#6E96FF` | **Primary accent — dark mode** (brighter than light-mode primary so it stays legible on dark surfaces; verified ≥4.5:1 on `neutral-900`) |

`blue-600` on white (`#FFFFFF`) clears AA for UI components/large text; for small body text on tinted `blue-50` backgrounds, use `blue-700` instead per the contrast-failure pattern flagged in research (light blue text on light blue-tinted backgrounds is a common accessibility bug — avoid it here explicitly).

### 1.2 Neutrals — Light mode
| Token | Hex | Use |
|---|---|---|
| `surface-app` | `#FAFAF8` | App background (warm off-white, not pure white) |
| `surface-card` | `#FFFFFF` | Cards, panels, the pin tray, top bar |
| `surface-sunken` | `#F2F2EF` | Canvas background (subtle dot-grid drawn in `border-subtle`, see §3) |
| `border-subtle` | `#E7E7E2` | Card borders, dividers |
| `border-strong` | `#D6D6CF` | Input borders, focus outlines (paired with blue-600 ring) |
| `text-primary` | `#16181C` | Headings, primary body text (near-black, softer than pure `#000`) |
| `text-secondary` | `#585E68` | Secondary text, metadata, timestamps |
| `text-tertiary` | `#8A8F98` | Placeholders, disabled text |

### 1.3 Neutrals — Dark mode
| Token | Hex | Use |
|---|---|---|
| `surface-app` | `#0F1420` | App background (dark navy slate) |
| `surface-card` | `#1E283A` | Cards, panels, top bar |
| `surface-sunken` | `#141A26` | Canvas / sidebar background |
| `border-subtle` | `#273349` | Card borders, dividers |
| `border-strong` | `#3A4B68` | Input borders |
| `text-primary` | `#F1F5F9` | Headings, primary body text (crisp off-white) |
| `text-secondary` | `#94A3B8` | Secondary text (slate gray) |
| `text-tertiary` | `#64748B` | Placeholders, disabled text |

### 1.4 Semantic colors (same role, light/dark variants)
| Role | Light | Dark | Use |
|---|---|---|---|
| Success | `#1A9A5B` | `#33C077` | Task completed, sync success |
| Warning | `#B5730A` | `#E5A030` | Due soon, milestone approaching |
| Error/Blocked | `#C6362E` | `#F0685F` | Overdue, blocked-task indicator, destructive actions |
| Info | `blue-600` / `blue-400` | reuse primary — never introduce a second blue | Neutral notices |

Semantic colors are reserved exclusively for status — never reused as decorative/branding color, so users can trust them at a glance (per research: mixing brand and status colors causes misreads).

### 1.5 Calendar Heatmap scale
Five steps, reusing the blue scale so the heatmap feels native to the brand rather than borrowing GitHub's green convention:
`none → border-subtle` · `level 1 → blue-200` · `level 2 → blue-300` · `level 3 → blue-400` · `level 4 → blue-600`.

### 1.6 Pin color tags (user-assignable, for organizing cards on a board)
A small fixed set so boards stay visually calm rather than becoming rainbow-colored: warm yellow `#F4C453`, coral `#F0806B`, mint `#5FC7A3`, lavender `#9C8CF0`, sky `#5FA8F5` (distinct from primary blue), and neutral grey `#B9BCC2`. Each has a matching pale background tint for card fills.

---

## 2. Typography

- **Typeface:** A single geometric-humanist sans-serif family across the whole app (e.g. Inter or an equivalent variable font available via Google Fonts in Flutter) — one family, varied by weight only, so the UI never feels stitched together across platforms.
- **Scale** (mobile base 14px body, scaling up slightly on tablet/desktop for comfortable reading distance):

| Style | Size (mobile / desktop) | Weight | Use |
|---|---|---|---|
| Display | 28 / 32 | 700 | Dashboard greeting, empty-state headlines |
| H1 | 22 / 24 | 700 | Screen titles (board title, tab titles) |
| H2 | 18 / 20 | 600 | Section headers (e.g. "Important & Urgent") |
| Body | 14 / 15 | 400 | Default text, pin content |
| Body Strong | 14 / 15 | 600 | Card titles, task titles |
| Caption | 12 / 13 | 400 | Metadata, timestamps, counts |
| Label | 12 / 12 | 600, uppercase, tracked | Section eyebrows, badges |

- Line height: 1.4–1.5 for body text; 1.2 for headings.
- Never rely on color alone to convey meaning (e.g. a blocked task gets an icon + label, not just red text) — supports colorblind accessibility.

---

## 3. Layout, spacing & shape

**Shape direction:** Reddit's own design-system teams found that inconsistent corner radii and button styles across a product make it feel disjointed, and standardized instead on a small, consistent radius scale plus uniform circular containers for every clickable icon. Epicordia adopts that same discipline, with noticeably more curvature than a typical enterprise tool — soft, friendly, and consistent — while keeping the calmer blue/neutral palette from §1 rather than Reddit's own brand color.

- **Base spacing unit:** 4px grid (4, 8, 12, 16, 24, 32, 48px steps) — every margin/padding in the app should be a multiple of 4.
- **Radius scale** (semantic tokens, each element sized to its own group — never one flat radius applied everywhere):

| Token | Radius | Use |
|---|---|---|
| `radius-xs` | 6px | Small chips, input fields, checkboxes-replacement controls |
| `radius-s` | 10px | Buttons, small cards, toolbar icons' hover background |
| `radius-m` | 16px | Standard cards (board cards, pin cards, list rows) |
| `radius-l` | 20px | Large surfaces — modals, side panels, bottom sheets |
| `radius-pill` | 999px (full) | Buttons with text, tags/chips, the Create button, segmented controls, the status control ring's outer hit-area |

Following the golden nesting rule (inner radius = outer radius − padding), an element inside a `radius-m` card with 12px padding gets `radius-s`, not the same 16px — never reuse a parent's radius on its direct children.

- **Clickable icons are always circular containers** (uniform 40px diameter on desktop/tablet, 44px on phone for touch-target size), regardless of where they appear — top bar icons, pin-tray tools, floating popover close buttons. Non-clickable/decorative icons have no container at all. This one rule, borrowed directly from Reddit's own design-system consolidation, is what prevents the "13 different small text/icon styles" problem their design team documented — Epicordia should never end up with more than one visual style per icon role.
- **Elevation:** flat design with soft, single-direction shadows only on interactive/lifted elements (a pin being dragged, an open popover/modal) — resting cards use a 1px border instead of a shadow, keeping the interface calm (shadows are earned by interaction, not default decoration).
- **Grid/breakpoints** (aligned to Flutter/Material responsive conventions):
  - **Compact (phone): <600px** — single column, bottom navigation, full-screen modals.
  - **Medium (tablet): 600–1024px** — collapsible navigation rail, board canvas + side-panel pin editor.
  - **Expanded (desktop/large tablet): >1024px** — persistent labeled sidebar, board canvas + side panel, room for a secondary inspector column if needed.

---

## 4. Core components

### 4.1 Sidebar / navigation (desktop & tablet)
- Fixed-width (desktop ~240px, collapsible to icon-only ~72px on tablet) left column, `surface-card` background, `border-subtle` right edge.
- Top: app name/mark. Below: primary nav items (Home, Boards, Notes, Tasks, Calendar) as icon + label rows, active item shown with a `blue-50` background pill and `blue-600` icon/text (dark mode: `blue-900`-tinted background, `blue-400` icon/text).
- Bottom: Settings, then storage/backup status as a small unobtrusive line.
- On tablet, collapses to icon-only rail by default with labels appearing on hover/tap-to-expand, matching the researched "navigation rail" pattern.

### 4.2 Bottom navigation (phone)
- 4–5 items max (Home, Boards, Notes+Tasks combined as one "Lists" entry, Calendar, More), icons + short labels, `surface-card` background, active item in `blue-600`.
- Quick Capture FAB floats above the bar, bottom-right, `blue-600` fill with a white "+" — the single most prominent action on screen, per FAB best practice (one primary action only).

### 4.3 Board screen chrome (mirrors the reference screenshots' layout)
- **Top bar:** breadcrumb trail at the left (`Home / Projects / Board Name`, each segment tappable), board title centered or left-aligned next to breadcrumb, and a right-aligned icon cluster: search, notifications/reminders, help, settings, then a **view-mode switch** (Canvas / List / Focus segmented control), a **zoom control** (Canvas mode only), and an **Export** action (replacing "Share," since there's no multi-user collaboration — Export covers PDF/image/flattened-doc output for the same audience need Milanote's Export serves).
- **Left pin tray:** a slim vertical rail of icon buttons — Note, Task, Link, Image, Draw, Audio, Connector, Frame, Table, Heading — with a visually separated **Trash** icon pinned at the very bottom, directly mirroring the reference layout's left-rail convention.
- **Canvas body:** `surface-sunken` with the subtle dot grid; pins are `surface-card` with 1px `border-subtle`, 12px radius, lifting to a soft shadow only while being dragged.
- **"Unsorted" counter:** a small badge top-right of the canvas area (as seen in the reference images) showing how many pins haven't been placed/organized yet — a lightweight nudge toward triage, reused directly from the Milanote pattern since it tested well there.

### 4.4 Cards (Dashboard board cards, list rows, pin cards)
- Consistent card shell across contexts: `surface-card`, `border-subtle`, 12px radius, 16px internal padding, title in Body Strong, metadata in Caption/`text-secondary`.
- Important/Urgent boards get a thin left-edge accent stripe in the warning/error semantic color (not a full-card color change, to stay calm).
- Task rows/cards use the **Task Status Control** (§4.8) in place of a checkbox — see that section for full behavior.

### 4.6a Unsorted tray (replaces the earlier "Inbox board" concept)
Quick-captured notes/tasks should never feel like they've been filed into a hidden second app inside the app. Instead:
- Captured items appear as small unfiled cards in an **"Unsorted" shelf** — a horizontally-scrollable strip at the top of the Dashboard (and mirrored as the existing "Unsorted" counter badge on the Boards Hub/Board screen, per §4.3) — rather than living inside a separate named board a user has to learn to navigate into.
- Each unsorted card can be dragged directly onto any board thumbnail (Dashboard/Boards Hub) to file it, or tapped to open a floating popover offering "Move to board…" — no dedicated "Inbox" screen to visit at all.
- The shelf empties as items get filed; when empty it collapses to nothing (no empty "Inbox" ever sits there looking unfinished).

### 4.8 Task Status Control
The primary way any task communicates progress — see full animation spec in §5.4. Visually: a small circular ring (20px on compact rows, 24px on cards) to the left of the task title, tappable, with the three states (empty / half-filled blue / checkmark-in-success-color) always paired with the title text's own treatment (normal → normal → strikethrough+dimmed) so status is never conveyed by the ring's color alone.

### 4.9 Create button & Type Selector
The single, deliberate entry point for making something new — distinct from the ultra-fast Quick Capture FAB (§4.6a is about triaging captures; this is about intentionally starting a To-do list, Note, or Board).

- **Create button:** a `radius-pill` primary button, always labeled "Create" with a small "+" icon, permanently visible — top bar (right side, next to the icon cluster) on tablet/desktop, and as the elevated **center item of the bottom navigation bar** on phone (larger than the flanking icons, filled in `blue-600`, sitting slightly above the bar's edge) — directly mirroring the convention Reddit and most major mobile apps use for a single, unmissable creation action.
- **Type Selector:** tapping Create never opens a native OS dropdown. Instead it opens a custom **floating popover** (per §5.2's light-interaction pattern) directly above/near the Create button, containing three large tappable options as a horizontal (tablet/desktop) or stacked (phone) set of `radius-m` cards, each with a distinct icon + label: **To-do list**, **Note**, **Board**. Each option card has its own subtle tint (not the three pin-tag colors — a neutral `surface-sunken` with a colored icon) so the three are visually distinct at a glance.
- **Transition into the creation page:** tapping an option does not close the popover and open something unrelated — the selected card animates a continuity/morph transition (full timing/sequence in §5.6) into the relevant creation page: a **To-do list** creation page (title, first few items, board destination or leave Unsorted), a **Note** creation page (rich text editor, board destination or leave Unsorted), or the **New Board** page (title, Canvas/List default, kanban opt-in toggle). The user should feel like the card they tapped *became* the next screen, not that it was replaced by one.
- This unifies what was previously a separate, smaller "+ New board" action on the Boards Hub — that action now simply opens the Type Selector pre-filtered/scrolled to Board, rather than being a second, differently-styled creation entry point elsewhere in the app.

### 4.5 Calendar Heatmap widget
- Grid of small rounded squares (3–4px radius, ~12px each, 2px gutter), colored per §1.5, arranged in weekly columns like a contributions graph; a light `text-tertiary` month label row above.
- Tapping/hovering a cell shows a tiny tooltip/popover with the day's count and jumps to that day in Calendar view on tap.

### 4.6 Buttons — a small, consolidated set (Reddit-style discipline)
Reddit's own design-system audit found that unmanaged button variation (different radii, fills, and text styles across the same product) was one of the biggest sources of visual inconsistency. Epicordia deliberately allows only four button styles, always `radius-pill`, no exceptions:
- **Primary:** `blue-600` fill, white text, used once per screen for the single most important action (mirrors FAB scarcity principle — don't let every screen have three "primary-looking" buttons).
- **Secondary:** `surface-card` fill, `border-strong` outline, `text-primary` text.
- **Ghost/tertiary:** no fill/border, `text-secondary`, used for low-emphasis actions (e.g. "Cancel").
- **Destructive:** `error` color outline/text by default, filled only inside a confirm step.
- **Icon-only buttons** (search, notifications, settings, pin-tray tools, popover close) are never square — always a circular container per §3's clickable-icon rule, with a `surface-sunken`-tinted background on hover/press.

### 4.7 Empty states
- Every empty list/board/tab gets an illustration-free, text-plus-icon prompt in `text-secondary`, one clear primary button (e.g. "Create your first board"), matching the "empty states matter" principle from research — never a literal blank white/grey rectangle.

---

## 5. Motion & Interaction Language

Motion isn't decoration here — it's how the app explains what just happened, so the interface should never rely on an instant, silent state-change. Every state transition below has a defined animation; nothing "just appears."

### 5.1 Principles
- **Spring-based easing everywhere**, not linear or basic ease-in-out — small overshoot/settle (like a physical object coming to rest) on drags, pop-ins, and toggles, so the app has a tactile, confident feel rather than a flat/robotic one.
- **Duration bands:** micro feedback (button press, toggle flip) 100–150ms; element enter/exit (popovers, cards) 150–250ms; screen-level transitions (entering a nested board) 250–350ms. Nothing in the app should take longer than ~350ms to settle.
- **Staggered reveals:** when a list of cards/pins first renders (opening a board, loading Dashboard sections), items fade+rise in with a small stagger (~20–30ms between each) rather than all popping in at once — reinforces that this is a living workspace, not a static page.
- **Continuity over cuts:** wherever an element on screen A becomes an element on screen B (a board card becoming the board's top bar, a task row becoming its detail popover), animate that element growing/moving into place (a shared-element/hero-style transition) rather than a hard cut to a new screen.

### 5.2 Overlay system — floating contextual popovers, not blanket modals
Most day-to-day interactions should feel local to what the user tapped, not like leaving the screen. Overlay choice by weight:

| Interaction weight | Pattern | Animation |
|---|---|---|
| **Light** — quick status change, priority pick, color tag, short context menu, due-date pick | **Floating popover**: a small card anchored directly next to/above the tapped element, with a subtle directional pointer/notch toward its trigger, drop shadow, rounded 12px corners | Scale from 0.92→1.0 + fade + slight rise (~180ms spring), anchored so it visually originates from the tapped element, not the screen center |
| **Medium** — editing a single pin's full content, quick task detail | **Side panel** (tablet/desktop, board stays visible) or **bottom sheet** (phone) — not a centered modal | Slides in from the anchored edge (right on desktop/tablet, bottom on phone) over ~220ms, board dims very slightly (10–15% scrim) but stays visible/blurred behind it, not hidden |
| **Heavy** — new board creation, Settings sections, import/export confirmation, first-run setup | **Full-screen sheet/modal** | Standard modal fade+rise, reserved only for flows that genuinely need the user's full attention away from the board |

Rule of thumb: if the user is still conceptually "on the board," they should see a floating popover or side panel with the board visible/dimmed behind it — never a full opaque takeover. Full modals are earned only by heavier, standalone tasks.

### 5.3 Switches & toggles
- Track morphs color (neutral → `blue-600`) over ~150ms as the thumb slides, not an instant color swap.
- Thumb slides with a small spring overshoot (travels slightly past its resting position, settles back) rather than a linear glide — this is what makes a toggle feel "flipped" rather than just "moved."
- On tap, a very brief (~80ms) scale-down-then-up on the thumb gives tactile press feedback before the slide animation runs.

### 5.4 Task status control (replaces plain checkboxes)
A tappable circular **status ring**, not a checkbox — it should visually tell the story of a task's progress, not just its binary done/not-done state:

- **Not started:** an empty outlined ring in `border-strong`.
- **In progress:** the ring animates filling clockwise to roughly half, in `blue-600`, over ~200ms — this state is set automatically the first time a task is opened/edited, or manually via tap-and-hold for a quick menu, so "in progress" emerges naturally from use rather than requiring a manual step every time.
- **Done:** tapping a Not-started or In-progress ring completes the fill (spring-eased, ~250ms) in the success color, and a checkmark draws itself inside the ring stroke-by-stroke (~150ms) immediately after the fill finishes — followed by the task's title text animating a soft strikethrough sweep and fading to `text-tertiary` over ~200ms. The whole sequence reads as "this task just got finished," not "a box got ticked."
- Tapping a Done ring reverses the whole sequence (uncomplete), symmetrically animated back to its prior state.
- This same ring is the single source of truth whether or not a board has kanban enabled: with kanban off, the ring's three states are all the user sees; with kanban on, the ring's state is exactly what places the task in its To Do/Doing/Done column — there is no separate, disconnected "status" field for kanban mode.

### 5.5 Canvas-specific motion
- **Drag lift:** picking up a pin scales it to 1.03x and adds a soft shadow over ~120ms; dropping settles back to 1.0x with a slight spring ease-out.
- **Snapping:** alignment guides fade in at ~80ms when a dragged pin nears alignment with another, fade out on release.
- **Board entry/exit:** entering a nested board zooms/fades the canvas forward (~280ms spring ease), visually growing out of the board pin the user tapped (shared-element continuity per §5.1); exiting via breadcrumb reverses the same animation.
- **View-mode switch (Canvas/List/Focus):** cross-fade + slight vertical settle (~180ms), never an abrupt cut, so the user's sense of "same data, different lens" is reinforced visually.

### 5.6 Create button & Type Selector motion
- **Opening:** tapping Create, the button itself gives a brief (~80ms) press scale-down, then the Type Selector popover blooms outward from the button's position — scale 0.9→1.0 + fade over ~200ms spring, with the three option cards staggered in individually (~25ms apart, per §5.1) rather than appearing as one flat block.
- **Selecting an option:** the chosen card does not simply vanish — it scales up and expands (~250ms spring ease) to fill the space the creation page will occupy, while its icon fades out and its label cross-fades into the new page's title; the other two option cards fade out quickly (~100ms) as this happens, so all visual attention follows the one the user picked.
- **Backing out:** tapping outside the popover or a "Cancel"/back action reverses the opening animation exactly (cards fade/stagger back, popover shrinks back into the Create button) — never a hard cut back to the previous screen.
- **Bottom-nav Create button (phone):** being the elevated center item, it gets a subtle idle "breathing" affordance — a very slow (~2s), low-amplitude scale pulse (1.0→1.02→1.0) only when the Unsorted tray has unfiled items waiting, as a gentle nudge rather than a badge number; otherwise it sits still.

---

## 6. Light/Dark mode rules

- Theme follows system setting by default; manual override available in Settings.
- No pure black/pure white anywhere (see neutral tables in §1.2/1.3) — this is deliberate for reduced eye strain in long sessions, per research.
- Primary blue shifts from `blue-600` (light) to the brighter `blue-400 (dark-mode primary)` (dark) specifically to maintain contrast — never reuse the exact same blue value across both modes.
- Elevation/shadow is de-emphasized further in dark mode (borders do more of the separation work than shadows, since shadows read poorly on dark surfaces).

---

## 7. Accessibility checklist (apply before considering any screen "done")

- [ ] All text/background pairings meet WCAG AA (4.5:1 body, 3:1 large text/icons) — verify with a contrast checker, not by eye.
- [ ] No status is conveyed by color alone (icon/label always accompanies semantic color).
- [ ] All interactive elements have a minimum 44x44px touch target on touch devices.
- [ ] Every drag-drop interaction has a non-drag fallback (tap-to-place, or a menu action).
- [ ] Focus states are visible for keyboard navigation on desktop (a `blue-600` focus ring, not just a color change).
- [ ] Text scaling (OS-level font size increases) doesn't break layouts — verify at 150% scale minimum.
