import 'package:flutter/material.dart';

class LifeCounterPage extends StatefulWidget {
  const LifeCounterPage({super.key});
  @override State<LifeCounterPage> createState()=>_LifeCounterPageState();
}

class _LifeCounterPageState extends State<LifeCounterPage>{
  int _players=4; int _startingLife=40; late List<int> _life; late List<int> _poison;
  @override void initState(){super.initState();_reset();}
  void _reset(){_life=List.filled(_players,_startingLife);_poison=List.filled(_players,0);if(mounted)setState((){});}
  void _setPlayers(int value){setState((){_players=value;_life=List.filled(value,_startingLife);_poison=List.filled(value,0);});}
  void _lifeChange(int i,int delta)=>setState(()=>_life[i]+=delta);
  void _poisonChange(int i,int delta)=>setState(()=>_poison[i]=(_poison[i]+delta).clamp(0,99));

  @override Widget build(BuildContext context){final theme=Theme.of(context);return Scaffold(appBar:AppBar(title:const Text('Contador de vida'),actions:[IconButton(tooltip:'Reiniciar partida',onPressed:_confirmReset,icon:const Icon(Icons.restart_alt_rounded))]),body:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,8,16,10),child:Row(children:[Expanded(child:DropdownButtonFormField<int>(initialValue:_players,decoration:const InputDecoration(labelText:'Jogadores'),items:List.generate(7,(i)=>i+2).map((n)=>DropdownMenuItem(value:n,child:Text('$n jogadores'))).toList(),onChanged:(v){if(v!=null)_setPlayers(v);})),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<int>(initialValue:_startingLife,decoration:const InputDecoration(labelText:'Vida inicial'),items:const[20,25,30,40].map((n)=>DropdownMenuItem(value:n,child:Text('$n vidas'))).toList(),onChanged:(v){if(v!=null){_startingLife=v;_reset();}}))])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Text('Toque nos lados − / + para ajustar a vida. Poison fica sempre visível.',style:theme.textTheme.bodySmall?.copyWith(color:theme.colorScheme.onSurfaceVariant))),const SizedBox(height:10),
    Expanded(child:LayoutBuilder(builder:(context,c){final cols=_players<=4?2:(_players<=6?2:2);return GridView.builder(padding:const EdgeInsets.fromLTRB(10,0,10,16),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,childAspectRatio:_players<=4?1.12:(_players<=6?1.35:1.65),crossAxisSpacing:8,mainAxisSpacing:8),itemCount:_players,itemBuilder:(context,i)=>_PlayerTile(index:i,life:_life[i],poison:_poison[i],onMinus:()=>_lifeChange(i,-1),onPlus:()=>_lifeChange(i,1),onPoisonMinus:()=>_poisonChange(i,-1),onPoisonPlus:()=>_poisonChange(i,1));}))
  ]));}

  Future<void> _confirmReset() async {final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Reiniciar partida?'),content:Text('Todos voltarão para $_startingLife vidas e 0 poison.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Reiniciar'))]));if(ok==true)_reset();}
}

class _PlayerTile extends StatelessWidget{
  const _PlayerTile({required this.index,required this.life,required this.poison,required this.onMinus,required this.onPlus,required this.onPoisonMinus,required this.onPoisonPlus});
  final int index,life,poison; final VoidCallback onMinus,onPlus,onPoisonMinus,onPoisonPlus;
  @override Widget build(BuildContext context){final theme=Theme.of(context);final palette=[theme.colorScheme.primaryContainer,theme.colorScheme.secondaryContainer,theme.colorScheme.tertiaryContainer,theme.colorScheme.surfaceContainerHighest];final bg=palette[index%palette.length];return Card(color:bg,clipBehavior:Clip.antiAlias,child:Column(children:[Padding(padding:const EdgeInsets.fromLTRB(12,8,12,0),child:Row(children:[Expanded(child:Text('Jogador ${index+1}',style:const TextStyle(fontWeight:FontWeight.w800))),Icon(Icons.favorite_rounded,size:16,color:theme.colorScheme.primary),const SizedBox(width:4),Text('$life',style:const TextStyle(fontWeight:FontWeight.w700))])),Expanded(child:Row(children:[Expanded(child:InkWell(onTap:onMinus,child:const Center(child:Icon(Icons.remove_rounded,size:34)))),Expanded(flex:2,child:FittedBox(fit:BoxFit.scaleDown,child:Text('$life',style:const TextStyle(fontSize:72,fontWeight:FontWeight.w900,height:1)))),Expanded(child:InkWell(onTap:onPlus,child:const Center(child:Icon(Icons.add_rounded,size:34))))])),Padding(padding:const EdgeInsets.fromLTRB(8,0,8,8),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton.visualDensity(onPressed:onPoisonMinus,icon:const Icon(Icons.remove_circle_outline_rounded,size:18)),const Icon(Icons.coronavirus_outlined,size:18),Text(' Poison $poison',style:const TextStyle(fontWeight:FontWeight.w700)),IconButton.visualDensity(onPressed:onPoisonPlus,icon:const Icon(Icons.add_circle_outline_rounded,size:18))]))]));}
}
