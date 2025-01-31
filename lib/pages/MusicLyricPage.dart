import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../provider/PlayerMusicProvider.dart';
import '../model/MusicModel.dart';
import '../common/constant.dart';

class MusicLyricPage extends StatefulWidget {
  const MusicLyricPage({super.key});

  @override
  _MusicLyricPageState createState() => _MusicLyricPageState();
}

class _MusicLyricPageState extends State<MusicLyricPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  //歌词控制器
  // late LyricController _lyricController;
  late AudioPlayer player;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _lyricController = LyricController(vsync: this);
    player = Provider.of<PlayerMusicProvider>(context, listen: false).player;
    // player.onAudioPositionChanged.listen((event) {
    //   _lyricController.progress = Duration(seconds: event.inSeconds);
    // });
  }

  @override
  Widget build(BuildContext context) {
    MusicModel musicModel = Provider.of<PlayerMusicProvider>(context, listen: false).musicModel;

    return Scaffold(
        backgroundColor: ThemeColors.colorBg,
        body:Stack(children: [
          /// 图片在Stack最底层
          ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: 50, sigmaY: 50, tileMode: TileMode.mirror),
            child: Image.network(HOST + musicModel.cover,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child:  Center(
                    child:SizedBox()
                    // LyricWidget(
                    //   lyricStyle: TextStyle(
                    //       color: ThemeColors.opcityWhiteColor,
                    //       fontSize: ThemeSize.middleFontSize),
                    //   currLyricStyle: TextStyle(
                    //       color: ThemeColors.colorWhite,
                    //       fontSize: ThemeSize.middleFontSize),
                    //   size: Size(double.infinity, double.infinity),
                    //   lyrics: LyricUtil.formatLyric(musicModel.lyrics),
                    //   controller: _lyricController,
                    // )
            )
            ),
          ])
        );
  }
}

