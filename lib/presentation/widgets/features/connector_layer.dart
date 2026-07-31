import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/pin_repository.dart';
import '../../../data/repository/connector_repository.dart';

final connectorsProvider = StreamProvider.family<List<ConnectorEntity>, String>((ref, boardId) {
  return ref.watch(connectorRepositoryProvider).watchConnectorsForBoard(boardId);
});

final pinsProvider = StreamProvider.family<List<PinEntity>, String>((ref, boardId) {
  return ref.watch(pinRepositoryProvider).watchPinsForBoard(boardId);
});

final connectorRenderDataProvider = Provider.family<List<ConnectorRenderData>, String>((ref, boardId) {
  final connectors = ref.watch(connectorsProvider(boardId)).value ?? [];
  final pins = ref.watch(pinsProvider(boardId)).value ?? [];
  final pinById = {for (final p in pins) p.id: p};
  
  return connectors
      .where((c) => pinById[c.fromPinId] != null && pinById[c.toPinId] != null)
      .map((c) {
        final fromPin = pinById[c.fromPinId]!;
        final toPin = pinById[c.toPinId]!;
        return ConnectorRenderData(
          connector: c,
          fromRect: Rect.fromLTWH(fromPin.x, fromPin.y, fromPin.width, fromPin.height),
          toRect: Rect.fromLTWH(toPin.x, toPin.y, toPin.width, toPin.height),
        );
      })
      .toList();
});

class ConnectorRenderData {
  final ConnectorEntity connector;
  final Rect fromRect;
  final Rect toRect;

  const ConnectorRenderData({
    required this.connector,
    required this.fromRect,
    required this.toRect,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectorRenderData &&
        other.connector == connector &&
        other.fromRect == fromRect &&
        other.toRect == toRect;
  }

  @override
  int get hashCode => Object.hash(connector, fromRect, toRect);
}

Offset edgeIntersection(Rect rect, Offset towards) {
  final center = rect.center;
  final dx = towards.dx - center.dx;
  final dy = towards.dy - center.dy;
  if (dx == 0 && dy == 0) return center;

  final scaleX = dx == 0 ? double.infinity : (rect.width / 2) / dx.abs();
  final scaleY = dy == 0 ? double.infinity : (rect.height / 2) / dy.abs();
  final scale = scaleX < scaleY ? scaleX : scaleY;

  return Offset(center.dx + dx * scale, center.dy + dy * scale);
}

Offset curveControlPoint(Offset start, Offset end, {double bow = 0.15}) {
  final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  final delta = end - start;
  final normal = Offset(-delta.dy, delta.dx); 
  return mid + normal * bow;
}

void paintArrowhead(Canvas canvas, Offset tip, double angleRadians, Paint paint) {
  const size = 9.0;
  const spread = 0.5;
  final p1 = tip - Offset(cos(angleRadians - spread), sin(angleRadians - spread)) * size;
  final p2 = tip - Offset(cos(angleRadians + spread), sin(angleRadians + spread)) * size;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(p1.dx, p1.dy)
    ..lineTo(p2.dx, p2.dy)
    ..close();
  canvas.drawPath(path, paint);
}

class ConnectorLayerPainter extends CustomPainter {
  ConnectorLayerPainter(this.connectors, this.colorScheme);
  
  final List<ConnectorRenderData> connectors;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final c in connectors) {
      final start = edgeIntersection(c.fromRect, c.toRect.center);
      final end = edgeIntersection(c.toRect, c.fromRect.center);
      final path = Path()..moveTo(start.dx, start.dy);

      double endAngle;
      final isCurved = c.connector.style == 'curved';
      if (isCurved) {
        final control = curveControlPoint(start, end);
        path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        endAngle = (end - control).direction;
      } else {
        path.lineTo(end.dx, end.dy);
        endAngle = (end - start).direction;
      }

      canvas.drawPath(path, linePaint);

      final fillPaint = Paint()
        ..color = linePaint.color
        ..style = PaintingStyle.fill;
      paintArrowhead(canvas, end, endAngle, fillPaint);
    }
  }

  @override
  bool shouldRepaint(ConnectorLayerPainter old) => !listEquals(old.connectors, connectors);
}

// For drag drafting
class ConnectorDraft {
  final String fromPinId;
  final Offset currentPointerWorldPos;

  ConnectorDraft({required this.fromPinId, required this.currentPointerWorldPos});
}

class DraftConnectorPainter extends CustomPainter {
  final Rect fromRect;
  final Offset currentPointer;
  final ColorScheme colorScheme;

  DraftConnectorPainter(this.fromRect, this.currentPointer, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final start = edgeIntersection(fromRect, currentPointer);
    
    final strokePaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
      
    final path = Path()
      ..moveTo(start.dx, start.dy);

    final control = curveControlPoint(start, currentPointer);
    path.quadraticBezierTo(control.dx, control.dy, currentPointer.dx, currentPointer.dy);
    final endAngle = (currentPointer - control).direction;

    canvas.drawPath(path, strokePaint);

    final fillPaint = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.fill;
    paintArrowhead(canvas, currentPointer, endAngle, fillPaint);
  }

  @override
  bool shouldRepaint(DraftConnectorPainter old) => true;
}
