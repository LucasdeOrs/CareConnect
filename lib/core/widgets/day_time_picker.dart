import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DayTimePicker extends StatefulWidget {
  final String day;
  final List<String> initialTimes;
  final Function(List<String>) onTimesChanged;

  const DayTimePicker({
    super.key,
    required this.day,
    required this.initialTimes,
    required this.onTimesChanged,
  });

  @override
  State<DayTimePicker> createState() => _DayTimePickerState();
}

class _DayTimePickerState extends State<DayTimePicker> {
  final List<String> _times = [];
  final TextEditingController _timeInputController = TextEditingController();
  final TimeRangeFormatter _timeRangeFormatter = TimeRangeFormatter();

  @override
  void initState() {
    super.initState();
    _times.addAll(widget.initialTimes);
  }

  void _addTime(String timeRange) {
    final cleanTime = timeRange.trim();
    final RegExp timeRegex = RegExp(r'^\d{2}:\d{2}\s-\s\d{2}:\d{2}$');

    if (timeRegex.hasMatch(cleanTime) && !_times.contains(cleanTime)) {
      setState(() {
        _times.add(cleanTime);
        _times.sort();
        widget.onTimesChanged(_times);
      });
      _timeInputController.clear();
    } else if (cleanTime.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato de horário inválido. Use HH:MM - HH:MM.'),
        ),
      );
    }
  }

  void _removeTime(String time) {
    setState(() {
      _times.remove(time);
      widget.onTimesChanged(_times);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  widget.day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  controller: _timeInputController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(13),
                    _timeRangeFormatter,
                  ],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '08:00 - 12:00',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _addTime(_timeInputController.text),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: _addTime,
                ),
              ),
            ],
          ),

          if (_times.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _times.map((time) {
                  return Chip(
                    label: Text(time, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => _removeTime(time),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(0),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
