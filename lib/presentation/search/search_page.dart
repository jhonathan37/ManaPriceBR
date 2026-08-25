import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog/live_card_catalog.dart';
import '../../data/local/app_settings_store.dart';
import '../../domain/entities/card_printing.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialName, this.initialCollectorNumber});
  final String? initialName;
  final String? initialCollectorNumber;
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  final LiveCardCatalog _catalog = LiveCardCatalog();
  Timer? _debounce;
  List<String> _suggestions = const [];
  List<CardPrinting> _printings = const [];
  CardPrinting? _selectedPrinting;
  String? _resolvedImageUrl;
  String? _catalogNotice;
  bool _loadingSuggestions = false, _loadingPrintings = false, _foil = false, _loadingDefaults = true;
  String _condition = 'NM';
  String _language = 'Português';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final settings = await AppSettingsStore.load();
    if (!mounted) return;
    setState(() {
      _condition = settings.condition;
      _foil = settings.foil;
      _language = settings.language;
      _loadingDefaults = false;
    });
    if ((widget.initialName ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPrintings(widget.initialName!.trim());
      });
    }
  }

  @override void dispose(){_debounce?.cancel();_controller.dispose();super.dispose();}

  void _onChanged(String value){
    _debounce?.cancel();
    final query=value.trim();
    setState((){_selectedPrinting=null;_printings=const[];_resolvedImageUrl=null;_catalogNotice=null;});
    if(query.length<2){setState((){_suggestions=const[];_loadingSuggestions=false;});return;}
    _debounce=Timer(const Duration(milliseconds:350),()async{
      if(!mounted)return;
      setState(()=>_loadingSuggestions=true);
      try{
        final items=await _catalog.autocomplete(query);
        if(!mounted||_controller.text.trim()!=query)return;
        setState((){_suggestions=items;_loadingSuggestions=false;_catalogNotice=null;});
      }catch(_){
        if(mounted)setState((){
          _suggestions=const[];
          _loadingSuggestions=false;
          _catalogNotice='Não consegui carregar sugestões agora. Verifique sua internet ou continue digitando o nome completo.';
        });
      }
    });
  }

  Future<void> _loadPrintings(String name) async {
    setState((){_loadingPrintings=true;_selectedPrinting=null;_printings=const[];_resolvedImageUrl=null;_catalogNotice=null;});
    try{
      final resolved=await _catalog.find(name);
      final items=await _catalog.printings(resolved?.name??name);
      if(!mounted||_controller.text.trim()!=name)return;
      CardPrinting? hinted;
      final collector=widget.initialCollectorNumber?.trim().toLowerCase();
      if(collector!=null&&collector.isNotEmpty){
        final matches=items.where((p)=>p.collectorNumber.trim().toLowerCase()==collector).toList();
        if(matches.length==1)hinted=matches.first;
      }
      setState((){
        _printings=items;
        _selectedPrinting=hinted;
        _resolvedImageUrl=hinted?.imageUrl??resolved?.imageUrl??(items.isNotEmpty?items.first.imageUrl:null);
        _loadingPrintings=false;
        _catalogNotice=items.isEmpty?'Não encontrei edições para esse nome. Confira a escrita ou tente o nome em inglês.':null;
      });
    }catch(_){
      if(mounted)setState((){
        _loadingPrintings=false;
        _catalogNotice='Não consegui consultar as edições agora. Pode ser falta de internet ou indisponibilidade temporária do catálogo.';
      });
    }
  }

  void _selectSuggestion(String name){_controller.text=name;_controller.selection=TextSelection.collapsed(offset:name.length);setState(()=>_suggestions=const[]);_loadPrintings(name);}
  Future<void> _ensurePrintings() async {final name=_controller.text.trim();if(name.isEmpty||_printings.isNotEmpty||_loadingPrintings)return;await _loadPrintings(name);}
  Future<void> _search() async {
    final name=_controller.text.trim();
    if(name.isEmpty){_notice('Digite o nome da carta que você quer consultar.');return;}
    await _ensurePrintings();
    if(!mounted)return;
    if(_printings.isEmpty){_notice('Ainda não consegui confirmar a edição. Tente novamente com internet ativa ou revise o nome da carta.');return;}
    if(_selectedPrinting==null){_notice('Só falta escolher a edição. Assim o preço não vem de uma impressão diferente.');return;}
    FocusScope.of(context).unfocus();
    setState(()=>_suggestions=const[]);
    final p=_selectedPrinting;
    context.push('/result',extra:{'name':name,'setCode':p?.setCode,'setName':p?.setName,'collectorNumber':p?.collectorNumber,'imageUrl':p?.imageUrl??_resolvedImageUrl,'condition':_condition,'foil':_foil,'language':_language});
  }
  void _notice(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));

  @override Widget build(BuildContext context){
    final theme=Theme.of(context);
    return Scaffold(
      appBar:AppBar(title:const Text('Buscar carta')),
      body:_loadingDefaults?const Center(child:CircularProgressIndicator()):ListView(
        padding:const EdgeInsets.fromLTRB(20,12,20,32),
        children:[
          Text('Qual carta você procura?',style:theme.textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:6),
          Text('Pode escrever em português ou inglês. Depois você escolhe a edição para receber o preço certo.',style:theme.textTheme.bodyLarge?.copyWith(color:theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height:20),
          TextField(controller:_controller,autofocus:widget.initialName?.isEmpty??true,textInputAction:TextInputAction.search,onChanged:_onChanged,onSubmitted:(_)=>_ensurePrintings(),decoration:InputDecoration(labelText:'Nome da carta',hintText:'Ex.: Testemunha Eterna ou Eternal Witness',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:_controller.text.isEmpty?null:IconButton(tooltip:'Limpar',onPressed:(){_controller.clear();setState((){_suggestions=const[];_printings=const[];_selectedPrinting=null;_resolvedImageUrl=null;_catalogNotice=null;});},icon:const Icon(Icons.close_rounded)))),
          if(_loadingSuggestions)...[const SizedBox(height:8),const LinearProgressIndicator()],
          if(_catalogNotice!=null)...[
            const SizedBox(height:10),
            Container(
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:theme.colorScheme.surfaceContainerHigh,borderRadius:BorderRadius.circular(14)),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.info_outline_rounded,color:theme.colorScheme.primary),const SizedBox(width:10),Expanded(child:Text(_catalogNotice!,style:theme.textTheme.bodyMedium))]),
            ),
          ],
          if(_suggestions.isNotEmpty)...[const SizedBox(height:8),Card(clipBehavior:Clip.antiAlias,child:Column(children:_suggestions.map((name)=>ListTile(leading:Icon(Icons.style_rounded,color:theme.colorScheme.primary),title:Text(name,style:const TextStyle(fontWeight:FontWeight.w600)),trailing:const Icon(Icons.north_west_rounded,size:18),onTap:()=>_selectSuggestion(name))).toList()))],
          const SizedBox(height:24),
          _StepTitle(number:'1',title:'Confirme a edição',subtitle:_selectedPrinting!=null&&widget.initialCollectorNumber!=null?'O scanner sugeriu esta edição. Confira antes de continuar.':'Cada edição pode ter um preço diferente.'),
          const SizedBox(height:12),
          if(_loadingPrintings) const LinearProgressIndicator() else if(_printings.isNotEmpty) DropdownButtonFormField<CardPrinting>(initialValue:_selectedPrinting,isExpanded:true,decoration:const InputDecoration(labelText:'Edição da carta',prefixIcon:Icon(Icons.layers_rounded)),items:_printings.map((p)=>DropdownMenuItem(value:p,child:Text(p.label,overflow:TextOverflow.ellipsis))).toList(),onChanged:(value)=>setState(()=>_selectedPrinting=value)) else OutlinedButton.icon(onPressed:_ensurePrintings,icon:const Icon(Icons.layers_outlined),label:const Text('Encontrar edições desta carta')),
          const SizedBox(height:22),
          _StepTitle(number:'2',title:'Ajuste a carta',subtitle:'Os valores abaixo usam suas preferências salvas.'),
          const SizedBox(height:10),
          Card(child:ExpansionTile(title:const Text('Idioma, condição e acabamento',style:TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('$_language • $_condition • ${_foil?'Foil':'Não foil'}'),childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),children:[DropdownButtonFormField<String>(initialValue:_language,decoration:const InputDecoration(labelText:'Idioma'),items:const['Português','Inglês','Espanhol'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setState(()=>_language=v);}),const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:_condition,decoration:const InputDecoration(labelText:'Condição'),items:const['NM','SP','MP','HP','DMG'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setState(()=>_condition=v);}),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Carta foil'),subtitle:const Text('Ative somente se a impressão for foil.'),value:_foil,onChanged:(v)=>setState(()=>_foil=v))])),
          const SizedBox(height:24),
          SizedBox(height:54,child:FilledButton.icon(onPressed:_search,icon:const Icon(Icons.price_check_rounded),label:Text(_selectedPrinting==null?'Escolha a edição para continuar':'Ver preço desta edição'))),
          const SizedBox(height:10),
          TextButton.icon(onPressed:()=>context.push('/effect-search'),icon:const Icon(Icons.auto_awesome_rounded),label:const Text('Não sabe o nome? Descreva o que a carta faz')),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget{
  const _StepTitle({required this.number,required this.title,required this.subtitle});
  final String number,title,subtitle;
  @override Widget build(BuildContext context){
    final theme=Theme.of(context);
    return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:32,height:32,alignment:Alignment.center,decoration:BoxDecoration(color:theme.colorScheme.primaryContainer,shape:BoxShape.circle),child:Text(number,style:TextStyle(fontWeight:FontWeight.w800,color:theme.colorScheme.primary))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:theme.textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(subtitle,style:theme.textTheme.bodySmall?.copyWith(color:theme.colorScheme.onSurfaceVariant))]))]);
  }
}
