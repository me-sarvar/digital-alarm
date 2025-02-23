import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:focus/screens/time_picker.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

extension DateTimeExtension on DateTime {
  String format(String format) {
    if (format == 'HH:mm') {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    return toString();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedTime = DateTime.now().format('HH:mm');
  List<Map<String, dynamic>> alarms = [];
  bool isPlaying = false;
  Timer? _updateTimer;
  int currentProgress = 0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late AudioPlayer audioPlayer;
  Timer? _alarmCheckTimer;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _initAudio();
    selectedTime = DateTime.now().format('HH:mm');

    _alarmCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
    

    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateProgress();
        if (alarms.isEmpty) {
          selectedTime = DateTime.now().format('HH:mm');
        }
      });
    });
  }

  Future<void> _initAudio() async {
    try {
      audioPlayer = AudioPlayer();
      await audioPlayer.setReleaseMode(ReleaseMode.stop);

    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    _updateTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _checkAlarms() {
    if (alarms.isEmpty) return;
    
    DateTime now = DateTime.now();
    for (var alarm in alarms.where((a) => a['isEnabled'])) {
      DateTime alarmTime = alarm['dateTime'] as DateTime;
      if (alarmTime.hour == now.hour && 
          alarmTime.minute == now.minute && 
          now.second == 0) {
        _triggerAlarm(alarm);
      }
    }
  }

  Future<void> _triggerAlarm(Map<String, dynamic> alarm) async {
    try {

      String soundName = alarm['sound'].toLowerCase();
      await audioPlayer.play(AssetSource('sounds/$soundName.mp3'));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        'Alarm',
        'Time for your ${alarm['time']} alarm!',
        platformChannelSpecifics,
      );

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text('Alarm', style: TextStyle(color: Color(0xFFA8C889))),
            content: Text('Time for your ${alarm["time"]} alarm!',
                style: TextStyle(color: Color(0xFFA8C889))),
            actions: [
              TextButton(
                child: Text('Stop', style: TextStyle(color: Color(0xFFA8C889))),
                onPressed: () {
                  audioPlayer.stop();
                  Navigator.of(context).pop();
                },
              ),
              if (alarm['snoozeEnabled'])
                TextButton(
                  child: Text('Snooze', style: TextStyle(color: Color(0xFFA8C889))),
                  onPressed: () {
                    _snoozeAlarm(alarm);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  void _snoozeAlarm(Map<String, dynamic> alarm) {
    DateTime newAlarmTime = DateTime.now().add(Duration(minutes: 5));
    setState(() {
      alarm['dateTime'] = newAlarmTime;
      alarm['time'] = newAlarmTime.format('HH:mm');
    });
  }

  void _openTimePicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimePicker(
          onTimeSelected: (hour, minute, settings) {
            final newTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
            setState(() {
              DateTime now = DateTime.now();
              DateTime newAlarmTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );
              
              if (newAlarmTime.isBefore(now)) {
                newAlarmTime = newAlarmTime.add(Duration(days: 1));
              }
              
              if (!alarms.any((alarm) => alarm['time'] == newTime)) {
                alarms.add({
                  'time': newTime,
                  'dateTime': newAlarmTime,
                  'isEnabled': true,
                  'sound': settings['sound'],
                  'snoozeEnabled': settings['snoozeEnabled'],
                  'repeatEnabled': settings['repeatEnabled'],
                });
                
                alarms.sort((a, b) => 
                  (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime)
                );
                selectedTime = newTime;
              }
            });
          },
        ),
      ),
    );
  }

  void _openCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFA8C889),
              surface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {

      setState(() {

      });
    }
  }

  String _getNextAlarmText() {
    if (alarms.isEmpty) return 'NO ALARMS SET';
    
    DateTime now = DateTime.now();
    DateTime? nextAlarm;
    
    for (var alarm in alarms.where((a) => a['isEnabled'])) {
      List<String> timeParts = alarm['time'].split(':');
      int hours = int.parse(timeParts[0]);
      int minutes = int.parse(timeParts[1]);
      
      DateTime alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours,
        minutes,
      );
      
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(Duration(days: 1));
      }
      
      if (nextAlarm == null || alarmTime.isBefore(nextAlarm)) {
        nextAlarm = alarmTime;
      }
    }
    
    if (nextAlarm == null) return 'NO ACTIVE ALARMS';
    
    Duration difference = nextAlarm.difference(now);
    int totalMinutes = difference.inMinutes;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return 'NEXT ALARM IN ${hours}H ${minutes}MIN';
    } else if (minutes > 0) {
      return 'NEXT ALARM IN ${minutes}MIN';
    } else {
      return 'ALARM NOW';
    }
  }

  void _updateProgress() {
    if (alarms.isEmpty || !alarms.any((a) => a['isEnabled'])) {
      currentProgress = 0;
      return;
    }

    DateTime now = DateTime.now();
    DateTime? nextAlarm;

    for (var alarm in alarms.where((a) => a['isEnabled'])) {
      List<String> timeParts = alarm['time'].split(':');
      int hours = int.parse(timeParts[0]);
      int minutes = int.parse(timeParts[1]);
      
      DateTime alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours,
        minutes,
      );
      
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(Duration(days: 1));
      }
      
      if (nextAlarm == null || alarmTime.isBefore(nextAlarm)) {
        nextAlarm = alarmTime;
      }
    }

    if (nextAlarm != null) {
      Duration difference = nextAlarm.difference(now);
      Duration totalDuration = Duration(hours: 24); // Maximum duration is 24 hours

      double progressPercent = 1 - (difference.inSeconds / totalDuration.inSeconds);
      currentProgress = (progressPercent * 40).floor();
      currentProgress = currentProgress.clamp(0, 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFA8C889),
      child: Scaffold(
        backgroundColor: Color(0xFFA8C889),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.6,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(55),
                    topRight: Radius.circular(55),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 60),
                        Text(
                          selectedTime,
                          style: TextStyle(
                            fontSize: 120,
                            color: Color(0xFFA8C889),
                            height: 0,
                          ),
                        ),
                        Text(
                          _getNextAlarmText(),
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF69745F),
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, left: 10),
                      child: CustomPaint(
                        painter: ProgressPainter(currentProgress),
                        size: Size(double.infinity, 150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                      .map(
                        (day) => Text(
                          day,
                          style: TextStyle(
                            fontSize: 22,
                            color:
                                DateTime.now().weekday ==
                                        [
                                              'MON',
                                              'TUE',
                                              'WED',
                                              'THU',
                                              'FRI',
                                              'SAT',
                                              'SUN',
                                            ].indexOf(day) +
                                            1
                                    ? Colors.black
                                    : Color(0xFF59644C),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: alarms.isEmpty 
                      ? [_buildEmptyCard()]
                      : alarms
                          .map((alarm) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildAlarmCard(alarm),
                              ))
                          .toList(),
                ),
              ),
            ),
          ],
        ),
        persistentFooterButtons: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _openCalendar,
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFFA8C889),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black,
                  fixedSize: Size(60, 60),
                ),
              ),
              SizedBox(
                width: 250,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (alarms.isNotEmpty) {
                      setState(() {
                        alarms[0]['isEnabled'] = !alarms[0]['isEnabled'];
                      });
                    }
                  },
                  label: Text(selectedTime, style: TextStyle(fontSize: 24),),
                  shape: StadiumBorder(),
                  backgroundColor: Colors.black,
                  foregroundColor: Color(0xFFA8C889),
                ),
              ),
              IconButton(
                onPressed: _openTimePicker,
                icon: Icon(
                  Icons.add,
                  color: Color(0xFFA8C889),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black,
                  fixedSize: Size(60, 60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: DottedBorder(
        color: Colors.grey,
        strokeWidth: 2,
        dashPattern: [5, 5],
        borderType: BorderType.RRect,
        child: Container(
          padding: EdgeInsets.all(8.0),
          width: 350,
          height: 150,
          child: Center(
            child: Text(
              'No alarms set',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF69745F),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: DottedBorder(
        color: Colors.grey,
        strokeWidth: 2,
        dashPattern: [5, 5],
        borderType: BorderType.RRect,
        child: Container(
          padding: EdgeInsets.all(8.0),
          width: 350,
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(alarm['time'], 
                      style: TextStyle(fontSize: 60)),
                  IconButton(
                    icon: Icon(
                      alarm['isEnabled'] ? Icons.pause : Icons.play_arrow,
                      size: 70,
                    ),
                    onPressed: () {
                      setState(() {
                        alarm['isEnabled'] = !alarm['isEnabled'];
                      });
                    },
                  ),
                ],
              ),
              Text(
                alarm['sound'],
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF69745F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final int totalBars = 40;
  final int currentProgress;
  
  ProgressPainter(this.currentProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double barSpacing = size.width / totalBars;

    for (int i = 0; i < totalBars; i++) {
      paint.color = Color(0xFFA8C889).withOpacity(0.3);
      canvas.drawLine(
        Offset(i * barSpacing, 0),
        Offset(i * barSpacing, size.height),
        paint,
      );
    }

    for (int i = 0; i < currentProgress; i++) {
      paint.color = Color(0xFFA8C889);
      canvas.drawLine(
        Offset(i * barSpacing, 0),
        Offset(i * barSpacing, size.height),
        paint,
      );
    }

    paint
      ..style = PaintingStyle.fill
      ..color = Color(0xFFA8C889);
    for (int i = 0; i < totalBars; i += 5) {
      canvas.drawCircle(Offset(i * barSpacing, -30), 3, paint);
    }

    if (currentProgress > 0) {
      paint.color = Colors.red;
      paint.strokeWidth = 3;

      canvas.drawLine(
        Offset(currentProgress * barSpacing, size.height),
        Offset(currentProgress * barSpacing, 0),
        paint,
      );

      final path = Path();
      final arrowX = currentProgress * barSpacing;
      path.moveTo(arrowX, -20);
      path.lineTo(arrowX - 10, -40);
      path.lineTo(arrowX + 10, -40);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress;
  }
}
