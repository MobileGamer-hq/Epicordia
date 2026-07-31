# Epicordia — Connector Logic & Flutter Implementation

How arrows between cards actually work: the geometry, the rendering approach, the interaction flow for creating/selecting one, and how it stays in sync as pins move.

---

## 1. Data flow (recap + how it feeds rendering)

A Connector is a row in the `Connectors` table: `boardId`, `fromPinId`, `toPinId`, `label` (nullable), `style` (`straight`/`curved`). It stores **which two pins** are connected — never coordinates. The actual line's start/end points are *derived*, every time, from wherever those two pins currently are:

```dart
// Riverpod provider — recomputes automatically whenever connectors
// OR either endpoint's position changes, since it watches both streams.
final connectorRenderDataProvider = 
    StreamProvider.family<List<ConnectorRenderData>, String>((ref, boardId) {
  final connectors$ = ref.watch(connectorDao).watchConnectorsForBoard(boardId);
  final pins$ = ref.watch(pinDao).watchPinsForBoard(boardId);

  return Rx.combineLatest2(connectors$, pins$, (connectors, pins) {
    final pinById = {for (final p in pins) p.id: p};
    return connectors
        .where((c) => pinById[c.fromPinId] != null && pinById[c.toPinId] != null)
        .map((c) => ConnectorRenderData(
              connector: c,
              fromRect: pinById[c.fromPinId]!.rect,
              toRect: pinById[c.toPinId]!.rect,
            ))
        .toList();
  });
});
```

This is the key architectural point: **a connector never stores or caches a line's coordinates.** It's recomputed live from the two pins' current rectangles, so dragging a pin around the canvas automatically drags every connector attached to it — there's nothing to manually "update" when a pin moves.

---

## 2. Geometry: anchoring a line to a card's edge — automatic by default, precisely adjustable when needed

A connector shouldn't visually start at the exact center of a card by default — it should start where a line from center-to-center would exit the card's rectangle. This is the **automatic** behavior, used whenever an endpoint's `anchorOffsetX/Y` is `null`:

```dart
/// Given a rectangle and a point outside it (the other pin's center),
/// returns the point on the rectangle's edge where a line from the
/// rectangle's center toward that point would exit.
Offset edgeIntersection(Rect rect, Offset towards) {
  final center = rect.center;
  final dx = towards.dx - center.dx;
  final dy = towards.dy - center.dy;
  if (dx == 0 && dy == 0) return center;

  // How far (as a multiple of the direction vector) until we hit
  // each pair of edges; take the smallest positive scale.
  final scaleX = dx == 0 ? double.infinity : (rect.width / 2) / dx.abs();
  final scaleY = dy == 0 ? double.infinity : (rect.height / 2) / dy.abs();
  final scale = scaleX < scaleY ? scaleX : scaleY;

  return Offset(center.dx + dx * scale, center.dy + dy * scale);
}
```

When a user has manually fine-tuned an endpoint (§4 step 5), `anchorOffsetX/Y` is set and simply overrides this calculation for that end — the resolved point becomes `pin.rect.topLeft + Offset(anchorOffsetX, anchorOffsetY)` directly, no intersection math needed, since the user already chose the exact spot.

When an endpoint has no attached pin at all (`fromPinId`/`toPinId` is `null`), the resolved point is just the stored `fromX/Y`/`toX/Y` value directly — a fixed point in world space that doesn't move with anything, since there's nothing for it to track.

```dart
Offset resolveEndpoint({
  required PinRect? pin,
  required Offset? manualOffset,
  required Offset? freeFloatingPoint,
  required Offset towardsForAutoIntersection,
}) {
  if (pin == null) return freeFloatingPoint!; // unattached end
  if (manualOffset != null) return pin.rect.topLeft + manualOffset; // fine-tuned
  return edgeIntersection(pin.rect, towardsForAutoIntersection); // automatic default
}
```

Used both ways — resolving the start point using the end pin's center (or its free-floating point) as the "towards" target, and vice versa for the end point.

### Straight vs. curved
- **Straight:** just draw the segment between the two edge points.
- **Curved:** a single quadratic Bézier, with the control point offset perpendicular to the midpoint — this is what gives a curved connector its gentle bow instead of a kink:

```dart
Offset curveControlPoint(Offset start, Offset end, {double bow = 0.15}) {
  final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  final delta = end - start;
  final normal = Offset(-delta.dy, delta.dx); // perpendicular
  return mid + normal * bow;
}
```

### Arrowhead
A small filled triangle at the end point, rotated to point along the line's final direction:

```dart
void paintArrowhead(Canvas canvas, Offset tip, double angleRadians, Paint paint) {
  const size = 9.0;
  const spread = 0.5; // radians, how wide the wedge is
  final p1 = tip - Offset(cos(angleRadians - spread), sin(angleRadians - spread)) * size;
  final p2 = tip - Offset(cos(angleRadians + spread), sin(angleRadians + spread)) * size;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(p1.dx, p1.dy)
    ..lineTo(p2.dx, p2.dy)
    ..close();
  canvas.drawPath(path, paint);
}
```
For a curved connector, `angleRadians` comes from the tangent at the curve's end (derivative of the quadratic Bézier at t=1), not the straight center-to-center angle — otherwise the arrowhead looks slightly wrong on a curve.

---

## 3. Rendering layer: one CustomPainter for every connector on the board

Don't build one `CustomPaint` widget per connector — with dozens of connectors that's dozens of separate layers being composited. Instead, **one painter draws every connector on the board in a single pass**, sitting in the canvas's transformed coordinate space, *below* the pin widgets so lines appear to run behind cards:

```dart
class ConnectorLayerPainter extends CustomPainter {
  ConnectorLayerPainter(this.connectors, this.colorScheme);
  final List<ConnectorRenderData> connectors;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.borderStrong
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final c in connectors) {
      final start = edgeIntersection(c.fromRect, c.toRect.center);
      final end = edgeIntersection(c.toRect, c.fromRect.center);
      final path = Path()..moveTo(start.dx, start.dy);

      double endAngle;
      if (c.connector.style == ConnectorStyle.curved) {
        final control = curveControlPoint(start, end);
        path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        endAngle = (end - control).direction; // tangent at t=1
      } else {
        path.lineTo(end.dx, end.dy);
        endAngle = (end - start).direction;
      }

      canvas.drawPath(path, linePaint);
      paintArrowhead(canvas, end, endAngle, linePaint..style = PaintingStyle.fill);
      if (c.connector.label != null) _paintLabel(canvas, path, c.connector.label!);
    }
  }

  @override
  bool shouldRepaint(ConnectorLayerPainter old) => 
      !listEquals(old.connectors, connectors); // only repaint if geometry actually changed
}
```

`_paintLabel` uses a `TextPainter` positioned at the path's midpoint, drawn on top of a small pill-shaped background rect (matching the `radius-pill` chip style from the UI doc) so the label stays legible over the dotted canvas background.

**Where this sits in the widget tree** (inside the same pan/zoom `Transform`/`InteractiveViewer` that positions the pins, so it pans/zooms in lockstep with everything else):

```dart
Transform(
  transform: canvasController.viewMatrix, // pan/zoom, shared with pins
  child: Stack(
    children: [
      CustomPaint(
        size: Size.infinite,
        painter: ConnectorLayerPainter(connectors, theme.colorScheme),
      ),
      ...pins.map((p) => Positioned(
            left: p.x, top: p.y, width: p.w, height: p.h,
            child: PinCard(pin: p),
          )),
    ],
  ),
)
```

---

## 4. Interaction: creating a connector

Mirrors Milanote's actual mechanic, confirmed from its own help documentation — not four handles at each edge, but **one anchor bubble** plus a **second, independent creation path** from the toolbar:

1. **Selecting or hovering a pin** reveals a single small circular anchor — a circle-with-arrow icon, per the UI doc's circular-icon-container rule — positioned at the pin's **top-right corner** (not one handle per edge). This is the primary, fastest way to start a connector from an existing card.
2. **Dragging from that anchor** starts the same ephemeral drag state as before:
   ```dart
   final connectorDraftProvider = StateProvider<ConnectorDraft?>((ref) => null);
   // ConnectorDraft { fromPinId, currentPointerWorldPos }
   ```
   A lightweight second painter draws just this in-progress line, following the pointer every frame.
3. **A second, independent creation path exists from the toolbar's connector tool:** dragging it onto empty canvas creates a short, fully unattached connector with **both** ends initially free-floating near the drop point — the user then drags each end independently onto a card (or leaves either end floating in space; this is explicitly allowed, matching Milanote's "manually position each end" behavior, and is why `fromPinId`/`toPinId` are nullable with `fromX/Y`/`toX/Y` fallbacks in the schema).
4. **On pointer-up** for any end being dragged (from either creation path), hit-test the drop position against every pin's rectangle (world coordinates, §6). Three outcomes: it lands on a pin → attach (`...PinId` set, offset fields left `null` for automatic edge-intersection); it lands in empty space → that end simply stays a free-floating point (`...PinId` stays/becomes `null`, `...X`/`...Y` set to the drop position); nothing is ever silently discarded the way an unattached single-anchor drag used to be — a connector is valid with zero, one, or two attached ends.
5. **Fine-tuning an existing endpoint:** dragging an already-connected end again lets the user adjust exactly where it touches the target card — as the dragged point nears the card's boundary, a small circle indicator shows the nearest valid snap point; releasing there sets that end's `anchorOffsetX/Y` (relative to the pin's bounds) instead of leaving it on automatic center-facing intersection. This is what lets two connectors both touching the same card visually enter/exit at different, deliberately-chosen points rather than always converging on the same auto-computed spot.
6. **Holding Shift while dragging an end** constrains the line to the nearest perfectly horizontal or vertical angle relative to its fixed other end — a small, cheap addition (clamp the drag angle to the nearest multiple of 90° when the modifier is held) that makes tidy diagram-style connections easy.

---

## 5. Interaction: selecting/editing an existing connector

Since a connector is just a rendered line (not its own widget with its own `GestureDetector`), tapping one needs manual hit-testing against the path:

```dart
bool isNearConnector(Offset tapWorldPos, ConnectorRenderData c, {double threshold = 10}) {
  final start = edgeIntersection(c.fromRect, c.toRect.center);
  final end = edgeIntersection(c.toRect, c.fromRect.center);
  // Sample the path (straight segment or Bézier) at N points and take
  // the minimum distance from the tap to any sampled point.
  final samples = c.connector.style == ConnectorStyle.curved
      ? _sampleBezier(start, curveControlPoint(start, end), end, steps: 20)
      : [start, end];
  double minDist = double.infinity;
  for (var i = 0; i < samples.length - 1; i++) {
    final d = _distanceToSegment(tapWorldPos, samples[i], samples[i + 1]);
    if (d < minDist) minDist = d;
  }
  return minDist <= threshold;
}
```

The canvas's tap handler runs pin hit-testing first (pins sit visually on top and should win any overlapping tap), and only checks connectors for taps that don't land on a pin. A hit selects the connector and reveals its **bend handle** (§ below) plus opens the **floating popover** (per the UI doc's light-interaction overlay pattern) offering: change style (straight/curved), delete.

**Editing a label directly, without opening a menu:** once a connector is selected, typing (desktop keyboard input, or a small inline text affordance on touch) writes straight into its `label` field, positioned at the connector's midpoint — matching Milanote's own "select a line and start typing" behavior. The floating popover's "Label" option remains as a discoverable alternative for anyone who selects via long-press/right-click first, but typing directly should always work once a connector is the current selection.

**Straightening a bent connector:** in addition to a "Straighten" action in the popover, double-tapping (or double-clicking) the bend handle itself (§3) resets `bendOffsetX`/`bendOffsetY` back to `null` immediately — a faster, more direct shortcut for the same action, matching Milanote's own handle-double-click behavior.

---

## 6. Screen-space ↔ world-space conversion

Every gesture callback in Flutter reports positions in the widget's local (screen) coordinates, but connector geometry and pin rectangles are stored in **world** coordinates (unaffected by the current pan/zoom). Every tap/drag position must be converted through the inverse of the canvas's current view matrix before it's used for hit-testing or drawing a draft connector:

```dart
Offset screenToWorld(Offset screenPoint, Matrix4 viewMatrix) {
  final inverse = Matrix4.inverted(viewMatrix);
  final v = inverse.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
  return Offset(v.x, v.y);
}
```

This one conversion function is reused everywhere: placing a new pin where the user tapped, hit-testing a connector tap, and tracking the live draft-connector line during a drag.

---

## 7. Performance notes
- Batch all connectors into one `CustomPainter` (§3) — never one painter/widget per connector.
- `shouldRepaint` should do a cheap equality check on the resolved render-data list, not always return `true` — with `ConnectorRenderData` as an immutable value object, a `listEquals` check is enough to skip repainting when nothing relevant changed.
- During an active pin drag, only that pin's position needs to update per-frame; the connector layer recomputes only the connectors touching that one pin's id, not the full list — worth memoizing per-pin so a drag with 50 unrelated connectors on the board doesn't recompute all 50 every frame.
