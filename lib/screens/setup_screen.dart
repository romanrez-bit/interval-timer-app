import 'package:flutter/material.dart';
import '../models/saved_timer.dart';
import '../services/database_service.dart';
import 'active_timer_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _nameController = TextEditingController(text: 'Круговая тренировка');
  final _prepController = TextEditingController(text: '10');
  final _workController = TextEditingController(text: '40');
  final _restController = TextEditingController(text: '20');
  final _circuitsController = TextEditingController(text: '8');

  List<SavedTimer> _savedTimers = [];

  static const _colorPrep = Color(0xFFD4A017);
  static const _colorWork = Color(0xFFE3620F);
  static const _colorRest = Color(0xFFD4A017);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  @override
  void initState() {
    super.initState();
    _loadSavedTimers();
  }

  Future<void> _loadSavedTimers() async {
    final timers = await DatabaseService.instance.getSavedTimers();
    setState(() => _savedTimers = timers);
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

  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTimerScreen(
          prepSeconds: int.tryParse(_prepController.text) ?? 10,
          workSeconds: int.tryParse(_workController.text) ?? 40,
          restSeconds: int.tryParse(_restController.text) ?? 20,
          numCircuits: int.tryParse(_circuitsController.text) ?? 8,
        ),
      ),
    );
  }

  void _loadTemplate(SavedTimer timer) {
    setState(() {
      _nameController.text = timer.name;
      _prepController.text = timer.prepSeconds.toString();
      _workController.text = timer.workSeconds.toString();
      _restController.text = timer.restSeconds.toString();
      _circuitsController.text = timer.numCircuits.toString();
    });
  }

  Future<void> _deleteTemplate(SavedTimer timer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Удалить шаблон "${timer.name}"?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
              const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && timer.id != null) {
      await DatabaseService.instance.deleteSavedTimer(timer.id!);
      _loadSavedTimers();
    }
  }

  Future<void> _saveCurrentAsTemplate() async {
    final timer = SavedTimer(
      name: _nameController.text.isEmpty
          ? 'Без названия'
          : _nameController.text,
      prepSeconds: int.tryParse(_prepController.text) ?? 10,
      workSeconds: int.tryParse(_workController.text) ?? 40,
      restSeconds: int.tryParse(_restController.text) ?? 20,
      numCircuits: int.tryParse(_circuitsController.text) ?? 8,
    );
    await DatabaseService.instance.insertSavedTimer(timer);
    _loadSavedTimers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Шаблон сохранён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
              _nameField(),
              const SizedBox(height: 16),
              _startButton(),
              const SizedBox(height: 20),
              const Text('шаблоны',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_savedTimers.isEmpty) {
                      return Center(
                        child: Text('нет сохранённых шаблонов',
                            style: TextStyle(color: _muted, fontSize: 13)),
                      );
                    }
                    final itemExtent = constraints.maxHeight / 3;
                    return ListView.builder(
                      itemExtent: itemExtent,
                      itemCount: _savedTimers.length,
                      itemBuilder: (context, index) =>
                          _templateCard(_savedTimers[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _addTemplateCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(
      String label, TextEditingController controller, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return Container(
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startWorkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorWork,
          padding: const EdgeInsets.symmetric(vertical: 30),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('старт',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _templateCard(SavedTimer timer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _loadTemplate(timer),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timer.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                      '${timer.workSeconds}/${timer.restSeconds} · ${timer.numCircuits} кругов',
                      style: const TextStyle(color: _muted, fontSize: 13)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: _muted, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {}, // TODO: экран/диалог редактирования шаблона
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: _muted, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _deleteTemplate(timer),
          ),
        ],
      ),
    );
  }

  Widget _addTemplateCard() {
    return GestureDetector(
      onTap: _saveCurrentAsTemplate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: _muted, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: _colorWork, size: 18),
            SizedBox(width: 8),
            Text('добавить шаблон',
                style: TextStyle(
                    color: _colorWork,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}