# Epicordia — Device Home Screen Widgets

Widget UI designs for Android (Jetpack Glance) and iOS (WidgetKit/SwiftUI), built on the same design tokens as the main app (`epicordia-ui-design-document.md`), adapted for two real platform constraints explained below.

---

## 1. What's actually possible in a home screen widget (read before designing further)

- **No Flutter/Dart UI.** `home_widget` is purely a data bridge — it saves key/value data from the Flutter app and tells the OS to refresh the widget, but the widget's actual UI must be written natively: **Jetpack Glance (Compose) on Android**, **WidgetKit/SwiftUI on iOS**. This plan is a design spec both native implementations should follow, not Flutter code.
- **No text input.** Neither platform supports a live, typeable text field inside a widget. This rules out an inline "type your note here" widget — **Quick Capture as a widget must be a tap target that deep-links into the app's Zen Capture screen**, not an in-widget composer.
- **Limited interactivity, and it differs by platform.** Android (via Glance) can run a background action from a tap — e.g. completing a task — without opening the app at all. iOS (App Intents, iOS 16+) supports similar lightweight interactive buttons, but is more constrained; anything beyond a simple toggle should deep-link into the app instead of trying to force interactivity iOS doesn't reliably support.
- **Snapshot-based rendering, not live animation.** Widgets render as periodically-refreshed snapshots (iOS WidgetKit is explicitly timeline/snapshot-based; Android widgets refresh on a similar cadence), not a continuously running view. **The Task Status Control's full animated sequence (fill → checkmark draw → strikethrough sweep) does not run inside a widget** — a widget shows the ring's *resting* state (empty / half-filled / checkmark) and jumps directly to the new resting state on the next refresh after a tap. This is a legitimate, expected simplification, not a shortcut — it's how every well-behaved widget on both platforms works.

---

## 2. The widget set

### 2.1 Today Widget (primary — highest priority to build)
The single most-requested type of widget in the research behind this app: today's tasks, glanceable, no app-open required.

- **Small:** a count + the single most urgent task. Large numeral (Display style, `blue-600`/`blue-400`) showing "3 due today," with the top task's title (Body Strong, truncated) and its status ring beneath. Tapping anywhere opens the Today dashboard.
- **Medium:** a short list — 3–4 tasks, each a compact row: status ring + title + a small due-time chip, using the same visual language as the Tasks tab row (§4.8 of the UI doc), just without its animation. Tapping a row's ring **on Android** completes the task directly, in the background, no app launch (via a Glance action); **on iOS** tapping a row deep-links into the app with that task focused, since iOS interactive widget actions are more limited. Tapping anywhere else opens Today.
- **Large:** the medium layout extended to 6–8 tasks, plus a slim heatmap strip (last 14 days only, compact) at the bottom, tapping into Calendar view.
- **Colors/shape:** `surface-card` background (respecting system light/dark automatically — widgets should never hardcode a theme, they follow the OS setting the same way the app does), `radius-m` corners, `border-subtle` outline. Overdue tasks show their due-time chip in the `error` semantic color, exactly matching the in-app convention.

### 2.2 Quick Capture Widget (secondary — build alongside Today)
- **Small only** (this one doesn't benefit from a larger size). A single, large, centered pill button in `blue-600`/`blue-400` with a "+" icon and the label "Capture" — visually the widget-scale equivalent of the in-app Create button's `radius-pill` styling.
- **Behavior:** tapping it always deep-links straight into the app's **Zen Capture** screen (the same stripped-down text-field-and-save screen used in-app), landing the user directly in that flow — this is the honest resolution of the "no text input in widgets" constraint: the widget's whole job is shaving the taps needed to *reach* Zen Capture, not replacing it.
- A secondary, smaller variant can offer two stacked buttons ("Note" / "Task") if platform-specific widget configuration options are used to let the user pick a fixed widget "mode" at add-time — optional, not required for v1.

### 2.3 Unsorted Tray Widget (optional, build after Today + Quick Capture are solid)
- **Small:** just a count badge — "5 unsorted" — in a neutral tag color, tapping opens the Dashboard scrolled to the Unsorted tray.
- **Medium:** the count plus a 2–3 item preview (title only, no metadata, since these are unfiled/untyped by definition), same card styling as the rest of the set.
- Deliberately **does not** support in-widget filing (dragging a card onto a board isn't something a widget can do) — its only job is surfacing that something is waiting, consistent with the in-app tray's own "gentle nudge" philosophy already defined in the motion spec (the pulsing Create button when Unsorted has items).

### 2.4 Calendar Heatmap Widget (lowest priority — nice-to-have, build last)
- **Medium/Large only** (too small to read at Small size). Renders the same blue-intensity heatmap grid as the in-app Dashboard widget, last ~10–14 weeks depending on size. Tapping any cell (where the platform allows per-region tap targets — Android Glance supports this more reliably than iOS) opens Calendar view on that date; otherwise the whole widget just opens Calendar view.
- Purely informational — no interactivity beyond navigation, since a heatmap has nothing to "complete" or "capture."

---

## 3. Data flow (native widget ↔ app)

- The app writes a small, pre-computed JSON snapshot (today's tasks, unsorted count/preview, heatmap cell values) via `HomeWidget.saveWidgetData(...)` whenever the relevant Drift stream changes — **the widget itself should never query the database directly**; it only ever reads the last snapshot the app handed it, since widgets running natively don't have access to the Dart/Drift layer at all.
- `HomeWidget.updateWidget(...)` is called after every relevant write (completing a task, filing an unsorted item, etc.) so the widget refreshes promptly rather than waiting for the OS's own periodic refresh cycle.
- Interactive taps that complete a task **on Android** go through a background action that writes directly to the database via a lightweight native-to-Dart callback (per the interactive-widget pattern `home_widget` supports), then triggers the same snapshot-refresh path — so the widget, the app (if open), and every other view stay in sync exactly like any other write in the app, no special-cased "widget data" that could drift out of sync with the real database.

---

## 4. Suggested build placement

- **Today + Quick Capture widgets:** attach to the existing Phase 2 work (`antigravity-development-plan.md`) — both depend only on data that already exists by that phase (tasks, Zen Capture), and are the two highest-value widgets per the original product research on what people want from widgets.
- **Unsorted + Heatmap widgets:** attach to Phase 8 (cross-platform polish), once the Unsorted tray and Dashboard heatmap they mirror are fully built and stable — building a widget against a still-changing in-app feature just means rebuilding the widget twice.
