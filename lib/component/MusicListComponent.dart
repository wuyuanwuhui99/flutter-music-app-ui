import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/serverMethod.dart';
import '../provider/PlayerMusicProvider.dart';
import '../model/MusicModel.dart';
import './MusicAvaterComponent.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../theme/ThemeColors.dart';

class MusicListComponent extends StatefulWidget {
  final List<MusicModel> musicList;
  final String classifyName;
  final Function onPlayMusic;

  MusicListComponent(
      {super.key,required this.musicList,required this.classifyName,required this.onPlayMusic});

  @override
  _MusicListComponentState createState() => _MusicListComponentState();
}

class _MusicListComponentState extends State<MusicListComponent> {
  bool loading = false;

  ///@author: wuwenqiang
  ///@description: 点赞和取消点赞
  ///@date: 2024-07-27 00:26
  void useLike(MusicModel musicModel) {
    if (loading) return;
    if (musicModel.isLike == 0) {
      insertMusicLikeService(musicModel.id).then((res) {
        loading = false;
        if (res.data > 0) {
          setState(() {
            musicModel.isLike = 1;
          });
        }
      }).catchError(() {
        loading = false;
      });
    } else {
      deleteMusicLikeService(musicModel.id).then((res) {
        loading = false;
        if (res.data > 0) {
          setState(() {
            musicModel.isLike = 0;
          });
        }
      }).catchError(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    PlayerMusicProvider provider =
        Provider.of<PlayerMusicProvider>(context, listen: true);
    List<Widget> musicListWidget = [];
    int index = -1;
    widget.musicList.forEach((ele) {
      int i = ++index;
      musicListWidget.add(InkWell(
        onTap: () {
          widget.onPlayMusic(ele, i);
        },
        child: Row(children: [
          MusicAvaterComponent(type:'music',name:'',avater:ele.cover,size:ThemeSize.middleAvater),
          SizedBox(width: ThemeSize.containerPadding),
          Expanded(
            flex: 1,
            child: Text('${ele.authorName} - ${ele.songName}'),
          ),
          SizedBox(width: ThemeSize.containerPadding),
          Image.asset(
              provider.musicModel?.id == ele.id &&
                      provider.playing &&
                      provider.classifyName == widget.classifyName
                  ? 'lib/assets/images/icon_music_playing_grey.png'
                  : 'lib/assets/images/icon_music_play.png',
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon),
          SizedBox(width: ThemeSize.containerPadding),
          InkWell(
            onTap: () {
              useLike(ele);
            },
            child: Image.asset(
                ele.isLike == 1
                    ? 'lib/assets/images/icon_like_active.png'
                    : 'lib/assets/images/icon_like.png',
                width: ThemeSize.smallIcon,
                height: ThemeSize.smallIcon),
          ),
          SizedBox(width: ThemeSize.containerPadding),
          Image.asset('lib/assets/images/icon_music_menu.png',
              width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
        ]),
      ));
      if (index != widget.musicList.length - 1) {
        musicListWidget.add(Container(
          height: 1,
          decoration: BoxDecoration(color: ThemeColors.borderColor),
          margin: EdgeInsets.only(
              top: ThemeSize.containerPadding,
              bottom: ThemeSize.containerPadding),
        ));
      }
    });
    return Container(
        padding: ThemeStyle.padding,
        decoration: ThemeStyle.boxDecoration,
        child: Column(children: musicListWidget));
  }
}
