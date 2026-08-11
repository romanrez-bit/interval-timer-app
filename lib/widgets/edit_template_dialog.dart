import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_timer.dart';

Future<SavedTimer?> showEditTemplateDialog(
    BuildContext context, {
      required SavedTimer timer,
    }) {
  return showDialog<SavedTimer>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => _EditTemplateDialogContent(timer: timer),
  );
}

class _EditTemplateDialogContent extends StatefulWidget {
  final SavedTimer timer;

  const _EditTemplateDialogContent({required this.timer});

  @override
  State<_EditTemplateDialogContent> createState() =>
      _EditTemplateDialogContentState();
}

class _EditTemplateDialogContentState
    extends State<_EditTemplateDialogContent> {
  static const _colorPrep = Color(0xFFD4A017);
  static const _colorWork = Color(0xFFE3620F);
  static const _colorRest = Color(0xFFD4A017);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  late final TextEditingController _nameController;
  late final TextEditingController _prepController;
  late final TextEditingController _workController;
  late final TextEditingController _restController;
  late final TextEditingController _circuitsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.timer.name);
    _prepController =
        TextEditingController(text: widget.timer.prepSeconds.toString());
    _workController =
        TextEditingController(text: widget.timer.workSeconds.toString());
    _restController =
        TextEditingController(text: widget.timer.restSeconds.toString());
    _circuitsController =
        TextEditingController(text: widget.timer.numCircuits.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prepController.dispose();
    _workController.dispose();
    _restController.dispose();
    _circuitsController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = SavedTimer(
      id: widget.timer.id,
      name: _nameController.text.isEmpty
          ? 'Без названия'
          : _nameController.text,
      prepSeconds:
      int.tryParse(_prepController.text) ?? widget.timer.prepSeconds,
      workSeconds:
      int.tryParse(_workController.text) ?? widget.timer.workSeconds,
      restSeconds:
      int.tryParse(_restController.text) ?? widget.timer.restSeconds,
      numCircuits:
      int.tryParse(_circuitsController.text) ?? widget.timer.numCircuits,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Редактировать шаблон',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                  color: _cardBg, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _numberField(
                      'подготовка, сек', _prepController, _colorPrep)),
              const SizedBox(width: 10),
              Expanded(
                  child: _numberField(
                      'работа, сек', _workController, _colorWork)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _numberField(
                      'отдых, сек', _restController, _colorRest)),
              const SizedBox(width: 10),
              Expanded(
                  child: _numberField(
                      'кругов', _circuitsController, Colors.white)),
            ]),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF4A4A46), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('отмена',
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorWork,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('сохранить',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
      String label, TextEditingController controller, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
      TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}