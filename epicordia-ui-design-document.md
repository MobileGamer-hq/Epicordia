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
| `surface-app` | `#101216` | App background (near-black, not pure black) |
| `surface-card` | `#1A1D22` | Cards, panels, top bar |
| `surface-sunken` | `#0B0D10` | Canvas background |
| `border-subtle` | `#2B2E34` | Card borders, dividers |
| `border-strong` | `#3B3F47` | Input borders |
| `text-primary` | `#F3F4F6` | Headings, primary body text (off-white, not pure white) |
| `text-secondary` | `#A6ABB4` | Secondary text |
| `text-tertiary` | `#6E737C` | Placeholders, disabled text |

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

- **Base spacing unit:** 4px grid (4, 8, 12, 16, 24, 32, 48px steps) — every margin/padding in the app should be a multiple of 4.
- **Corner radius:** cards/panels 12px, buttons/inputs 8px, small chips/tags fully rounded (pill), the canvas dot-grid itself uses tiny 1–2px dots spaced ~24px apart in `border-subtle`.
- **Elevation:** flat design with soft, single-direction shadows only on interactive/lifted elements (a pin being dragged, an open modal) — resting cards use a 1px border instead of a shadow, keeping the interface calm (shadows are earned by interaction, not default decoration).
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

### 4.5 Calendar Heatmap widget
- Grid of small rounded squares (3–4px radius, ~12px each, 2px gutter), colored per §1.5, arranged in weekly columns like a contributions graph; a light `text-tertiary` month label row above.
- Tapping/hovering a cell shows a tiny tooltip/popover with the day's count and jumps to that day in Calendar view on tap.

### 4.6 Buttons
- **Primary:** `blue-600` fill, white text, 8px radius, used once per screen for the single most important action (mirrors FAB scarcity principle — don't let every screen have three "primary-looking" buttons).
- **Secondary:** `surface-card` fill, `border-strong` outline, `text-primary` text.
- **Ghost/tertiary:** no fill/border, `text-secondary`, used for low-emphasis actions (e.g. "Cancel").
- **Destructive:** `error` color outline/text by default, filled only inside a confirm step.

### 4.7 Empty states
- Every empty list/board/tab gets an illustration-free, text-plus-icon prompt in `text-secondary`, one clear primary button (e.g. "Create your first board"), matching the "empty states matter" principle from research — never a literal blank white/grey rectangle.

---

## 5. Motion & micro-interactions

- **Drag lift:** picking up a pin scales it to 1.03x and adds a soft shadow over ~120ms; dropping settles back to 1.0x with a slight ease-out.
- **Snapping:** alignment guides fade in at ~80ms when a dragged pin nears alignment with another, fade out on release.
- **Board entry/exit:** entering a nested board zooms/fades the canvas forward (~200ms ease); exiting via breadcrumb reverses it — this single transition is what makes it feel like Milanote/Figma rather than a generic list-based CRUD app.
- **View-mode switch (Canvas/List/Focus):** cross-fade + slight vertical settle (~150ms), never an abrupt cut, so the user's sense of "same data, different lens" is reinforced visually.
- Keep all durations short (100–250ms) and easing consistent (standard ease-in-out) — motion should feel responsive, never decorative or slow.

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
