import 'dart:async';
import 'package:flutter/material.dart';

class RpeOption {
  final String emoji;
  final String label;
  final String description;
  final String rpeText;
  final double value;
  final bool isWarning;

  const RpeOption({
    required this.emoji,
    required this.label,
    required this.description,
    required this.rpeText,
    required this.value,
    this.isWarning = false,
  });
}

const List<RpeOption> rpeOptions = [
  RpeOption(
      emoji: '😊',
      label: 'Легко',
      description: 'Могу говорить свободно',
      rpeText: 'RPE 4',
      value: 4),
  RpeOption(
      emoji: '🙂',
      label: 'Норм',
      description: 'Свободная речь',
      rpeText: 'RPE 6',
      value: 6),
  RpeOption(
      emoji: '😤',
      label: 'Тяжело',
      description: 'Только короткие фразы',
      rpeText: 'RPE 7–8',
      value: 7.5),
  RpeOption(
      emoji: '🥵',
      label: 'На пределе',
      description: 'Только отдельные слова',
      rpeText: 'RPE 9',
      value: 9),
  RpeOption(
      emoji: '⛔',
      label: 'Не могу',
      description: 'Не могу говорить',
      rpeText: 'RPE 10',
      value: 10,
      isWarning: true),
];

const int rpeAutoSkipSeconds = 5;

Future<double?> showRpeDialog(
    BuildContext context, {
      required int circuitNumber,
      required int totalCircuits,
    }) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    builder: (context) => _RpeDialogContent(
      circuitNumber: circuitNumber,
      totalCircuits: totalCircuits,
    ),
  );
}

class _RpeDialogContent extends StatefulWidget {
  final int circuitNumber;
  final int totalCircuits;

  const _RpeDialogContent({
    required this.circuitNumber,
    required this.totalCircuits,
  });

  @override
  State<_RpeDialogContent> createState() => _RpeDialogContentState();
}

class _RpeDialogContentState extends State<_RpeDialogContent> {
  Timer? _timer;
  int _secondsLeft = rpeAutoSkipSeconds;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        _finish(null);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(double? value) {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    Navigator.pop(context, value);
  }

  Future<void> _selectOption(RpeOption option) async {
    _timer?.cancel();
    if (option.isWarning) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text('Обрати внимание',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Рекомендуем снизить темп или сделать более долгий отдых. '
                'Это не медицинская рекомендация — при плохом самочувствии '
                'остановите тренировку.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) return;
    }
    _finish(option.value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Как прошёл круг?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('круг ${widget.circuitNumber} из ${widget.totalCircuits}',
                  style: const TextStyle(
                      color: Color(0xFF8A8A86),
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 28),
              ...rpeOptions.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RpeButton(
                  option: option,
                  onTap: () => _selectOption(option),
                ),
              )),
              const SizedBox(height: 12),
              Text('автопереход через $_secondsLeft…',
                  style: const TextStyle(
                      color: Color(0xFF5A5A56), fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RpeButton extends StatelessWidget {
  final RpeOption option;
  final VoidCallback onTap;

  const _RpeButton({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: option.isWarning
              ? const Color(0xFF2A1616)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: option.isWarning
              ? Border.all(color: const Color(0xFF5A2A2A))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(option.description,
                        style: TextStyle(
                            color: option.isWarning
                                ? const Color(0xFFC98A8A)
                                : const Color(0xFF8A8A86),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
            Text(option.rpeText,
                style: TextStyle(
                    color: option.isWarning
                        ? const Color(0xFFC98A8A)
                        : const Color(0xFF8A8A86),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}