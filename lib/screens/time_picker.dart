import 'package:flutter/material.dart';

class TimePicker extends StatefulWidget {

  final void Function(int hour, int minute, Map<String, dynamic> settings)? onTimeSelected;
  const TimePicker({super.key, this.onTimeSelected});

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;


  late int selectedHour;
  late int selectedMinute;
  bool isSnoozeEnabled = false;
  bool isRepeatEnabled = false;
  String selectedSound = 'Minions';

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedHour = now.hour;
    selectedMinute = now.minute;
    
    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourController.jumpToItem(selectedHour);
      _minuteController.jumpToItem(selectedMinute);
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    child: Container(
                      alignment: Alignment.center,
                      width: 200,
                      height: 65,
                      decoration: BoxDecoration(color: Color(0xFF36402B), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWheelList(
                          controller: _hourController,
                          items: List.generate(24, (index) => index),
                          onChanged: (value) {
                            selectedHour = value;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 40,
                              color: Color(0xFFA8C899),
                            ),
                          ),
                        ),
                        _buildWheelList(
                          controller: _minuteController,
                          items: List.generate(60, (index) => index),
                          onChanged: (value) {
                            selectedMinute = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBottomActions(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon: Icon(Icons.close, color: Colors.green[200], size: 30), style: IconButton.styleFrom(fixedSize: Size(80, 80), backgroundColor: Color(0xFF10130D)),),
                Text('CHOOSE TIME',style: TextStyle(color: Colors.green[200], fontSize: 20, fontWeight: FontWeight.bold),),
                IconButton(onPressed: _saveAlarm, icon: Icon(Icons.check, color: Colors.black, size: 30), style: IconButton.styleFrom(fixedSize: Size(80, 80), backgroundColor: Color(0xFF98AC84)),),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _saveAlarm() {
    if (_isValidTime()) {

      final settings = {
        'sound': selectedSound,
        'snoozeEnabled': isSnoozeEnabled,
        'repeatEnabled': isRepeatEnabled,
      };
      
      widget.onTimeSelected?.call(selectedHour, selectedMinute, settings);
      Navigator.pop(context);
    }
  }

  bool _isValidTime() {
    return selectedHour >= 0 && selectedHour < 24 && 
           selectedMinute >= 0 && selectedMinute < 60;
  }

  Row _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBottomButton(
          Icons.music_note, 
          'SOUND\n$selectedSound',
          () => _showSoundPicker(),
        ),
        _buildBottomButton(
          Icons.notifications, 
          'SNOOZE\n${isSnoozeEnabled ? "ON" : "OFF"}',
          () => setState(() => isSnoozeEnabled = !isSnoozeEnabled),
        ),
        _buildBottomButton(
          Icons.repeat, 
          'REPEAT\n${isRepeatEnabled ? "YES" : "NO"}',
          () => setState(() => isRepeatEnabled = !isRepeatEnabled),
        ),
      ],
    );
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green[200], size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.green[200],
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelList({
    required FixedExtentScrollController controller,
    required List<int> items,
    required Function(int) onChanged,
  }) {
    return SizedBox(
      width: 70,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 80,
        physics: FixedExtentScrollPhysics(),
        perspective: 0.005,
        diameterRatio: 2.0,
        onSelectedItemChanged: (value) {
          setState(() {
            onChanged(value);
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            return Center(
              child: Text(
                items[index].toString().padLeft(2, '0'),
                style: TextStyle(
                  color: Color(0xFFA8C889),
                  fontSize: 60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSoundPicker() {
    final sounds = ['Default', 'Minions', 'Alarm', 'Minions-2', 'Korean'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF36402B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Sound',
              style: TextStyle(
                color: Color(0xFFA8C889),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...sounds.map(
              (sound) => ListTile(
                title: Text(
                  sound,
                  style: TextStyle(color: Color(0xFFA8C889)),
                ),
                trailing: selectedSound == sound
                    ? Icon(Icons.check, color: Color(0xFFA8C889))
                    : null,
                onTap: () {
                  setState(() {
                    selectedSound = sound;
                  });
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
