import 'package:flutter/material.dart';
import 'stitch_design_system.dart';


const _bg = stitchCanvas, _card = stitchSurface, _raised = stitchSurfaceLow, _orange = stitchOrange, _peach = stitchPeach, _text = stitchText, _muted = stitchMuted, _green = stitchGreen;

class FigmaDashboard extends StatelessWidget {
  const FigmaDashboard({super.key, required this.data, required this.onReload, required this.onStart, required this.onNavigate, this.desktop = false, this.personalAccount = false});
  final Future<List<dynamic>> data;
  final Future<void> Function() onReload;
  final VoidCallback onStart;
  final ValueChanged<int> onNavigate;
  final bool desktop;
  final bool personalAccount;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: data,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _orange));
      if (snap.hasError) return _LoadError(message: snap.error.toString(), retry: onReload);
      final d = snap.data ?? const [];
      if (d.length < 4) return _LoadError(message: 'Não foi possível carregar o painel.', retry: onReload);
      final p = _map(d[0]), a = _map(_map(d[0])['athlete']), w = _map(d[1]), m = _map(d[2]);
      final sessions = _maps(d[3]), plans = d.length > 4 ? _maps(d[4]) : <Map<String,dynamic>>[];
      final posts = d.length > 5 ? _maps(_map(d[5])['posts']) : <Map<String,dynamic>>[];
      final name = (a['name'] ?? p['name'] ?? 'Atleta').toString();
      final count = _n(m['totalSessions']).round(), weekCount = _n(w['totalSessions']).round();
      final sec = _n(w['totalVolume']); // API currently returns durationSec in this field.
      final page = _Content(name:name, profile:p, week:w, month:m, sessions:sessions, plan:_today(plans), posts:posts, monthCount:count, weekCount:weekCount, active:sec, distance:_n(w['totalDistance']), onStart:onStart, onCalendar:()=>onNavigate(1), onReload:onReload);
      if (!desktop) return page;
      return Scaffold(backgroundColor:_bg, body:Row(children:[
        SizedBox(width:288, child:ColoredBox(color:stitchSidebar, child:Padding(padding:const EdgeInsets.all(18), child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Row(children:[Icon(Icons.bolt,color:_orange,size:28),SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('WEGYM',style:TextStyle(color:_text,fontSize:20,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),Text('PERFORMANCE OS',style:TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1))])]),
          const SizedBox(height:28), FilledButton.icon(onPressed:()=>onNavigate(2),icon:const Icon(Icons.add),label:const Text('NOVO TREINO'),style:FilledButton.styleFrom(backgroundColor:_orange,foregroundColor:stitchOnPrimaryContainer)),
          Expanded(child:ListView(padding:EdgeInsets.zero,children:[_nav('Visão Geral',Icons.grid_view,0,onNavigate,true),_nav('Treinos',Icons.fitness_center,2,onNavigate,false),_nav('Analytics & Perf',Icons.show_chart,4,onNavigate,false),_nav('Comunidade',Icons.groups,3,onNavigate,false),_nav('Alunos & Personal',Icons.people,7,onNavigate,false),_nav('Agendamentos',Icons.event,5,onNavigate,false),_nav('Nutrição',Icons.restaurant,6,onNavigate,false),_nav('Metas & Desafios',Icons.flag,8,onNavigate,false),_nav('Programas',Icons.view_list,9,onNavigate,false),_nav('Chat',Icons.chat,10,onNavigate,false),_nav('Configurações',Icons.tune,11,onNavigate,false),_nav('Planos PRO',Icons.workspace_premium,12,onNavigate,false),_nav('Medidas',Icons.monitor_weight,13,onNavigate,false)])),
          const Spacer(), const Text('STATUS DA REDE  •  ONLINE',style:TextStyle(color:_green,fontSize:9,fontWeight:FontWeight.w800))
        ])))),
        Expanded(child:Column(children:[
          Container(height:64,padding:const EdgeInsets.symmetric(horizontal:24),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Colors.white10))),child:Row(children:[
            const Icon(Icons.search,color:_muted),const SizedBox(width:10),const Expanded(child:Text('Buscar treinos, exercícios, atletas...',style:TextStyle(color:_muted,fontSize:12))),
            const Icon(Icons.location_on_outlined,color:_peach,size:16),const SizedBox(width:5),const Text('WeGYM Club',style:TextStyle(color:_text,fontSize:11)),const SizedBox(width:18),const Icon(Icons.notifications_none,color:_muted),const SizedBox(width:14),
            Text(name,style:const TextStyle(color:_text,fontWeight:FontWeight.w800,fontSize:12)),const SizedBox(width:9),CircleAvatar(radius:16,backgroundColor:_orange,child:Text(name.isEmpty?'A':name[0].toUpperCase()))
          ])),
          Expanded(child:page)
        ]))
      ]));
    });

  Widget _nav(String label, IconData icon, int index, ValueChanged<int> tap, bool selected) {
    if (index == 7 && !personalAccount) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selected: selected,
          selectedTileColor: stitchSurfaceHigh,
          leading: Icon(
            icon,
            size: 17,
            color: selected ? _peach : _muted,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? _peach : _muted,
            ),
          ),
          onTap: () => tap(index),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.name,required this.profile,required this.week,required this.month,required this.sessions,required this.plan,required this.posts,required this.monthCount,required this.weekCount,required this.active,required this.distance,required this.onStart,required this.onCalendar,required this.onReload});
  final String name; final Map<String,dynamic> profile,week,month; final List<Map<String,dynamic>> sessions,posts; final Map<String,dynamic>? plan; final int monthCount,weekCount; final double active,distance; final VoidCallback onStart,onCalendar; final Future<void> Function() onReload;
  @override Widget build(BuildContext context)=>RefreshIndicator(color:_orange,onRefresh:onReload,child:LayoutBuilder(builder:(context,c){
    final wide=c.maxWidth>=920, cols=c.maxWidth>=700?4:c.maxWidth>=400?2:1;
    final metricData=<Widget>[
      _metric('TEMPO ATIVO',_duration(active),Icons.timer_outlined,_orange),
      _metric('TREINOS NO MÊS','$monthCount / 22',Icons.calendar_month,_orange),
      _metric('SESSÃO MÉDIA',_duration(weekCount==0?0:active/weekCount),Icons.schedule,stitchBlue),
      _metric('DISTÂNCIA','${distance.toStringAsFixed(1)} KM',Icons.route,_green),
    ];
    final w=(c.maxWidth-(cols-1)*12)/cols;
    return ListView(padding:EdgeInsets.all(wide?24:16),children:[
      Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1280),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if (const bool.fromEnvironment('PREVIEW_DASHBOARD'))
          Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:_orange.withValues(alpha:.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:_orange.withValues(alpha:.35))),child:const Text('PRÉVIA VISUAL • DADOS DE DEMONSTRAÇÃO • Sessões não serão salvas',style:TextStyle(color:_peach,fontSize:10,fontWeight:FontWeight.w800))),
        _hero(name,monthCount,onStart,onCalendar),
        const SizedBox(height:14),
        Wrap(spacing:12,runSpacing:12,children:[for(final x in metricData)SizedBox(width:w,child:x)]),
        const SizedBox(height:16),
        if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(flex:66,child:Column(children:[_workout(plan,onStart),const SizedBox(height:16),_consistency(sessions,weekCount)])),
          const SizedBox(width:16),
          Expanded(flex:34,child:Column(children:[_goal(monthCount,_n(month['totalCalories'])),const SizedBox(height:16),_insight(active,weekCount,_n(week['avgHeartRate']).round()),const SizedBox(height:16),_community(posts,sessions)]))
        ]) else ...[
          _workout(plan,onStart),const SizedBox(height:14),_goal(monthCount,_n(month['totalCalories'])),const SizedBox(height:14),_insight(active,weekCount,_n(week['avgHeartRate']).round()),const SizedBox(height:14),_consistency(sessions,weekCount),const SizedBox(height:14),_community(posts,sessions)
        ]
      ])))
    ]);
  }));

  static Widget _hero(String name,int count,VoidCallback start,VoidCallback calendar){
    final prog=(count/22).clamp(0.0,1.0), remaining=(22-count).clamp(0,22);
    return _box(24,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:8,crossAxisAlignment:WrapCrossAlignment.center,children:[_pill('TEMPORADA 04 • ATIVO',_orange,_peach),Text('• SP CLUBE JARDINS',style:TextStyle(color:_muted,fontSize:9,fontWeight:FontWeight.w800))]),
      const SizedBox(height:10),Text('BEM-VINDO DE VOLTA, ${name.toUpperCase()}!',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_text,fontSize:23,height:1.2,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),
      const SizedBox(height:5),Text('Você completou ${(prog*100).round()}% da meta mensal. Faltam $remaining treinos para sua meta.',style:const TextStyle(color:_muted,fontSize:12)),
      const SizedBox(height:14),LayoutBuilder(builder:(context,c){final compact=c.maxWidth<1024;final progress=Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:prog,minHeight:8,color:_orange,backgroundColor:stitchSurfaceHighest)));final pct=Text('${(prog*100).round()}%',style:const TextStyle(color:_text,fontSize:11,fontWeight:FontWeight.w900));final actions=Wrap(spacing:8,runSpacing:8,children:[
        FilledButton.icon(onPressed:start,icon:const Icon(Icons.play_arrow,size:16),label:const Text('INICIAR SESSÃO DE HOJE'),style:FilledButton.styleFrom(backgroundColor:_orange,foregroundColor:stitchOnPrimaryContainer,textStyle:const TextStyle(fontSize:10,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic))),
        OutlinedButton.icon(onPressed:calendar,icon:const Icon(Icons.calendar_month,size:15),label:const Text('VER HISTÓRICO'),style:OutlinedButton.styleFrom(foregroundColor:_text,side:const BorderSide(color:Colors.white10),textStyle:const TextStyle(fontSize:10,fontWeight:FontWeight.w800)))
      ]);return compact?Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[progress,const SizedBox(width:10),pct]),const SizedBox(height:14),actions]):Row(children:[SizedBox(width:c.maxWidth*.49,child:Row(children:[progress,const SizedBox(width:10),pct])),const Spacer(),actions]);})
    ]),gradient:true);
  }

  static Widget _metric(String label,String value,IconData icon,Color tint)=>_box(16,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(label,style:const TextStyle(color:_muted,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.4))),Icon(icon,color:tint,size:16)]),
    const SizedBox(height:9),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_text,fontSize:22,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),
    const SizedBox(height:6),Text('DADOS ATUALIZADOS',style:TextStyle(color:tint,fontSize:8,fontWeight:FontWeight.w800))
  ]));

  static Widget _workout(Map<String,dynamic>? plan,VoidCallback start){
    final ex=_maps(plan?['exercises']);
    return _box(20,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(width:4,height:30,decoration:BoxDecoration(color:_orange,borderRadius:BorderRadius.circular(5))),const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('HOJE • FOCO HIPERTROFIA',style:TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('TREINO PROGRAMADO',style:TextStyle(color:_text,fontSize:15,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic))])),if(ex.isNotEmpty)Text('${ex.length} exercícios',style:const TextStyle(color:_muted,fontSize:9))]),
      const SizedBox(height:12),
      if(ex.isEmpty)Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:_raised,borderRadius:BorderRadius.circular(12)),child:const Text('Nenhum exercício foi programado para hoje. Inicie uma sessão para registrar seu treino.',style:TextStyle(color:_muted,fontSize:11,height:1.5)))
      else for(var i=0;i<ex.length&&i<6;i++)_exercise(i+1,ex[i]),
      const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:start,icon:const Icon(Icons.play_arrow),label:const Text('COMEÇAR TREINO'),style:FilledButton.styleFrom(backgroundColor:_orange,foregroundColor:stitchOnPrimaryContainer)))
    ]));
  }
  static Widget _exercise(int i,Map<String,dynamic> e)=>Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:_raised,borderRadius:BorderRadius.circular(10)),child:Row(children:[
    CircleAvatar(radius:13,backgroundColor:stitchSidebar,child:Text(i.toString().padLeft(2,'0'),style:const TextStyle(color:_peach,fontSize:8,fontWeight:FontWeight.w900))),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((e['name']??'Exercício').toString(),style:const TextStyle(color:_text,fontSize:11,fontWeight:FontWeight.w800)),Text('${e['sets']??''} séries • ${e['reps']??''} reps • ${e['load']??''}',style:const TextStyle(color:_muted,fontSize:9))])),const Icon(Icons.check_circle_outline,size:16,color:Colors.white38)
  ]));

  static Widget _goal(int count,double kcal){
    final p=(count/22).clamp(0.0,1.0);
    return _box(20,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('META DO MÊS',style:TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.5)),
      const SizedBox(height:14),Center(child:SizedBox(width:150,height:150,child:Stack(alignment:Alignment.center,children:[SizedBox.expand(child:CircularProgressIndicator(value:p,color:_orange,backgroundColor:stitchSurfaceHighest,strokeWidth:11)),Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('${(p*100).round()}%',style:const TextStyle(color:_text,fontSize:32,fontWeight:FontWeight.w900)),const Text('CONCLUÍDO',style:TextStyle(color:_muted,fontSize:8,fontWeight:FontWeight.w900,letterSpacing:1))])]))),
      const SizedBox(height:14),Row(children:[Expanded(child:_mini('CALORIAS','${kcal.round()} kcal',_text)),Expanded(child:_mini('TREINOS','$count / 22',_green))]),const SizedBox(height:8),const Text('Meta de 22 treinos usada como referência visual.',style:TextStyle(color:_muted,fontSize:8))
    ]));
  }
  static Widget _insight(double seconds,int count,int hr)=>_box(18,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Row(children:[Icon(Icons.auto_awesome,color:_orange,size:17),SizedBox(width:8),Text('RESUMO WEGYM',style:TextStyle(color:_text,fontSize:11,fontWeight:FontWeight.w900))]),
    const SizedBox(height:12),Text(count==0?'Registre seu primeiro treino da semana. Seu histórico aparecerá aqui conforme você avança.':'Você acumulou ${_duration(seconds)} em $count sessões nesta semana.',style:const TextStyle(color:_muted,fontSize:10,height:1.5)),
    const SizedBox(height:9),Text(hr>0?'♥  $hr BPM médio':'Frequência cardíaca indisponível',style:const TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w700))
  ]));

  static Widget _consistency(List<Map<String,dynamic>> sessions,int count){
    final trained=<String>{};for(final s in sessions){final date=DateTime.tryParse(s['completedAt']?.toString()??'')?.toLocal();if(date!=null)trained.add(_key(date));}
    final now=DateTime.now();
    return _box(18,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('HISTÓRICO DE CONSISTÊNCIA',style:TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.5)),const SizedBox(height:4),const Text('FREQUÊNCIA RECENTE',style:TextStyle(color:_text,fontSize:14,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),const SizedBox(height:4),Text('Últimos 30 dias • ${trained.length} dias com treinos carregados',style:const TextStyle(color:_muted,fontSize:9)),const SizedBox(height:12),
      Wrap(spacing:5,runSpacing:5,children:List.generate(30,(i){final date=now.subtract(Duration(days:29-i)),done=trained.contains(_key(date)),today=i==29;return Container(width:30,height:23,alignment:Alignment.center,decoration:BoxDecoration(color:today?_green.withValues(alpha:.2):done?_orange:_raised,borderRadius:BorderRadius.circular(5),border:today?Border.all(color:_green):null),child:Text(today?'HOJE':date.day.toString().padLeft(2,'0'),style:TextStyle(color:today?_green:done?stitchOnPrimaryContainer:_muted.withValues(alpha:.6),fontSize:today?6:8,fontWeight:FontWeight.w900)));})),
      const SizedBox(height:10),Text('$count treinos nos últimos 7 dias',style:const TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w800))
    ]));
  }

  static Widget _community(List<Map<String,dynamic>> posts,List<Map<String,dynamic>> sessions){
    final shown=posts.take(3).toList();
    return _box(18,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('ATIVIDADE DA COMUNIDADE',style:TextStyle(color:_peach,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.5)),const SizedBox(height:12),
      if(shown.isEmpty&&sessions.isEmpty)const Text('Sua atividade recente aparecerá aqui.',style:TextStyle(color:_muted,fontSize:10))
      else if(shown.isNotEmpty)for(final post in shown)_post(post)
      else for(final s in sessions.take(3))_session(s),
      const SizedBox(height:6),const Align(alignment:Alignment.centerRight,child:Text('DADOS DO FEED',style:TextStyle(color:_muted,fontSize:8,fontWeight:FontWeight.w800)))
    ]));
  }
  static Widget _post(Map<String,dynamic> p){final u=_map(p['user']),name=(u['displayName']??'Atleta').toString();return Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[CircleAvatar(radius:15,backgroundColor:_raised,child:Text(name.isEmpty?'A':name[0].toUpperCase(),style:const TextStyle(color:_peach,fontSize:10))),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(color:_text,fontWeight:FontWeight.w800,fontSize:9)),Text((p['text']??'Compartilhou uma atualização').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_muted,fontSize:8))]))]));}
  static Widget _session(Map<String,dynamic> s)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Row(children:[const Icon(Icons.fitness_center,color:_orange,size:15),const SizedBox(width:8),Expanded(child:Text((s['modality']??'TREINO').toString().toUpperCase(),style:const TextStyle(color:_text,fontSize:9,fontWeight:FontWeight.w800))),Text(_duration(_n(s['durationSec'])),style:const TextStyle(color:_muted,fontSize:8))]));
  static Widget _mini(String l,String v,Color c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l,style:const TextStyle(color:_muted,fontSize:8,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(v,style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.w900))]);
}

Widget _box(double pad,Widget child,{bool gradient=false})=>Container(width:double.infinity,padding:EdgeInsets.all(pad),decoration:BoxDecoration(color:_card,gradient:gradient?const LinearGradient(colors:[_card,stitchSurfaceHigh]):null,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white.withValues(alpha:.035)),boxShadow:const [BoxShadow(color:Color(0x18000000),blurRadius:10,offset:Offset(0,4))]),child:child);
Widget _pill(String t,Color bg,Color fg)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:bg.withValues(alpha:.18),borderRadius:BorderRadius.circular(20)),child:Text(t,style:TextStyle(color:fg,fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.4)));
Map<String,dynamic> _map(dynamic x){if(x is Map<String,dynamic>)return x;if(x is Map)return x.map((k,v)=>MapEntry(k.toString(),v));return <String,dynamic>{};}
List<Map<String,dynamic>> _maps(dynamic x)=>x is List?x.whereType<Map>().map(_map).toList():<Map<String,dynamic>>[];
double _n(dynamic x)=>x is num?x.toDouble():double.tryParse(x?.toString()??'')??0;
String _duration(double v){final s=v.round().clamp(0,999999999),h=s~/3600,m=(s%3600)~/60;return h>0?'${h}h${m.toString().padLeft(2,'0')}':'$m min';}
String _key(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
Map<String,dynamic>? _today(List<Map<String,dynamic>> plans){const days=['seg','ter','qua','qui','sex','sab','dom'];final today=days[DateTime.now().weekday-1];for(final p in plans){if((p['day']??'').toString().toLowerCase()==today)return p;}return null;}
class _LoadError extends StatelessWidget{const _LoadError({required this.message,required this.retry});final String message;final Future<void> Function() retry;@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_outlined,color:_peach,size:34),const SizedBox(height:12),Text(message,textAlign:TextAlign.center,style:const TextStyle(color:_muted)),const SizedBox(height:12),OutlinedButton.icon(onPressed:retry,icon:const Icon(Icons.refresh),label:const Text('TENTAR NOVAMENTE'))])));}




