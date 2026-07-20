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

## 2. Geometry: anchoring a line to a card's edge, not its center

A connector shouldn't visually start at the exact center of a card (it'd look like it's floating over the content) — it should start where a line from center-to-center would exit the card's rectangle. This is a standard line–rectangle clipping calculation:

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

Used both ways — `edgeIntersection(fromRect, toRect.center)` for the start point, `edgeIntersection(toRect, fromRect.center)` for the end point. The result: a line that visibly touches each card's border, on whichever side actually faces the other card.

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

Mirrors Milanote's own convention — small handles appear on a selected card's edges, and dragging from one to another card creates the arrow:

1. **Selecting a pin** reveals four small circular connector handles at the midpoint of each edge (top/right/bottom/left), styled per the UI doc's circular-icon-container rule, visible only while that pin is selected/hovered.
2. **Dragging from a handle** starts a temporary, ephemeral drag state (not written to the database yet):
   ```dart
   final connectorDraftProvider = StateProvider<ConnectorDraft?>((ref) => null);
   // ConnectorDraft { fromPinId, currentPointerWorldPos }
   ```
   A lightweight second painter draws just this one in-progress line, following the pointer every frame, with no arrowhead-target logic needed yet — a plain dashed line to the current pointer position reads clearly as "still deciding."
3. **On pointer-up**, hit-test the drop position against every pin's rectangle (in world coordinates — see §5 for the screen→world conversion). If it lands on a valid, different pin, commit: insert a new `Connectors` row (`fromPinId`, `toPinId`); if it misses every pin (dropped on empty canvas), discard the draft with no database write.
4. The pin-tray's dedicated Connector tool (§4.3 of the UI doc) is an alternative entry point for the same gesture, for anyone who prefers explicitly choosing "I'm making a connector now" over discovering the edge handles.

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

The canvas's tap handler runs pin hit-testing first (pins sit visually on top and should win any overlapping tap), and only checks connectors for taps that don't land on a pin. A hit opens the **floating popover** (per the UI doc's light-interaction overlay pattern) anchored at the tap point, offering: change style (straight/curved), edit label, delete.

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
