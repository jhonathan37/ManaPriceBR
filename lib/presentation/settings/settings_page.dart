import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double discount = 15;
  String language = 'Português';
  String condition = 'NM';
  bool foil = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            initialValue: language,
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
            initialValue: condition,
            decoration: const InputDecoration(labelText: 'Condição padrão'),
            items: const ['NM', 'SP', 'MP', 'HP']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => condition = value ?? condition),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foil por padrão'),
            value: foil,
            onChanged: (value) => setState(() => foil = value),
          ),
        ],
      ),
    );
  }
}
