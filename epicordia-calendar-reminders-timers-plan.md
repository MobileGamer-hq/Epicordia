# Epicordia — Calendar, Reminders & Timers Integration Plan

Three separate device capabilities, each with real platform asymmetry between iOS and Android — this plan treats them as three distinct integrations rather than one generic "device sync" feature, because that's what the underlying OS APIs actually are.

---

## 1. The platform reality (read this first)

| Capability | iOS | Android |
|---|---|---|
| **Calendar** | EventKit (`EKEvent`) — full read/write | Calendar Provider — full read/write |
| **Reminders** | EventKit (`EKReminder`) — a genuinely separate system from Calendar, with its own app | **No OS-level equivalent.** Android has no unified "Reminders" system API — reminder-style features on Android are just local notifications |
| **Timers/Alarms** | **No public API.** Apple does not let third-party apps create entries in the native Clock app | `android.provider.AlarmClock` intents — a real, documented way to hand off to the system Clock app's Alarm and Timer screens |

This asymmetry is unavoidable, not a gap in our planning — it comes directly from what each OS actually exposes to third-party apps. The plan below embraces it rather than pretending both platforms can do the same thing.

---

## 2. Calendar (two-way sync) — package decision

**Use `device_calendar_plus`**, not the older `device_calendar` package. The original is effectively abandoned; `device_calendar_plus` is its modern, actively maintained replacement, built and run in production by the makers of Bullet — a task/notes/calendar Flutter app with almost the exact same shape as Epicordia's calendar needs.

Why it's the right fit specifically for us:
- **Full RRULE support with a typed `RecurrenceRule` model** — matches our own `Tasks.recurrenceRule` design directly, no format translation needed.
- **Edit or delete a whole series, this-and-following, or a single occurrence** — this resolves an open question flagged back in the schema-corrections work ("editing 'this one' vs. 'this and all future' is a UX decision to design explicitly later"). The package already models this distinction, so our own recurring-task edit UI can map directly onto it rather than inventing our own semantics.
- **A write-only permission tier** — lets Epicordia request *only* the ability to create/update events it made itself, without necessarily requesting full read access to the user's entire calendar, which is a meaningfully better privacy posture and an easier permission prompt for the user to say yes to.
- Handles the iOS EventKit ↔ Android Calendar Provider inconsistencies (timezones, recurrence quirks) internally, which is exactly the kind of cross-platform glue not worth re-solving ourselves.

**This confirms and slightly refines the Phase 5 calendar work already in the dev plan** — the two-way sync, conflict handling (last-write-wins by timestamp), and RRULE mapping described there now has a concrete package to implement against.

---

## 3. Reminders — iOS-specific, native Reminders app integration

**Use `in_app_reminder`** (wraps EventKit's `EKReminder`) — creates real entries in the iOS **Reminders** app: title, notes, due date/time, recurrence.

### How this actually gets used
- This is an **opt-in, per-task toggle**, not automatic for every task — call it "Also add to Reminders" in a task's Pin Editor, visible only on iOS (the toggle simply doesn't render on Android, since there's nothing to sync to).
- **Avoid double-notifying the user.** If a task is synced to a native `EKReminder`, the Reminders app itself is responsible for alerting the user at the due time — Epicordia should *not* also fire its own local notification for that same task, or the user gets pinged twice for one thing. If the toggle is off (the default), Epicordia's own local notification (§5) is the only alert, as already planned.
- **On Android**, "reminders" has no separate OS concept to hook into — a task's reminder is simply our own local notification, full stop. No toggle is shown because there's nothing extra to opt into.

### Schema addition
Add `Tasks.osReminderId` (nullable text) — the `EKReminder` identifier, set only when the per-task toggle is on (iOS only; always `null` on Android). Deleting or un-toggling removes the corresponding `EKReminder` via the plugin.

---

## 4. Timers/Alarms — Android system handoff, iOS in-app fallback

**Use `flutter_alarm_clock`** on Android — a thin wrapper around `android.provider.AlarmClock` intents that hands off directly to the system Clock app:
- `createAlarm(hour, minutes, title)` — sets a real system alarm.
- `createTimer(length, title)` — starts a real system timer.
- `showAlarms()` / `showTimers()` — opens the Clock app directly to those screens.

### How this actually gets used
- A **"Start Timer" action** on any Task card's floating popover (light-weight interaction, per the UI doc's overlay system): pick a duration, optionally attach it to the task's title as the timer's label.
- **On Android:** the duration is handed off to the system Clock app via `createTimer()` — this is deliberately more reliable than an app-scheduled notification, since system timers aren't subject to battery-optimization/Doze restrictions the way a backgrounded app's own scheduling can be.
- **On iOS**, since there's no public API for the Clock app, the same "Start Timer" action instead schedules one of Epicordia's own local notifications (§5) for now + duration, with a small note in the UI ("Timer will notify you here — iOS doesn't allow apps to add timers to the Clock app") so the user understands *why* the two platforms feel different, rather than the app silently behaving inconsistently.
- **Alarms** (a specific wall-clock time, not a duration) work the same way: Android hands off to `createAlarm()`; iOS falls back to a scheduled local notification at that exact time.

This is a UX-honesty decision worth being explicit about: rather than faking parity between platforms, the in-app copy should say what's actually happening, since a user who knows *why* their Android timer rings even with the app closed, while their iPhone's doesn't behave quite the same, trusts the app more than one that pretends both are identical.

---

## 5. Local notifications — the cross-platform baseline everything else sits on top of

**Use `flutter_local_notifications`** (already planned for Phase 2/5) as the one mechanism that always works, on both platforms, regardless of whether Calendar/Reminders/Timer integrations are enabled:
- Fires for every task's due date/scheduled date by default.
- Is the **iOS fallback** for the Timer feature (§4).
- Is the **entirety** of "reminders" on Android, since there's no OS Reminders API to integrate with (§3).
- Is suppressed for a specific task only when that task has an active `osReminderId` (§3) on iOS, to avoid the double-notification problem.

---

## 6. Permission request UX

Consistent with the app's broader "ask nothing until it's needed" philosophy (already established for calendar sync in the app-flow doc):
- **Calendar permission** is requested the first time a task gets a due date *and* the user has calendar sync enabled in Settings (not on first launch).
- **Reminders permission** (iOS) is requested the first time the user toggles "Also add to Reminders" on any task — not proactively.
- **Timer/Alarm handoff** requires no special runtime permission on Android (the `AlarmClock` intents are just requests to the Clock app, not a permission grant) — nothing to ask for here at all.
- Every permission prompt should be preceded by Epicordia's own brief explanation of *why* (a short in-app message before the OS dialog appears), rather than surprising the user with a bare system permission sheet.

---

## 7. Schema additions (summary)

| Table | New field | Purpose |
|---|---|---|
| `Tasks` | `osReminderId` (nullable text) | iOS `EKReminder` identifier, set only when the per-task "Also add to Reminders" toggle is on |
| `Tasks` | `calendarEventId` | *(already existed — no change; this is the `device_calendar_plus` event id for the two-way calendar sync)* |

No new table is needed for Timers — a "Start Timer" action is an ephemeral, one-off intent handoff (or a one-off scheduled local notification on iOS), not something that needs its own persisted row, since it isn't a recurring or trackable entity the way a Task or Reminder is.

---

## 8. Where this fits in the build plan

All of §2–§6 extend **Phase 5 (Calendar Sync & Notifications)** in `antigravity-development-plan.md` — this plan doesn't require a new phase, but Phase 5's task list should be read as now including: adopting `device_calendar_plus` specifically (not a generic "a calendar package"), the iOS Reminders toggle + `osReminderId` field, and the Timer action + `flutter_alarm_clock` handoff. Phase 5's Gate Check should be extended to include: a manual test of the Reminders toggle on iOS (confirming no double-notification), and a manual test of the Timer action on both platforms (confirming the Android system handoff actually rings, and the iOS fallback notification fires at the right time).
