import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/local/life_session_store.dart';

class LifeCounterPage extends StatefulWidget {
  const LifeCounterPage({super.key});

  @override
  State<LifeCounterPage> createState() => _LifeCounterPageState();
}

class _LifeCounterPageState extends State<LifeCounterPage>
    with WidgetsBindingObserver {
  final LifeSessionStore _store = LifeSessionStore();
  final List<_Undo> _history = [];

  int _count = 4;
  int _start = 40;
  int _seconds = 0;
  int? _monarch;
  int? _initiative;
  late List<_P> _players;
  Timer? _timer;
  bool _running = false;
  bool _compactSetup = false;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetState();
    unawaited(_restore());
  }

  @override
  void dispose() {
    unawaited(_persist());
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persist());
    }
  }

  void _resetState() {
    _players = List.generate(
      _count,
      (i) => _P('Jogador ${i + 1}', _start, _count),
    );
    _monarch = null;
    _initiative = null;
    _history.clear();
    _seconds = 0;
    _running = false;
    _timer?.cancel();
  }

  Future<void> _restore() async {
    try {
      final state = await _store.load();
      if (!mounted) return;
      if (state == null) {
        setState(() => _restoring = false);
        return;
      }

      final rawPlayers = state['players'];
      if (rawPlayers is! List || rawPlayers.length < 2 || rawPlayers.length > 8) {
        setState(() => _restoring = false);
        return;
      }

      final restoredCount = (state['count'] as num?)?.toInt() ?? rawPlayers.length;
      final restoredStart = (state['start'] as num?)?.toInt() ?? 40;
      final restoredPlayers = rawPlayers
          .map((raw) => _P.fromMap(Map<String, dynamic>.from(raw as Map), restoredCount))
          .toList();

      setState(() {
        _count = restoredPlayers.length;
        _start = restoredStart;
        _seconds = (state['seconds'] as num?)?.toInt() ?? 0;
        _monarch = _validPlayerIndex(state['monarch']);
        _initiative = _validPlayerIndex(state['initiative']);
        _compactSetup = state['compactSetup'] == true;
        _players = restoredPlayers;
        _running = false;
        _restoring = false;
        _history.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _restoring = false);
    }
  }

  int? _validPlayerIndex(dynamic value) {
    final index = value is num ? value.toInt() : null;
    if (index == null || index < 0 || index >= _count) return null;
    return index;
  }

  Future<void> _persist() async {
    if (_restoring) return;
    await _store.save({
      'count': _count,
      'start': _start,
      'seconds': _seconds,
      'monarch': _monarch,
      'initiative': _initiative,
      'compactSetup': _compactSetup,
      'players': _players.map((p) => p.toMap()).toList(),
    });
  }

  void _commit(VoidCallback change) {
    setState(change);
    unawaited(_persist());
  }

  void _saveUndo(int i) {
    _history.add(_Undo(i, _players[i].copy(), _monarch, _initiative));
    if (_history.length > 50) _history.removeAt(0);
  }

  void _changeLife(int i, int delta) => _commit(() {
        _saveUndo(i);
        _players[i].life += delta;
      });

  void _changePoison(int i, int delta) => _commit(() {
        _saveUndo(i);
        _players[i].poison = max(0, _players[i].poison + delta);
      });

  void _changeTax(int i, int delta) => _commit(() {
        _saveUndo(i);
        _players[i].tax = max(0, _players[i].tax + delta);
      });

  void _changeCommander(int victim, int source, int delta) => _commit(() {
        _saveUndo(victim);
        final old = _players[victim].commander[source];
        final next = max(0, old + delta);
        _players[victim].commander[source] = next;
        _players[victim].life -= next - old;
      });

  void _undo() {
    if (_history.isEmpty) return;
    _commit(() {
      final undo = _history.removeLast();
      _players[undo.index] = undo.player;
      _monarch = undo.monarch;
      _initiative = undo.initiative;
    });
  }

  void _setPlayerCount(int count) => _commit(() {
        _count = count;
        _resetState();
      });

  void _setStartingLife(int life) => _commit(() {
        _start = life;
        _resetState();
      });

  void _toggleTimer() {
    setState(() => _running = !_running);
    _timer?.cancel();
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds % 15 == 0) unawaited(_persist());
      });
    } else {
      unawaited(_persist());
    }
  }

  String get _clock =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mesa Commander'),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _toggleTimer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(_clock, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _compactSetup ? 'Mostrar configuração' : 'Modo mesa',
            onPressed: () => _commit(() => _compactSetup = !_compactSetup),
            icon: Icon(_compactSetup ? Icons.tune_rounded : Icons.fullscreen_rounded),
          ),
          IconButton(
            tooltip: 'Desfazer',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Ferramentas',
            onPressed: _tools,
            icon: const Icon(Icons.casino_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_compactSetup)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _count,
                      decoration: const InputDecoration(labelText: 'Jogadores', isDense: true),
                      items: List.generate(7, (i) => i + 2)
                          .map((n) => DropdownMenuItem(value: n, child: Text('$n jogadores')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _setPlayerCount(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _start,
                      decoration: const InputDecoration(labelText: 'Vida inicial', isDense: true),
                      items: const [20, 25, 30, 40]
                          .map((n) => DropdownMenuItem(value: n, child: Text('$n vidas')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _setStartingLife(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (_monarch != null || _initiative != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 7),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_monarch != null)
                    Chip(avatar: const Text('👑'), label: Text('Monarca: ${_players[_monarch!].name}')),
                  if (_initiative != null)
                    Chip(
                      avatar: const Icon(Icons.explore_rounded, size: 17),
                      label: Text('Iniciativa: ${_players[_initiative!].name}'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final landscape = constraints.maxWidth > constraints.maxHeight;
                final cols = _count <= 2 ? 1 : landscape ? min(4, _count) : 2;
                final ratio = landscape
                    ? (_compactSetup ? 1.45 : 1.18)
                    : (_compactSetup ? .88 : .76);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: ratio,
                  ),
                  itemCount: _count,
                  itemBuilder: (context, i) => _playerCard(i, theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerCard(int i, ThemeData theme) {
    final player = _players[i];
    final maxCommander = player.commander.isEmpty ? 0 : player.commander.reduce(max);
    final lethal = player.life <= 0 || player.poison >= 10 || maxCommander >= 21;
    final accents = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      theme.colorScheme.error,
    ];
    final accent = accents[i % accents.length];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: lethal ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: lethal ? theme.colorScheme.error : accent, width: 5)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _rename(i),
                      child: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  if (_monarch == i) const Text('👑 '),
                  if (_initiative == i) Icon(Icons.explore_rounded, size: 17, color: accent),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (v) => _playerMenu(i, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'cmd', child: Text('Commander Damage')),
                      PopupMenuItem(value: 'monarch', child: Text('Tornar Monarca')),
                      PopupMenuItem(value: 'initiative', child: Text('Dar Iniciativa')),
                      PopupMenuItem(value: 'rename', child: Text('Editar nome')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeLife(i, -1),
                      onLongPress: () => _changeLife(i, -5),
                      child: Center(child: Icon(Icons.remove_rounded, size: 42, color: accent)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${player.life}',
                        style: TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                          height: .9,
                          color: lethal ? theme.colorScheme.error : null,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeLife(i, 1),
                      onLongPress: () => _changeLife(i, 5),
                      child: Center(child: Icon(Icons.add_rounded, size: 42, color: accent)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
              child: Wrap(
                spacing: 5,
                runSpacing: 3,
                alignment: WrapAlignment.center,
                children: [
                  _HoldChip(
                    label: '☠ ${player.poison}',
                    tooltip: 'Poison: toque +1 • segure -1',
                    onTap: () => _changePoison(i, 1),
                    onHold: () => _changePoison(i, -1),
                  ),
                  _HoldChip(
                    label: 'Tax ${player.tax}',
                    tooltip: 'Commander Tax: toque +1 • segure -1',
                    onTap: () => _changeTax(i, 1),
                    onHold: () => _changeTax(i, -1),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.shield_outlined, size: 15),
                    label: Text(maxCommander > 0 ? 'CMD $maxCommander/21' : 'CMD'),
                    onPressed: () => _commanderSheet(i),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playerMenu(int i, String value) {
    if (value == 'cmd') _commanderSheet(i);
    if (value == 'rename') _rename(i);
    if (value == 'monarch') _commit(() => _monarch = _monarch == i ? null : i);
    if (value == 'initiative') _commit(() => _initiative = _initiative == i ? null : i);
  }

  Future<void> _commanderSheet(int victim) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commander Damage em ${_players[victim].name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'O dano reduz a vida automaticamente. 21 do mesmo comandante é letal.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              ...List.generate(_count, (source) {
                if (source == victim) return const SizedBox.shrink();
                final value = _players[victim].commander[source];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_players[source].name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: LinearProgressIndicator(value: min(1, value / 21)),
                  leading: CircleAvatar(child: Text('${source + 1}')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          _changeCommander(victim, source, -1);
                          Navigator.pop(context);
                          _commanderSheet(victim);
                        },
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('$value/21', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                        onPressed: () {
                          _changeCommander(victim, source, 1);
                          Navigator.pop(context);
                          _commanderSheet(victim);
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tools() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ferramentas da mesa', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(_running ? Icons.pause_circle : Icons.play_circle),
                title: Text(_running ? 'Pausar cronômetro' : 'Iniciar cronômetro'),
                subtitle: Text('Tempo da partida: $_clock'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleTimer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.casino_rounded),
                title: const Text('Rolar D20'),
                onTap: () {
                  final n = Random().nextInt(20) + 1;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎲 D20: $n')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.paid_rounded),
                title: const Text('Cara ou coroa'),
                onTap: () {
                  final v = Random().nextBool() ? 'Cara' : 'Coroa';
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🪙 $v')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: const Text('Desfazer última alteração'),
                enabled: _history.isNotEmpty,
                onTap: () {
                  Navigator.pop(context);
                  _undo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Nova partida'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmReset();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(int i) async {
    final controller = TextEditingController(text: _players[i].name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome do jogador'),
        content: TextField(controller: controller, autofocus: true, maxLength: 18),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salvar')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty && mounted) {
      _commit(() => _players[i].name = value.trim());
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nova partida?'),
            content: Text(
              'Todos voltarão para $_start vidas. Poison, Commander Damage, Tax, Monarca, Iniciativa e cronômetro serão zerados.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reiniciar')),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) {
      _commit(_resetState);
    }
  }
}

class _HoldChip extends StatelessWidget {
  const _HoldChip({
    required this.label,
    required this.tooltip,
    required this.onTap,
    required this.onHold,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: onHold,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(label),
            ),
          ),
        ),
      );
}

class _P {
  _P(this.name, this.life, int count) : commander = List.filled(count, 0);

  String name;
  int life;
  int poison = 0;
  int tax = 0;
  List<int> commander;

  _P copy() {
    final p = _P(name, life, commander.length)
      ..poison = poison
      ..tax = tax;
    p.commander = List.of(commander);
    return p;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'life': life,
        'poison': poison,
        'tax': tax,
        'commander': commander,
      };

  factory _P.fromMap(Map<String, dynamic> map, int count) {
    final player = _P(
      map['name']?.toString() ?? 'Jogador',
      (map['life'] as num?)?.toInt() ?? 40,
      count,
    )
      ..poison = (map['poison'] as num?)?.toInt() ?? 0
      ..tax = (map['tax'] as num?)?.toInt() ?? 0;

    final rawCommander = map['commander'];
    if (rawCommander is List) {
      player.commander = List.generate(
        count,
        (i) => i < rawCommander.length ? (rawCommander[i] as num?)?.toInt() ?? 0 : 0,
      );
    }
    return player;
  }
}

class _Undo {
  _Undo(this.index, this.player, this.monarch, this.initiative);

  final int index;
  final _P player;
  final int? monarch;
  final int? initiative;
}
