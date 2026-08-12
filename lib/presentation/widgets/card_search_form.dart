import 'package:flutter/material.dart';

class CardSearchForm extends StatelessWidget {
  const CardSearchForm({
    super.key,
    required this.nameController,
    required this.language,
    required this.condition,
    required this.foil,
    required this.onLanguageChanged,
    required this.onConditionChanged,
    required this.onFoilChanged,
    required this.onSearch,
    this.loading = false,
  });

  final TextEditingController nameController;
  final String language;
  final String condition;
  final bool foil;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<bool> onFoilChanged;
  final VoidCallback onSearch;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: const InputDecoration(
            labelText: 'Nome da carta',
            hintText: 'Ex.: The One Ring',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: const InputDecoration(
            labelText: 'Idioma',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Português', child: Text('Português')),
            DropdownMenuItem(value: 'Inglês', child: Text('Inglês')),
          ],
          onChanged: onLanguageChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: condition,
          decoration: const InputDecoration(
            labelText: 'Condição',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'NM', child: Text('NM')),
            DropdownMenuItem(value: 'SP', child: Text('SP')),
            DropdownMenuItem(value: 'MP', child: Text('MP')),
            DropdownMenuItem(value: 'HP', child: Text('HP')),
          ],
          onChanged: onConditionChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Foil'),
          value: foil,
          onChanged: onFoilChanged,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: loading ? null : onSearch,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(loading ? 'Consultando...' : 'CONSULTAR'),
        ),
      ],
    );
  }
}
