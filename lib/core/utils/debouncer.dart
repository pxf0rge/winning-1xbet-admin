import 'dart:async';

/// Coalesces rapid callbacks (e.g. Realtime storms) into one delayed action.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 450)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
