import 'dart:async';

class AutoSaveTimer {
  late int _intervalMinutes; //保存间隔时间（分钟）
  late Function _onSave; //保存回调函数
  late Function _onTick; //每秒回调函数
  Timer? _timer; //定时器

  AutoSaveTimer({
    required int intervalMinutes,
    required Function onSave,
    required Function onTick,
  }) {
    _intervalMinutes = intervalMinutes;
    _onSave = onSave;
    _onTick = onTick;
    _startTimer();
  }

  void _startTimer() {
    int secondsRemaining = _intervalMinutes * 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;
      _onTick(Duration(seconds: secondsRemaining));
      if (secondsRemaining <= 0) {
        _onSave();
        _startTimer();
      }
    });
  }

  void reset() {
    _startTimer();
  }

  void setIntervalMinutes(int minutes) {
    _intervalMinutes = minutes;
    reset();
  }

  void dispose() {
    _timer?.cancel();
  }
}
