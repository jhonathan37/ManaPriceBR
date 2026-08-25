import 'package:flutter/material.dart';

import '../../data/local/app_settings_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double discount = 20;
  String language = 'Português';
  String condition = 'NM';
  bool foil = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await AppSettingsStore.load();
    if (!mounted) return;
    setState(() {
      discount = settings.discount;
      language = settings.language;
      condition = settings.condition;
      foil = settings.foil;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppSettingsStore.save(AppSettings(
      discount: discount,
      language: language,
      condition: condition,
      foil: foil,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferências salvas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Preferências de cotação', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Esses valores serão usados automaticamente nas novas buscas.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Text('Desconto padrão', style: Theme.of(context).textTheme.titleMedium),
                Text('${discount.toStringAsFixed(0)}%'),
                Slider(
                  value: discount,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: '${discount.toStringAsFixed(0)}%',
                  onChanged: (value) => setState(() => discount = value),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: language,
                  decoration: const InputDecoration(labelText: 'Idioma padrão'),
                  items: const [
                    DropdownMenuItem(value: 'Português', child: Text('Português')),
                    DropdownMenuItem(value: 'Inglês', child: Text('Inglês')),
                    DropdownMenuItem(value: 'Espanhol', child: Text('Espanhol')),
                  ],
                  onChanged: (value) => setState(() => language = value ?? language),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(labelText: 'Condição padrão'),
                  items: const ['NM', 'SP', 'MP', 'HP', 'DMG']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => condition = value ?? condition),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Foil por padrão'),
                  value: foil,
                  onChanged: (value) => setState(() => foil = value),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Salvando…' : 'Salvar preferências'),
                  ),
                ),
              ],
            ),
    );
  }
}
