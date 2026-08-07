import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Text('ManaPrice BR', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Consulte, calcule e venda suas cartas mais rápido.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
            const SizedBox(height: 28),
            _ActionCard(icon: Icons.search_rounded, title: 'Pesquisar carta', subtitle: 'Digite o nome e consulte o preço.', onTap: () => context.push('/search')),
            const SizedBox(height: 14),
            _ActionCard(icon: Icons.photo_camera_rounded, title: 'Escanear carta', subtitle: 'Tire uma foto e reconheça o nome.', onTap: () => context.push('/scanner')),
            const SizedBox(height: 14),
            _ActionCard(icon: Icons.playlist_add_check_rounded, title: 'Consulta em lote', subtitle: 'Consulte várias cartas de uma vez.', onTap: () => context.push('/batch')),
            const SizedBox(height: 14),
            _ActionCard(icon: Icons.history_rounded, title: 'Histórico', subtitle: 'Veja suas últimas consultas.', onTap: () {}),
            const SizedBox(height: 14),
            _ActionCard(icon: Icons.settings_rounded, title: 'Configurações', subtitle: 'Defina desconto, condição e preferências.', onTap: () => context.push('/settings')),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ])),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
