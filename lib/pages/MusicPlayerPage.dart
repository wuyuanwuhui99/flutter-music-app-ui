import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/LocalStorageUtils.dart';
import '../service/serverMethod.dart';
import '../router/index.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../provider/PlayerMusicProvider.dart';
import '../model/MusicModel.dart';
import '../common/config.dart';
import '../common/constant.dart';
import '../utils/common.dart';
import '../component/CommentComponent.dart';
import '../component/FavoriteComponent.dart';
import '../utils/HttpUtil.dart';
import '../component/MusicAvaterComponent.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  MusicPlayerPageState createState() => MusicPlayerPageState();
}

class MusicPlayerPageState extends State<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;
  double sliderValue = 0;
  int duration = 0; // 已经播放额时间
  int totalSec = 0; // 总时间
  late AudioPlayer player;
  int currentPlayIndex = -1; // 当前播放音乐的下标
  // late LyricController _lyricController; //歌词控制器
  late AnimationController _repeatController; // 会重复播放的控制器
  late Animation<double> _curveAnimation; // 非线性动画
  int commentTotal = 0;
  Map<LoopModeEnum, String> loopMode = {
    LoopModeEnum.ORDER: "lib/assets/images/icon_music_order.png",
    LoopModeEnum.REPEAT: "lib/assets/images/icon_music_loop.png",
    LoopModeEnum.RANDOM: "lib/assets/images/icon_music_random.png"
  };
  late StreamSubscription onDurationChangedListener; // 监听总时长
  late StreamSubscription onAudioPositionChangedListener; // 监听播放进度
  late StreamSubscription onPlayerCompletionListener; // 监听播放完成
  late PlayerMusicProvider provider;
  bool loading = false;
  bool isFavorite = false; // 是否已经收藏

  @override
  void initState() {
    provider = Provider.of<PlayerMusicProvider>(context, listen: false);
    // _lyricController = LyricController(vsync: this);
    usePlay();
    _repeatController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 创建一个从0到360弧度的补间动画 v * 2 * π
    _curveAnimation =
        Tween<double>(begin: 0, end: 1).animate(_repeatController);

    // 获取当前正在播放的音乐下标
    currentPlayIndex = provider.playIndex;

    useIsMusicFavorite();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 添加监听订阅
    // MyApp.routeObserver.subscribe(this, ModalRoute.of(context));
  }

  ///@author: wuwenqiang
  ///@description: 退出当前页面，返回上一级页面
  ///@date: 2024-06-18 21:57
  @override
  void didPop() {
    super.didPop();
    onDurationChangedListener.cancel(); // 取消监听音乐播放时长
    onAudioPositionChangedListener.cancel(); // 取消监听音乐播放进度
  }

  @override
  void dispose() {
    super.dispose();
    // 移除监听订阅
    onDurationChangedListener.cancel(); // 取消监听音乐播放时长
    onAudioPositionChangedListener.cancel(); // 取消监听音乐播放进度
    // MyApp.routeObserver.unsubscribe(this);
    _repeatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<PlayerMusicProvider>(context, listen: true);
    return Scaffold(
        backgroundColor: ThemeColors.colorBg,
        body: Stack(children: [
          /// 图片在Stack最底层
          ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: 50, sigmaY: 50, tileMode: TileMode.mirror),
            child: provider.musicModel.cover != null && provider.musicModel.cover != ''
                ? Image.network(getMusicCover(provider.musicModel.cover),
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width)
                : Image.asset('lib/assets/images/default_cover.jpg',
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: ThemeSize.containerPadding * 2),
                Text(provider.musicModel.songName,
                    style: TextStyle(
                        color: ThemeColors.colorWhite,
                        fontSize: ThemeSize.bigFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: ThemeSize.containerPadding),
                buildPlayCircle(),
                SizedBox(height: ThemeSize.containerPadding),
                Expanded(flex: 1, child: buildLyric()),
                SizedBox(height: ThemeSize.containerPadding),
                buildSinger(),
                SizedBox(height: ThemeSize.containerPadding),
                buildPlayMenu(),
                SizedBox(height: ThemeSize.containerPadding),
                buildprogress(),
                SizedBox(height: ThemeSize.containerPadding),
                buildPlayBtn(),
                SizedBox(height: ThemeSize.containerPadding)
              ],
            ),
          )
        ]));
  }

  Widget buildPlayCircle() {
    double playerWidth =
        MediaQuery.of(context).size.width - ThemeSize.containerPadding * 6;
    return Container(
        width: playerWidth,
        height: playerWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: ThemeColors.opcityColor,
          borderRadius: BorderRadius.circular(playerWidth),
        ),
        child: RotationTransition(
          turns: _curveAnimation,
          child: Container(
              width: playerWidth - ThemeSize.smallMargin,
              height: playerWidth - ThemeSize.smallMargin,
              margin: EdgeInsets.all(ThemeSize.smallMargin),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Color.fromRGBO(54, 57, 56, 1),
                    Color.fromRGBO(54, 57, 56, 1),
                    Colors.black,
                  ],
                ),
                borderRadius: BorderRadius.circular(playerWidth),
              ),
              child: Padding(
                  padding: EdgeInsets.all(ThemeSize.containerPadding * 4),
                  child: ClipOval(
                      child:
                      MusicAvaterComponent(type:'music',name:'',avater:provider.musicModel.cover,size:playerWidth -
                          ThemeSize.smallMargin -
                          ThemeSize.containerPadding * 3),
                  ))),
        ));
  }

  Widget buildLyric() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
          child: provider.musicModel.lyrics != null &&
                  provider.musicModel.lyrics != ''
              ? InkWell(
                  child:SizedBox(),
                  // LyricWidget(
                  //   lyricStyle: TextStyle(
                  //       color: ThemeColors.opcityWhiteColor,
                  //       fontSize: ThemeSize.middleFontSize),
                  //   currLyricStyle: TextStyle(
                  //       color: ThemeColors.colorWhite,
                  //       fontSize: ThemeSize.middleFontSize),
                  //   size: Size(double.infinity, double.infinity),
                  //   lyrics: LyricUtil.formatLyric(provider.musicModel.lyrics),
                  //   controller: _lyricController,
                  // ),
                  onTap: () {
                    Routes.router.navigateTo(context, '/MusicLyricPage');
                  },
                )
              : Text('暂无歌词',
                  style: TextStyle(
                      color: ThemeColors.opcityWhiteColor,
                      fontSize: ThemeSize.middleFontSize))),
    );
  }

  ///@author: wuwenqiang
  ///@description: 创建歌手
  /// @date: 2024-05-22 22:29
  Widget buildSinger() {
    return Center(
        child: Text(provider.musicModel.authorName,
            maxLines: 1, // 设置最大行数为1
            overflow: TextOverflow.ellipsis, // 设置溢出模式为省略号
            style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: ThemeColors.colorWhite,
                color: ThemeColors.colorWhite)));
  }

  ///@author: wuwenqiang
  ///@description: 创建底部弹窗
  /// @date: 2024-06-23 22:29
  void buildModalBottomSheet(Widget component) {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ThemeSize.middleRadius),
                topRight: Radius.circular(ThemeSize.middleRadius))),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: component);
        });
  }

  ///@author: wuwenqiang
  ///@description: 音乐播放操作
  /// @date: 2024-06-23 22:29
  Widget buildPlayMenu() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: InkWell(
            child: Image.asset(
              provider.musicModel.isLike == 0
                  ? "lib/assets/images/icon_music_collect.png"
                  : "lib/assets/images/icon_collection_active.png",
              width: ThemeSize.playIcon,
              height: ThemeSize.playIcon,
            ),
            onTap: () {
              if (loading) return;
              loading = true;
              PlayerMusicProvider provider =
                  Provider.of<PlayerMusicProvider>(context, listen: false);
              if (provider.musicModel.isLike == 0) {
                insertMusicLikeService(provider.musicModel.id).then((res) {
                  loading = false;
                  if (res.data > 0) {
                    provider.setFavorite(1);
                  }
                }).catchError(() {
                  loading = false;
                });
              } else {
                deleteMusicLikeService(provider.musicModel.id).then((res) {
                  loading = false;
                  if (res.data > 0) {
                    provider.setFavorite(0);
                  }
                }).catchError(() {
                  loading = false;
                });
              }
            },
          ),
        ),
        Expanded(
          child: InkWell(
            child: Image.asset(
              "lib/assets/images/icon_share_music.png",
              width: ThemeSize.playIcon,
              height: ThemeSize.playIcon,
            ),
            onTap: () {
              Routes.router.navigateTo(context,
                  '/MusicSharePage?musicItem=${Uri.encodeComponent(MusicModel.stringify(provider.musicModel))}');
            },
          ),
          flex: 1,
        ),
        Expanded(
          flex: 1,
          child: InkWell(
              child: Image.asset(
                "lib/assets/images/icon_music_comments.png",
                width: ThemeSize.playIcon,
                height: ThemeSize.playIcon,
              ),
              onTap: () async {
                ResponseModel<List> res = await getTopCommentListService(
                    provider.musicModel.id, CommentEnum.MUSIC, 1, 20);
                commentTotal = res.total ?? 0;
                buildModalBottomSheet(CommentComponent(
                  type: CommentEnum.MUSIC,
                  relationId: provider.musicModel.id,
                ));
              }),
        ),
        Expanded(
          flex: 1,
          child: InkWell(
            child: Image.asset(
              isFavorite
                  ? "lib/assets/images/icon_full_star.png"
                  : "lib/assets/images/icon_favorite.png",
              width: ThemeSize.playIcon,
              height: ThemeSize.playIcon,
            ),
            onTap: () {
              buildModalBottomSheet(FavoriteComponent(
                musicId: provider.musicModel.id,
                isFavorite: isFavorite,
                onFavorite: (bool isMusicFavorite) {
                  Navigator.pop(context);
                  setState(() {
                    isFavorite = isMusicFavorite;
                  });
                },
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget buildprogress() {
    return Row(
      children: [
        SizedBox(width: ThemeSize.containerPadding * 2),
        Text(getDuration(duration),
            style: TextStyle(color: ThemeColors.colorWhite)),
        Expanded(
          flex: 1,
          child: Slider(
            value: sliderValue,
            onChanged: (data) {
              provider.player.seek(Duration(seconds: totalSec * data ~/ 100));
              setState(() {
                sliderValue = data;
              });
            },
            onChangeStart: (data) {
              print('start:$data');
            },
            onChangeEnd: (data) {
              print('end:$data');
            },
            min: 0,
            max: 100.0,
            activeColor: ThemeColors.opcityWhiteColor,
            inactiveColor: ThemeColors.opcityColor,
          ),
        ),
        Text(getDuration(totalSec),
            style: TextStyle(color: ThemeColors.colorWhite)),
        SizedBox(width: ThemeSize.containerPadding * 2),
      ],
    );
  }

  Widget buildPlayBtn() {
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: PopupMenuButton<LoopModeEnum>(
              color: ThemeColors.popupMenuColor,
              initialValue: provider.loopMode,
              child: Image.asset(
                loopMode[provider.loopMode]!,
                width: ThemeSize.playIcon,
                height: ThemeSize.playIcon,
              ),
              onSelected: (LoopModeEnum loopMode) {
                provider.setLoopMode(loopMode);
                LocalStorageUtils.setLoopMode(loopMode);
              },
              itemBuilder: (context) {
                return <PopupMenuEntry<LoopModeEnum>>[
                  PopupMenuItem<LoopModeEnum>(
                      value: LoopModeEnum.ORDER,
                      child: Row(children: <Widget>[
                        Image.asset("lib/assets/images/icon_music_order.png",
                            width: ThemeSize.smallIcon,
                            height: ThemeSize.smallIcon),
                        SizedBox(width: ThemeSize.smallMargin),
                        Text('顺序播放',
                            style: TextStyle(color: ThemeColors.colorWhite))
                      ])),
                  PopupMenuItem<LoopModeEnum>(
                    value: LoopModeEnum.REPEAT,
                    child: Row(children: <Widget>[
                      Image.asset('lib/assets/images/icon_music_loop.png',
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),
                      SizedBox(width: ThemeSize.smallMargin),
                      Text('单曲循环',
                          style: TextStyle(color: ThemeColors.colorWhite))
                    ]),
                  ),
                  PopupMenuItem<LoopModeEnum>(
                    value: LoopModeEnum.RANDOM,
                    child: Row(children: <Widget>[
                      Image.asset('lib/assets/images/icon_music_random.png',
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),
                      SizedBox(width: ThemeSize.smallMargin),
                      Text('随机播放',
                          style: TextStyle(color: ThemeColors.colorWhite))
                    ]),
                  )
                ];
              },
            )),
        Expanded(
            flex: 1,
            child: InkWell(
                onTap: usePrevMusic,
                child: Image.asset(
                  "lib/assets/images/icon_music_prev.png",
                  width: ThemeSize.playIcon,
                  height: ThemeSize.playIcon,
                ))),
        Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  child: Container(
                      width: ThemeSize.bigAvater,
                      height: ThemeSize.bigAvater,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(ThemeSize.bigAvater),
                        border:
                            Border.all(color: ThemeColors.colorWhite, width: 2),
                      ),
                      child: Center(
                        child: Image.asset(
                          provider.playing
                              ? "lib/assets/images/icon_music_playing.png"
                              : "lib/assets/images/icon_music_play_white.png",
                          width: ThemeSize.playIcon,
                          height: ThemeSize.playIcon,
                        ),
                      )),
                  onTap: () {
                    if (provider.playing) {
                      provider.player.pause();
                      provider.setPlaying(false);
                      _repeatController.stop(canceled: false);
                    } else {
                      provider.player.resume();
                      provider.setPlaying(true);
                      _repeatController.forward();
                      _repeatController.repeat();
                    }
                  },
                )
              ],
            )),
        Expanded(
            flex: 1,
            child: InkWell(
                onTap: useNextMusic,
                child: Image.asset(
                  "lib/assets/images/icon_music_next.png",
                  width: ThemeSize.playIcon,
                  height: ThemeSize.playIcon,
                ))),
        Expanded(
            flex: 1,
            child: Image.asset(
              "lib/assets/images/icon_music_play_menu.png",
              width: ThemeSize.playIcon,
              height: ThemeSize.playIcon,
            )),
      ],
    );
  }

  /// 播放音乐
  void usePlay() async {
    final result = await provider.player.play(UrlSource(HOST + provider.musicModel.localPlayUrl));
    if (result == 1) {
      provider.setPlaying(true);
      onDurationChangedListener?.cancel(); // 恢复监听音乐播放时长
      onAudioPositionChangedListener?.cancel(); // 恢复监听音乐播放进度
      onDurationChangedListener =
          provider.player.onDurationChanged.listen((event) {
        setState(() {
          totalSec = event.inSeconds;
        });
      });
      onAudioPositionChangedListener =
          provider.player.onAudioPositionChanged.listen((event) {
        // _lyricController.progress = Duration(seconds: event.inSeconds);
        setState(() {
          duration = event.inSeconds;
          sliderValue = (duration / totalSec) * 100;
        });
      });
      onPlayerCompletionListener?.cancel();
      onPlayerCompletionListener =
          provider.player.onPlayerCompletion.listen((event) {
        useNextMusic(); // 切换下一首
      });
    }
  }

  ///@author: wuwenqiang
  ///@description: 切换上一首
  /// @date: 2024-06-21 23:12
  usePrevMusic() {
    if (provider.loopMode == LoopModeEnum.RANDOM) {
      // 随机播放
      if (provider.playMusicList.length > 1) {
        // 如果已经播放的音乐两首以上，回退上一首
        MusicModel prevMusic =
            provider.playMusicList[provider.playMusicList.length - 2];
        provider.playMusicList.removeAt(provider.playMusicList.length - 1);
        currentPlayIndex =
            provider.musicList.indexWhere((item) => item.id == prevMusic.id);
      } else if (currentPlayIndex == 0) {
        // 如果已经播放的歌曲只有一首，切换上一首
        currentPlayIndex = provider.musicList.length - 1;
      } else {
        currentPlayIndex -= 1;
      }
    } else {
      if (currentPlayIndex > 0) {
        currentPlayIndex--;
      } else {
        currentPlayIndex = provider.musicList.length - 1;
      }
    }
    provider.setPlayIndex(currentPlayIndex);
    useIsMusicFavorite();
  }

  void useIsMusicFavorite() {
    isMusicFavoriteService(provider.musicModel.id).then((value) {
      setState(() {
        isFavorite = value.data > 0;
      });
    });
  }

  ///@author: wuwenqiang
  ///@description: 切换下一首歌曲
  /// @date: 2024-06-14 00:15
  void useNextMusic() {
    if (provider.loopMode == LoopModeEnum.RANDOM) {
      int index = Random().nextInt(provider.unPlayMusicList.length - 1);
      currentPlayIndex = provider.musicList
          .indexWhere((item) => item.id == provider.unPlayMusicList[index].id);
    } else {
      if (currentPlayIndex < provider.musicList.length - 1) {
        currentPlayIndex++;
      } else {
        currentPlayIndex = 0;
      }
    }
    this.useIsMusicFavorite();
    provider.setPlayIndex(currentPlayIndex);
  }
}
