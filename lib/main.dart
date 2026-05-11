import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SleepTimerApp());
}

class SleepTimerApp extends StatelessWidget {
  const SleepTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Timer YT Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0000),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _channel = MethodChannel('sleep_timer/native');

  static const List<int> _presets = [10, 15, 20, 30, 45, 60, 90, 120];

  int _selectedMinutes = 30;
  Timer? _ticker;
  DateTime? _endsAt;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _running => _endsAt != null;

  Future<void> _start() async {
    final minutes = _selectedMinutes;
    if (minutes <= 0) return;

    try {
      await _channel.invokeMethod('openYouTubeMusic');
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não consegui abrir o YT Music: ${e.message}')),
      );
    }

    setState(() {
      _endsAt = DateTime.now().add(Duration(minutes: minutes));
      _remaining = Duration(minutes: minutes);
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final now = DateTime.now();
    if (!now.isBefore(endsAt)) {
      _fire();
      return;
    }
    setState(() => _remaining = endsAt.difference(now));
  }

  Future<void> _fire() async {
    _ticker?.cancel();
    setState(() {
      _ticker = null;
      _endsAt = null;
      _remaining = Duration.zero;
    });
    try {
      await _channel.invokeMethod('pauseMedia');
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao pausar: ${e.message}')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Boa noite. YT Music pausado.')),
    );
  }

  void _cancel() {
    _ticker?.cancel();
    setState(() {
      _ticker = null;
      _endsAt = null;
      _remaining = Duration.zero;
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Timer · YT Music'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                _running ? 'Pausando em' : 'Escolha o tempo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _running ? _fmt(_remaining) : '$_selectedMinutes min',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_running) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _presets.map((m) {
                    final selected = m == _selectedMinutes;
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedMinutes = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickCustom,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Tempo personalizado'),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _running ? _cancel : _start,
                  icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _running ? 'Cancelar' : 'Iniciar e abrir YT Music',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mantenha o app aberto em segundo plano. '
                'Ao zerar, o YT Music será pausado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustom() async {
    final controller = TextEditingController(text: '$_selectedMinutes');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minutos'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'min'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _selectedMinutes = result);
  }
}
