import 'dart:async';

/// Manages the inactivity timer that locks the vault automatically.
///
/// Usage:
///   - Call [start] once after successful auth.
///   - Call [resetTimer] on every user interaction.
///   - [onLock] is triggered when the timer fires.
///   - Call [stop] when the session ends.
class AutoLockService {
  AutoLockService({required this.onLock});

  /// Callback invoked when the vault should be locked.
  final void Function() onLock;

  Timer?    _timer;
  Duration  _timeout = const Duration(minutes: 2);
  DateTime? _lastActivity;

  // ── Configuration ──────────────────────────────────────────────────────────

  void setTimeout(int minutes) {
    _timeout = Duration(minutes: minutes);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Starts (or restarts) the inactivity timer.
  void start() {
    stop();
    _lastActivity = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), _tick);
  }

  /// Resets the inactivity clock. Call on every meaningful user action.
  void resetTimer() {
    _lastActivity = DateTime.now();
  }

  /// Stops the timer without triggering a lock.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastActivity = null;
  }

  bool get isRunning => _timer != null && (_timer?.isActive ?? false);

  // ── Internal ───────────────────────────────────────────────────────────────

  void _tick(Timer _) {
    final last = _lastActivity;
    if (last == null) return;
    if (DateTime.now().difference(last) >= _timeout) {
      stop();
      onLock();
    }
  }
}
