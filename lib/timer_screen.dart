import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math';
import 'package:http/http.dart' as http;

class TimerScreen extends StatefulWidget {
  final IO.Socket socket;

  TimerScreen({required this.socket});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  bool isCountingDown = false;

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    widget.socket.on('test-completed', (data) {
      // Показываем уведомление
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Уведомление"),
              content: Text("Тест завершен"),
              actions: [
                TextButton(
                    onPressed: onContinuePressed,
                    child: Text('Продолжить работу')),
                TextButton(
                    onPressed: onFinishPressed,
                    child: Text('Завершить работу')),
              ],
            );
          });
    });
  }

  Future<void> sendCommand(String command) async {
    await http.post('http://localhost:3000/command' as Uri,
        body: {'command': command});
  }

  Future<void> onContinuePressed() async {
    Navigator.pop(context);

    await sendCommand('minimize_wpf');
  }

  void onFinishPressed() {
    Navigator.pop(context);
  }

  void startCountdown() {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;

    setState(() {
      isCountingDown = true;
    });

    Future.delayed(Duration(seconds: totalSeconds), () {
      setState(() {
        isCountingDown = false;
      });
    });
  }

  void sendTimeToServer() {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;

    print('Sending time: $hours:$minutes:$seconds');
    widget.socket.emit('time-received', totalSeconds);

    startCountdown();
  }

  int calculateRemainingSeconds() {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    return totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Лимит времени'),
        backgroundColor: Color.fromRGBO(119, 75, 36, 1),
        foregroundColor: Color.fromRGBO(239, 206, 173, 1),
      ),
      body: Container(
        color: const Color(0xFFEFCEAD),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: CircleProgressPainter(
                      remainingSeconds: calculateRemainingSeconds()),
                  child: Center(
                    child: isCountingDown
                        ? CountdownTimer(
                            seconds: calculateRemainingSeconds(),
                            onFinish: () {
                              setState(() {
                                isCountingDown = false;
                              });
                            },
                          )
                        : Text(
                            formatTime(calculateRemainingSeconds()),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(119, 75, 36, 1),
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NumberPicker(
                    title: 'Часы',
                    minValue: 0,
                    maxValue: 23,
                    onChanged: (value) {
                      setState(() {
                        hours = value;
                      });
                    },
                  ),
                  NumberPicker(
                    title: 'Минуты',
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) {
                      setState(() {
                        minutes = value;
                      });
                    },
                  ),
                  NumberPicker(
                    title: 'Секунды',
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) {
                      setState(() {
                        seconds = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              AnimatedBuilder(
                animation: _buttonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScaleAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTapDown: (_) {
                    _buttonAnimationController.forward();
                  },
                  onTapUp: (_) {
                    _buttonAnimationController.reverse();
                    sendTimeToServer();
                  },
                  onTapCancel: () {
                    _buttonAnimationController.reverse();
                  },
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Color.fromRGBO(119, 75, 36, 1),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            color: Color.fromRGBO(239, 206, 173, 1),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Установить таймер',
                            style: TextStyle(
                              color: Color.fromRGBO(239, 206, 173, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  String formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}';
  }
}

class NumberPicker extends StatefulWidget {
  final String title;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  NumberPicker({
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  _NumberPickerState createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  int value = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.title,
            style: TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(119, 75, 36, 1),
            )),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              value = (value + (details.primaryDelta! > 0 ? 1 : -1)) %
                  (widget.maxValue + 1);
              if (value < widget.minValue) {
                value = widget.maxValue;
              }
              widget.onChanged(value);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Color.fromRGBO(119, 75, 36, 1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(119, 75, 36, 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final int remainingSeconds;

  CircleProgressPainter({required this.remainingSeconds});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * (remainingSeconds / (24 * 3600));

    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onFinish;

  CountdownTimer({required this.seconds, required this.onFinish});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    startCountdown();
  }

  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
          widget.onFinish();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int hours = _remainingSeconds ~/ 3600;
    final int minutes = (_remainingSeconds % 3600) ~/ 60;
    final int seconds = _remainingSeconds % 60;

    return Text(
      '$hours : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
