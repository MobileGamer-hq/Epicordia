enum TimerState { idle, running, paused, finished }

class InAppTimer {
  final Duration totalDuration;
  final Duration remainingDuration;
  final TimerState state;
  final String? label;
  final String? linkedTaskId;

  const InAppTimer({
    required this.totalDuration,
    required this.remainingDuration,
    this.state = TimerState.idle,
    this.label,
    this.linkedTaskId,
  });

  double get progressFraction {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    final elapsed = totalDuration.inMilliseconds - remainingDuration.inMilliseconds;
    return (elapsed / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get formattedRemaining {
    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  InAppTimer copyWith({
    Duration? totalDuration,
    Duration? remainingDuration,
    TimerState? state,
    String? label,
    String? linkedTaskId,
  }) {
    return InAppTimer(
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      state: state ?? this.state,
      label: label ?? this.label,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
    );
  }
}
