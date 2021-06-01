import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radio/models/radio.dart';
import 'package:radio/utils/radio_utils.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:alan_voice/alan_voice.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio> radios;
  MyRadio _selectedRadio;
  Color _selectedColor;
  bool _isplaying=false;

  final AudioPlayer _audioPlayer=AudioPlayer();
  @override
  void initState() {
    super.initState();
    fetchRadios();
    setupAlan();
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING) {
        _isplaying = true;
      } else {
        _isplaying = false;
      }
      setState(() {});
    });
  }
  setupAlan(){
    AlanVoice.addButton("Add your alan api key",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command)=> handleCommand(command.data));
  }
  
  handleCommand(Map<String, dynamic> response){
    switch(response['command']){
      case "play":
        _playMusic(_selectedRadio.url);
        break;
      case "stop":
        _audioPlayer.stop();
        break;
      case "next":
        final index=_selectedRadio.id;
        MyRadio newradio;
        if(index+1>radios.length){
          newradio=radios.firstWhere((element) => element.id==1);
          radios.remove(newradio);
          radios.insert(0, newradio);
        }
        else{
          newradio=radios.firstWhere((element) => element.id==index+1);
          radios.remove(newradio);
          radios.insert(0, newradio);
        }
        _playMusic(newradio.url);
        break;
      case "next":
        final index=_selectedRadio.id;
        MyRadio newradio;
        if(index-1<=0){
          newradio=radios.firstWhere((element) => element.id==1);
          radios.remove(newradio);
          radios.insert(0, newradio);
        }
        else{
          newradio=radios.firstWhere((element) => element.id==index-1);
          radios.remove(newradio);
          radios.insert(0, newradio);
        }
        _playMusic(newradio.url);
        break;
      default:
        print("command was${response['command']}");
    }
  }
  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    setState(() {});
  }

  _playMusic(String url){
    _audioPlayer.play(url);
    _selectedRadio=radios.firstWhere((element) => element.url==url);
    setState(() {

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      body: Stack(
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(
            LinearGradient(
              colors: [
                AIColors.primaryColor2,
              _selectedColor?? AIColors.primaryColor1,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )
              .make(),
          AppBar(
            title: "RRadio".text.xl4.bold.white.make().shimmer(
                primaryColor: Vx.purple300,
              secondaryColor: Vx.white,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ).h(100).p16(),
          
         radios!=null? VxSwiper.builder(
            aspectRatio: 1.0,
              enlargeCenterPage: true,
             onPageChanged: (index) {
               _selectedRadio = radios[index];
               final colorHex = radios[index].color;
               _selectedColor = Color(int.tryParse(colorHex));
               setState(() {});
             },
              itemCount: radios.length,
              itemBuilder:(context,index){
            final rad=radios[index];

            return VxBox(

              child: ZStack(
                [
                  Positioned(
                    top: 0.0,
                    right: 0.0,
                    child: VxBox(
                      child:
                      rad.category.text.uppercase.white.make().px16(),
                    )
                        .height(40)
                        .black
                        .alignCenter
                        .withRounded(value: 10.0)
                        .make(),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VStack(

                      [
                        rad.name.text.xl3.white.bold.make(),
                        5.heightBox,
                        rad.tagline.text.sm.white.semiBold.make(),
                      ],
                      crossAlignment:CrossAxisAlignment.center,
                    ),
                  ),
                  Align(
                      alignment: Alignment.center,
                      child: [
                        Icon(
                          CupertinoIcons.play_circle,
                          color: Colors.white,
                        ),
                        10.heightBox,
                        "Double tap to play".text.gray300.make(),
                      ].vStack()
                  )

                ]
              )
            ).clip(Clip.antiAlias)
                .bgImage(DecorationImage(
                image: NetworkImage(rad.image),
                fit:BoxFit.cover,
                colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
                BlendMode.darken),
            ),
            ).border(color: Colors.black, width: 3.0)
                .withRounded(value: 60.0)
                .make()
                .onInkDoubleTap((){
                  _playMusic(rad.url);
            })
                .p16();
          }).centered():Center(
           child: CircularProgressIndicator(
             backgroundColor: Colors.white,
           ),
         ),
          Align(
            alignment: Alignment.bottomCenter,
            child: VStack(
              [

                if(_isplaying)
                  "Playing Now - ${_selectedRadio.name} FM".text.white.makeCentered().p16(),

                Center(
                  child: Icon(
                    _isplaying?CupertinoIcons.stop_circle:CupertinoIcons.play_circle,
                    color: Colors.white,
                    size: 50.0,
                  ).onInkTap(() {
                    if(_isplaying){
                      _audioPlayer.stop();
                    }
                    else{
                      _playMusic(_selectedRadio.url);
                    }
                  }),
                ),
              ]
            ),
          ).pOnly(bottom: context.percentHeight*12),
        ],
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
