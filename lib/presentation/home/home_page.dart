import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.tertiary]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ManaPrice BR', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.5)), Text('Sua carta, sua edição, o preço certo.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant))])),
              IconButton.filledTonal(tooltip: 'Configurações', onPressed: () => context.push('/settings'), icon: const Icon(Icons.tune_rounded)),
            ]),
            const SizedBox(height: 28),
            Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryContainer, colors.secondaryContainer.withValues(alpha: .72)]), borderRadius: BorderRadius.circular(26)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: colors.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(99)), child: const Text('Busca inteligente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))), const SizedBox(height: 16), Text('Encontre a carta mesmo sem lembrar o nome.', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.1)), const SizedBox(height: 10), Text('Descreva o que ela faz e o ManaPriceBR procura as melhores opções para você.', style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)), const SizedBox(height: 18), FilledButton.icon(onPressed: () => context.push('/effect-search'), icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Descrever uma carta'))]),
            const SizedBox(height: 24),
            Text('O que você quer fazer?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: _PrimaryAction(icon: Icons.search_rounded, title: 'Buscar por nome', subtitle: 'Nome, edição e preço', onTap: () => context.push('/search'))), const SizedBox(width: 12), Expanded(child: _PrimaryAction(icon: Icons.center_focus_strong_rounded, title: 'Escanear', subtitle: 'Aponte a câmera', onTap: () => context.push('/scanner')))]),
            const SizedBox(height: 24),
            Text('Na mesa de jogo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _CompactAction(icon: Icons.favorite_rounded, title: 'Contador de vida', subtitle: '2 a 8 jogadores • Commander completo', onTap: () => context.push('/life')),
            const SizedBox(height: 20),
            Text('Mais ferramentas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _CompactAction(icon: Icons.playlist_add_check_rounded, title: 'Consulta em lote', subtitle: 'Consulte várias cartas de uma vez', onTap: () => context.push('/batch')),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant)), child: Row(children: [Icon(Icons.verified_rounded, color: colors.primary), const SizedBox(width: 12), Expanded(child: Text('Preço por edição, condição e acabamento para reduzir erros na cotação.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)))])),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final theme=Theme.of(context), colors=theme.colorScheme; return Material(color: colors.surface, borderRadius: BorderRadius.circular(22), child: InkWell(onTap:onTap, borderRadius:BorderRadius.circular(22), child:Container(constraints:const BoxConstraints(minHeight:154), padding:const EdgeInsets.all(18), decoration:BoxDecoration(borderRadius:BorderRadius.circular(22), border:Border.all(color:colors.outlineVariant)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Container(width:46,height:46,decoration:BoxDecoration(color:colors.primaryContainer,borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:colors.primary)),const Spacer(),Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:4),Text(subtitle,style:theme.textTheme.bodySmall?.copyWith(color:colors.onSurfaceVariant))])))); }
}
class _CompactAction extends StatelessWidget {
  const _CompactAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final colors=Theme.of(context).colorScheme; return Card(margin:EdgeInsets.zero,elevation:0,clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:colors.secondaryContainer,borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:colors.onSecondaryContainer)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:colors.onSurfaceVariant,fontSize:13))])),const Icon(Icons.chevron_right_rounded)])))); }
}
