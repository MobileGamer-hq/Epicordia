# Epicordia — App Flow

This document maps every screen and the paths between them. It should be read alongside the AI Design Document (functional spec) and the UI Design Document (visual system).

---

## 1. Top-level navigation map

```
                          ┌─────────────────────┐
                          │   App Launch          │
                          │ (no login, no splash   │
                          │  account screen)       │
                          └──────────┬────────────┘
                                     │
                          ┌──────────▼────────────┐
                          │   First-run only:      │
                          │  "Visual planner or    │
                          │   list person?" +      │
                          │   optional lock setup  │
                          └──────────┬────────────┘
                                     │
                          ┌──────────▼────────────┐
                          │   DASHBOARD (Home)     │◄──────────────┐
                          │  = landing screen      │                │
                          └──┬───┬───┬───┬───┬────┘                │
                             │   │   │   │   │                     │
        ┌────────────────────┘   │   │   │   └───────────────┐     │
        │                        │   │   │                    │     │
        ▼                        ▼   ▼   ▼                    ▼     │
┌───────────────┐   ┌─────────────┐ ┌──────────┐   ┌──────────────┐│
│  Boards Hub    │   │  Notes tab   │ │ Tasks tab │   │ Calendar view││
│ (all boards)   │   │  (flat list) │ │(flat list)│   │ (month/week) ││
└───────┬────────┘   └──────┬──────┘ └────┬─────┘   └──────┬───────┘│
        │                   │             │                │        │
        ▼                   │             │                │        │
┌───────────────┐           │             │                │        │
│ BOARD screen   │◄──────────┴─────────────┴────────────────┘        │
│ (Canvas/List/  │  (tapping a note or task opens its parent board,  │
│  Focus toggle) │   scrolled/zoomed to that item)                   │
└───┬────────┬───┘                                                   │
    │        │                                                       │
    │        └── nested board pin → opens child BOARD screen          │
    │            (breadcrumb trail grows; back = breadcrumb tap)      │
    │                                                                 │
    └── pin tap → Pin Editor (modal/panel, type-specific)             │
                                                                       │
        Global, reachable from anywhere via sidebar/nav:              │
        ┌──────────────┐  ┌───────────────┐  ┌───────────────┐       │
        │ Search        │  │ Settings       │  │ Quick Capture  │──────┘
        │ (full-text)   │  │                │  │ (FAB / widget) │
        └──────────────┘  └───────────────┘  └───────────────┘
```

---

## 2. Screen inventory

| # | Screen | Reached from | Purpose |
|---|---|---|---|
| 1 | **First-run setup** | App's very first launch only | Set visual-vs-list default, optional PIN/biometric lock, nothing account-related |
| 2 | **Dashboard (Home)** | App launch (every subsequent time), sidebar "Home" | Landing screen: today's tasks, all boards grouped with Important/Urgent surfaced, Calendar Heatmap, mini calendar |
| 3 | **Boards Hub** | Sidebar "Boards" | Full grid/list of all top-level boards, "+ New board" |
| 4 | **Board screen** | Boards Hub, Dashboard board cards, nested board pin, Notes/Tasks tab item tap | The core workspace: Canvas / List / Focus toggle over one board's content |
| 5 | **Pin Editor** | Tapping/opening any pin on a board | Type-specific editing surface (note text, task detail, image, drawing, etc.) — opens as a side panel on tablet/desktop, full-screen sheet on phone |
| 6 | **Notes tab** | Sidebar "Notes" | Flat, searchable list of every note pin across all boards |
| 7 | **Tasks tab** | Sidebar "Tasks" | Flat, filterable list of every task across all boards, with blocked/unblocked and kanban-stage filters where applicable |
| 8 | **Calendar view** | Sidebar "Calendar", Dashboard mini calendar "expand" | Month/week grid combining app tasks/milestones and synced device calendar events |
| 9 | **Quick Capture** | FAB (bottom-right on phone/tablet, near sidebar on desktop), home-screen widget | Zen/Focus capture: text field + save only, lands in Inbox board |
| 10 | **Search** | Sidebar/top-bar search icon, keyboard shortcut on desktop | Full-text search across boards, notes, tasks |
| 11 | **Settings** | Sidebar "Settings" | Theme, default view mode, app lock, backup/export/import, calendar sync, notification preferences, storage |
| 12 | **App Lock screen** | App resume/launch, if enabled | PIN/biometric gate before Dashboard loads |

---

## 3. Detailed flows

### 3.1 First launch
1. App opens directly to a short first-run flow (no account creation, no login fields anywhere) — a single screen asking "Do you think in lists or in boards?" (sets default view mode preference, changeable later in Settings).
2. Optional: "Set up an app lock?" — Yes leads to PIN/biometric setup; No skips straight through.
3. Lands on Dashboard, empty state: a friendly prompt to create the first board or capture the first note/task, plus 2–3 starter templates (mirroring Milanote's template-driven onboarding) so the canvas doesn't feel intimidating on first open.

### 3.2 Daily-use loop (the most common path)
1. Open app → **Dashboard** (or App Lock first, if enabled).
2. Glance at today's tasks + heatmap + Important/Urgent boards.
3. Either: tap a task to complete it inline, tap a board card to enter that **Board screen**, or tap the **Quick Capture** FAB to jot something new without navigating anywhere.
4. From a Board screen, toggle Canvas/List/Focus as needed; drag pins on Canvas, check off items in List/Focus.
5. Return to Dashboard via sidebar "Home" or back navigation.

### 3.3 Working inside a board
1. Enter a **Board screen** from any entry point.
2. Breadcrumb bar at the top shows the nesting path (e.g. `Home / Projects / Spring Streetwear / Materials`).
3. Left pin tray (rail) lets the user drag a new pin type onto the canvas, or tap+place on touch devices.
4. Tapping an existing pin opens its **Pin Editor** — side panel on tablet/desktop so the board stays visible behind it, full-screen modal sheet on phone.
5. Double-tapping/clicking a nested board pin pushes into that child board; breadcrumb grows by one level; tapping any earlier breadcrumb segment jumps back directly (not just one level at a time).
6. The Canvas/List/Focus toggle (top-right, near the other icons) re-renders the same underlying pins without navigating away — switching modes is not a new "screen," just a re-render.

### 3.4 Quick Capture flow (Zen mode)
1. Triggered from the FAB, home-screen widget, or (desktop) a keyboard shortcut.
2. Opens directly to a blank text field with only a Save action visible — no board picker, no tags, no color, no kanban stage.
3. Save → item is created in the Inbox board as a Note or Task (auto-detected: if it looks like an actionable item or the user taps a small "make this a task" toggle, otherwise it's a note) and the capture sheet closes back to whatever screen the user was on.
4. Later, from the Inbox board (reachable via Boards Hub or a Dashboard shortcut), the user triages captured items into their proper boards.

### 3.5 Search flow
1. Search icon/shortcut opens a search overlay from any screen.
2. Typing filters live across boards, notes, and tasks; results are grouped by type.
3. Tapping a result jumps directly into context: a note result opens its board (scrolled to that pin in Canvas, or highlighted in List); a task result opens the Tasks tab detail or its board.

### 3.6 Calendar sync flow (background, not a distinct screen the user "flows through," but touches the Calendar view and Settings)
1. First time a task gets a due date, or the user opens Calendar view, the app requests device calendar permission if not already granted.
2. Once granted, sync runs in the background (two-way); Settings has a "Calendar sync" row showing last-synced time and a manual "Sync now" action.

### 3.7 Backup/export flow
1. Settings → "Backup & Data" section.
2. Shows last automatic local backup timestamp; manual "Export workspace now" and "Import from file" actions live here.
3. Import flow always confirms merge-vs-replace before touching existing data, with a clear warning if "replace" is chosen.

---

## 4. Responsive navigation shifts (same screens, different chrome)

| Breakpoint | Primary navigation | Board screen adaptation |
|---|---|---|
| **Phone (<600px)** | Bottom tab bar or slide-over drawer (Home, Boards, Notes/Tasks combined, Calendar, More) — full sidebar is hidden | Pin tray collapses into a bottom sheet/FAB menu; Pin Editor opens full-screen |
| **Tablet (600–1024px)** | Collapsible navigation rail (icons, expandable to labels) | Pin tray stays as a slim left rail; Pin Editor opens as a side panel |
| **Desktop (>1024px)** | Persistent full sidebar with labels, always visible | Pin tray + breadcrumb + top-right icon cluster all visible at once, matching the reference layout (Milanote-style) |

This mirrors the researched pattern: sidebars are for larger screens, phones get a bottom bar or drawer, tablets get a nav rail — never the same fixed sidebar forced onto every size.
