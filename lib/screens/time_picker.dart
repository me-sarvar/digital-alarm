import 'package:flutter/material.dart';

class TimePicker extends StatefulWidget {
  final void Function(int hour, int minute)? onTimeSelected;
  const TimePicker({super.key, this.onTimeSelected});

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  int selectedHour = 0;
  int selectedMinute = 0;

  @override
  void initState() {
    // TODO: implement initState
    _hourController = FixedExtentScrollController(initialItem: 0);
    _minuteController = FixedExtentScrollController(initialItem: 0);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
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
                            setState(() {
                              selectedHour = value;
                            });
                            widget.onTimeSelected?.call(
                              selectedHour,
                              selectedMinute,
                            );
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
                            setState(() {
                              selectedMinute = value;
                            });
                            widget.onTimeSelected?.call(
                              selectedHour,
                              selectedMinute,
                            );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(Icons.music_note, 'SOUND\nWAKE UP'),
                  _buildBottomButton(Icons.notifications, 'SNOOZE\nEVERY 10 MIN'),
                  _buildBottomButton(Icons.repeat, 'REPEAT\nNO'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon: Icon(Icons.close, color: Colors.green[200], size: 30), style: IconButton.styleFrom(fixedSize: Size(80, 80), backgroundColor: Color(0xFF10130D)),),
                Text('CHOOSE TIME',style: TextStyle(color: Colors.green[200], fontSize: 20, fontWeight: FontWeight.bold),),
                IconButton(onPressed: (){}, icon: Icon(Icons.check, color: Colors.black, size: 30), style: IconButton.styleFrom(fixedSize: Size(80, 80), backgroundColor: Color(0xFF98AC84)),),
              ],
            )
          ],
        ),
      ),
    );
  }
  Widget _buildBottomButton(IconData icon, String label){
    return Column(
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
        itemExtent: 80,
        physics: FixedExtentScrollPhysics(),
        perspective: 0.005,
        diameterRatio: 2.0,
        onSelectedItemChanged: onChanged,
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
}
