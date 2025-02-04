import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import '../component/MusicAvaterComponent.dart';
import 'package:provider/provider.dart';
import '../router/index.dart';
import '../model/MusicModel.dart';
import '../provider/PlayerMusicProvider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeStyle.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import '../common/constant.dart';

class MusicRecommentPage extends StatefulWidget {
  const MusicRecommentPage({super.key});

  @override
  _MusicRecommentPageState createState() => _MusicRecommentPageState();
}

class _MusicRecommentPageState extends State<MusicRecommentPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int pageNum = 2; // 初始化加载两页共20条数据，后面每页加载10条
  int pageSize = 10;
  int total = 0;
  List<MusicModel> musicModelList = [];
  List<String> iconList = [
    "lib/assets/images/icon_no1.png",
    "lib/assets/images/icon_no2.png",
    "lib/assets/images/icon_no3.png"
  ];
  late MusicModel currentPlayingMusicModel;
  late bool playing;
  EasyRefreshController easyRefreshController = EasyRefreshController();

  @override
  void initState() {
    super.initState();
    getRecommendMusicList(1, 20);
    usePlayState();
  }

  /// 获取播放状态
  usePlayState() {
    AudioPlayer player =
        Provider.of<PlayerMusicProvider>(context, listen: false).player;
    player.onPlayerStateChanged.listen((event) {
      setState(() {
        playing = event.index == 1;
      });
    });
  }

  void getRecommendMusicList(int pageNum, pageSize) {
    getMusicListByClassifyIdService(1, pageNum, pageSize, 1).then((res) {
      setState(() {
        total = res.total!;
        res.data.forEach((item) {
          item['classifyId'] = 1;
          item['pageNum'] = pageNum;
          item['pageSize'] = pageSize;
          item['isRedis'] = 0;
          musicModelList.add(MusicModel.fromJson(item));
        });
      });
      easyRefreshController.finishLoad(success: true,noMore: musicModelList.length == total);
    });
  }

  // 创建音乐列表项
  Widget buildMusicItem(
      List<MusicModel> musicModelList, MusicModel musicModel, int index) {
    return Container(
        decoration: ThemeStyle.boxDecoration,
        margin: ThemeStyle.margin,
        width:
            MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
        padding: ThemeStyle.padding,
        child: Row(children: [
          index < iconList.length
              ? Image.asset(iconList[index],
                  width: ThemeSize.middleIcon, height: ThemeSize.middleIcon)
              : Container(
                  width: ThemeSize.middleIcon,
                  height: ThemeSize.middleIcon,
                  child: Center(
                      child: Text(
                    (index + 1).toString(),
                  ))),
          SizedBox(width: ThemeSize.containerPadding),
          MusicAvaterComponent(type:'music',name:'',size: ThemeSize.middleAvater,avater:musicModel.cover),
          SizedBox(width: ThemeSize.containerPadding),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(musicModel.songName,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: ThemeSize.smallMargin),
                Text(musicModel.authorName,
                    style: TextStyle(color: ThemeColors.disableColor)),
              ],
            ),
          ),
          InkWell(
              child: Image.asset(
                  playing && musicModel.id == currentPlayingMusicModel.id
                      ? "lib/assets/images/icon_music_playing_grey.png"
                      : "lib/assets/images/icon_music_play.png",
                  width: ThemeSize.smallIcon,
                  height: ThemeSize.smallIcon),
              onTap: () async {
                PlayerMusicProvider provider = Provider.of<PlayerMusicProvider>(context, listen: false);
                if(provider.classifyName != '推荐歌曲'){
                  await getMusicListByClassifyIdService(1, 1, MAX_FAVORITE_NUMBER, 1).then((value){
                    provider.setClassifyMusic(value.data.map((element) => MusicModel.fromJson(element)).toList(),musicModel,index,'推荐歌曲');
                  });
                }else if(musicModel.id != provider.musicModel?.id){
                  provider.setPlayMusic(musicModel, true);
                }
                Routes.router.navigateTo(context, '/MusicPlayerPage');
              }),
          SizedBox(width: ThemeSize.containerPadding),
          InkWell(child: Image.asset(
              "lib/assets/images/icon_like${musicModel.isLike == 1 ? "_active" : ""}.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon),onTap: (){
            if(musicModel.isLike == 0){
              insertMusicLikeService(musicModel.id).then((res) => {
                if(res.data > 0){
                  setState(() {
                    musicModel.isLike = 1;
                  })
                }
              });
            }else{
              deleteMusicLikeService(musicModel.id).then((res) => {
                if(res.data > 0){
                  setState(() {
                    musicModel.isLike = 0;
                  })
                }
              });
            }
          }),
          SizedBox(width: ThemeSize.containerPadding),
          Image.asset("lib/assets/images/icon_music_menu.png",
              width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
        ]));
  }

  List<Widget> buildMusicWedgetList() {
    List<Widget> musicWedgetList = [];
    int index = 0;
    musicModelList.forEach((element) {
      musicWedgetList.add(buildMusicItem(musicModelList, element, index));
      index++;
    });
    return musicWedgetList;
  }

  @override
  Widget build(BuildContext context) {
    currentPlayingMusicModel =
        Provider.of<PlayerMusicProvider>(context).musicModel;
    playing = Provider.of<PlayerMusicProvider>(context).playing;
    return Container(
      width: MediaQuery.of(context).size.width,
      child: EasyRefresh(
        controller: easyRefreshController,
        footer: ClassicalFooter(
          loadText: '上拉加载',
          loadReadyText: '准备加载',
          loadingText: '加载中...',
          loadedText: '加载完成',
          noMoreText: '没有更多',
          bgColor: Colors.transparent,
          textColor: ThemeColors.disableColor,
        ),
        onLoad: () async {
          pageNum++;
          if (total <= musicModelList.length) {
            Fluttertoast.showToast(
                msg: "已经到底了",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: ThemeSize.middleFontSize);
          } else {
            getRecommendMusicList(pageNum, pageSize);
          }
        },
        child: Column(
          children: buildMusicWedgetList(),
        ),
      ),
    );
  }
}
