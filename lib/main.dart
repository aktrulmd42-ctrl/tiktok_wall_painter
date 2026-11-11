
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() => runApp(const WallPainterApp());
class WallPainterApp extends StatelessWidget {
  const WallPainterApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const WallPage());
  }
}
class Bullet { double targetX=0.55; double targetY=0.2; double progress=0; Color color=Colors.pink; }
class WallPage extends StatefulWidget { const WallPage({super.key}); @override State<WallPage> createState()=>_WallPageState(); }
class _WallPageState extends State<WallPage> with SingleTickerProviderStateMixin {
  String currentName='Shah Alam Fan';
  String inputName='';
  List<Bullet> bullets=[];
  List<Bullet> splashes=[];
  double reveal=0;
  bool isVIP=false; // 0 = S placeholder, 1 = full profile photo
  int _shotIndex=0;
  XFile? _profileFile;
  final _picker=ImagePicker();
  late AnimationController anim;
  final rnd=Random();
  List<Color> colors=[Colors.pink, Colors.amber, Colors.cyan, Colors.purple, Colors.orange, Colors.green];
  @override void initState(){
    super.initState();
    anim=AnimationController(vsync:this,duration:const Duration(milliseconds:800))..repeat(reverse:true);
    // LIVE BRIDGE - connect to TikTok Bridge ws://127.0.0.1:8081
    try {
      final ch = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8081'));
      ch.stream.listen((msg) {
        try {
          final d = jsonDecode(msg);
          if (d['type'] == 'viewer_action') {
            final name = (d['name'] ?? 'Viewer').toString();
            final isVip = d['isVIP'] == true;
            final photo = d['photo']?.toString();
            if (!mounted) return;
            setState(() { currentName = name; isVIP = isVip; reveal = 0; _shotIndex = 0; splashes.clear(); });
            // AUTO 15 bullets for this viewer - no button needed
            for (int i = 0; i < 15; i++) { Future.delayed(Duration(milliseconds: i * 140), () { if (mounted) fireOne(); }); }
          }
        } catch (_) {}
      });
    } catch (_) {}
    // NO AUTO - only fire on button / Send as Viewer
  }
  void fireOne(){
    final b=Bullet();
    // TOP TO BOTTOM: 0.14 -> 0.50 step by step
    b.targetY=0.14 + (_shotIndex % 7)*0.06; _shotIndex++;
    b.targetX=0.55 + rnd.nextDouble()*0.15;
    b.color=isVIP?Colors.amber:colors[rnd.nextInt(colors.length)];
    setState(()=>bullets.add(b));
    // bullet flies fast
    Timer.periodic(const Duration(milliseconds:12),(t){
      if(!mounted){t.cancel();return;}
      setState(()=>b.progress+=0.12); // fast
      if(b.progress>=1){
        t.cancel();
        setState((){
          bullets.remove(b);
          splashes.add(b);
          // profile slowly reveals with each hit
          reveal=(reveal+1/15).clamp(0.0,1.0);
        });
        // SPLASH DISAPPEARS after 350ms - gayeb hoye jabe
        Future.delayed(const Duration(milliseconds:350),(){
          if(!mounted) return;
          setState(()=>splashes.remove(b));
        });
      }
    });
  }
  Future<void> pickProfile() async {
    final f=await _picker.pickImage(source:ImageSource.gallery);
    if(f!=null) setState((){
      _profileFile=f;
      reveal=0; _shotIndex=0; splashes.clear(); for(int i=0;i<15;i++){ Future.delayed(Duration(milliseconds:i*140),()=>fireOne()); }
      // restart reveal - new profile will fade in from top to bottom bullets
    });
  }
  @override Widget build(BuildContext context){
    final w=MediaQuery.of(context).size.width;
    final h=MediaQuery.of(context).size.height;
    double gunY=h*0.72;
    return Scaffold(
      backgroundColor:const Color(0xFF0A2A33),
      body: Column(children:[
        Container(color:Colors.red, padding:const EdgeInsets.symmetric(horizontal:12,vertical:10), child: Row(children:[
          const CircleAvatar(radius:22,child:Text('L')),
          const SizedBox(width:8),
          const Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('KTM Artist',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)), Text('LIVE - TikTok Wall Painter',style:TextStyle(color:Colors.white)) ])),
          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(20)), child:Row(children:[Container(width:8,height:8,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle)), const SizedBox(width:6), const Text('LIVE',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold))])),
        ])),
        Expanded(child: Stack(children:[
          // BG
          Positioned.fill(child: Image.asset('assets/images/wall_bg.webp', fit:BoxFit.cover, errorBuilder:(c,e,s)=>Container(color:const Color(0xFF0A2A33)))),
          // PROFILE AREA - center
          Positioned(left:0,right:0,top:h*0.06, child: Column(children:[
            if(isVIP) const Text('👑', style:TextStyle(fontSize:32)),
            Stack(alignment:Alignment.center, children:[
              // S placeholder - gayeb hoye jabe as reveal increases
              Opacity(opacity:1-reveal, child: Container(width:isVIP?150:120,height:isVIP?150:120, decoration:BoxDecoration(color:Colors.purple,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:4)), child:const Center(child:Text('S',style:TextStyle(fontSize:56,color:Colors.white,fontWeight:FontWeight.bold))))),
              // Real profile photo - aste aste fute uthbe
              Opacity(opacity:reveal, child: Container(width:isVIP?150:120,height:isVIP?150:120, decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:isVIP?Colors.amber:Colors.white,width:isVIP?6:4), image:_profileFile!=null?null:const DecorationImage(image:AssetImage('assets/images/ktm_artist_3d.png'),fit:BoxFit.cover)), child:_profileFile!=null?ClipOval(child:Image.network(_profileFile!.path,fit:BoxFit.cover)):null)),
            ]),
            if(isVIP) Container(margin:const EdgeInsets.only(top:6), padding:const EdgeInsets.symmetric(horizontal:14,vertical:4), decoration:BoxDecoration(color:Colors.red,borderRadius:BorderRadius.circular(10),border:Border.all(color:Colors.amber,width:2)), child:const Text('VIP', style:TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:18))),
            const SizedBox(height:8),
            Opacity(opacity:reveal, child: Text(currentName, textAlign:TextAlign.center, style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold,color:Colors.white,shadows:[Shadow(color:Colors.black,blurRadius:8)],decoration:TextDecoration.underline,decorationColor:Colors.red,decorationThickness:3))),
            Text('Bullets Fired: $_shotIndex', style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
          ])),
          // Splashes - they disappear after 350ms
          ...splashes.map((b)=>Positioned(left:b.targetX*w-14,top:b.targetY*h-14,child:Container(width:28,height:28,decoration:BoxDecoration(color:b.color.withOpacity(0.9),shape:BoxShape.circle,boxShadow:[BoxShadow(color:b.color,blurRadius:8)]),child:const Center(child:Text('✦',style:TextStyle(color:Colors.white,fontSize:14)))))),
          // Flying bullets - gun to wall, top to bottom target
          ...bullets.map((b){
            double y=gunY+(b.targetY*h-gunY)*b.progress;
            double x=140+(b.targetX*w-140)*b.progress;
            return Positioned(left:x,top:y,child:Container(width:14,height:14,decoration:BoxDecoration(color:b.color,shape:BoxShape.circle)));
          }),
          // Artist - left, gun right, clean muzzle (new image has neon star, no pink blob)
          Positioned(left:0,bottom:0, width:130, height:220, child: Image.asset('assets/images/ktm_artist_3d.png', fit:BoxFit.contain, alignment:Alignment.bottomCenter)),
          // How to get painted - bottom right small
          Positioned(right:8,bottom:8,width:178,child:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('How To Get Painted?',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),
          Row(children:[Container(width:26,height:26,decoration:const BoxDecoration(color:Colors.pink,shape:BoxShape.circle),child:const Center(child:Text('🎨',style:TextStyle(fontSize:13)))), const SizedBox(width:6), const Expanded(child:Text('Type Me -> Name'))]),
          const SizedBox(height:4),
          Row(children:[Container(width:26,height:26,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:const Center(child:Text('❤️',style:TextStyle(fontSize:13)))), const SizedBox(width:6), const Expanded(child:Text('Follow -> Name + Photo'))]),
          const SizedBox(height:4),
          Row(children:[Container(width:26,height:26,decoration:const BoxDecoration(color:Colors.blue,shape:BoxShape.circle),child:const Center(child:Text('↗️',style:TextStyle(fontSize:13)))), const SizedBox(width:6), const Expanded(child:Text('Share -> Name + Photo'))]),
          const SizedBox(height:4),
          Row(children:[Container(width:26,height:26,decoration:const BoxDecoration(color:Colors.orange,shape:BoxShape.circle),child:const Center(child:Text('👆',style:TextStyle(fontSize:13)))), const SizedBox(width:6), const Expanded(child:Text('100 Tap -> Name'))]),
          const SizedBox(height:4),
          Row(children:[Container(width:26,height:26,decoration:const BoxDecoration(color:Colors.purple,shape:BoxShape.circle),child:const Center(child:Text('🎁',style:TextStyle(fontSize:13)))), const SizedBox(width:6), const Expanded(child:Text('Gift -> VIP Photo'))]),
        ]))),
        ])),
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), color:const Color(0xFF0A2A33), child: Row(children:[const Text('Recent:',style:TextStyle(color:Colors.white70)), const SizedBox(width:8), Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6), decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10)), child:Text(currentName)), const SizedBox(width:8), Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6), decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10)), child:const Text('Shah Alam Fan'))])),
        Padding(padding:const EdgeInsets.all(10), child: Row(children:[
          Expanded(child: TextField(onChanged:(v)=>inputName=v, decoration:InputDecoration(hintText:'Type your name...',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(30))))),
          const SizedBox(width:8),
          ElevatedButton(onPressed:(){ if(inputName.isNotEmpty){ setState((){currentName=inputName; isVIP=inputName.toLowerCase().contains('gift')||inputName.toLowerCase().contains('vip'); reveal=0; _shotIndex=0; splashes.clear();}); for(int i=0;i<15;i++){ Future.delayed(Duration(milliseconds:i*140),()=>fireOne()); } } }, style:ElevatedButton.styleFrom(backgroundColor:Colors.pink,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(30))), child:const Text('Send as Viewer')),
        ])),
        // No button / no switch - Send as Viewer = TikTok action, auto fires 15 bullets
        const SizedBox(height:2),
        const SizedBox(height:10),
      ]),
    );
  }
}
