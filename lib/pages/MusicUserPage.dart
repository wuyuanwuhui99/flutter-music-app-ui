import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/FavoriteDirectoryModel.dart';
import '../router/index.dart';
import '../service/serverMethod.dart';
import '../provider/UserInfoProvider.dart';
import '../model/UserInfoModel.dart';
import '../theme/ThemeStyle.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import '../common/constant.dart';
import '../model/MuiscMySingerModel.dart';
import '../model/MusicModel.dart';

class MusicUserPage extends StatefulWidget {
  const MusicUserPage({super.key});

  @override
  _MusicUserPageState createState() => _MusicUserPageState();
}

class _MusicUserPageState extends State<MusicUserPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  List playRecordList = []; // 播放记录列表
  // 创建一个从0到360弧度的补间动画 v * 2 * π
  late AnimationController _repeatController; // 会重复播放的控制器
  late Animation<double> _curveAnimation;

  @override
  void initState() {
    super.initState();
    _repeatController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // 创建一个从0到360弧度的补间动画 v * 2 * π
    _curveAnimation =
        Tween<double>(begin: 0, end: 1).animate(_repeatController);

    getMusicRecordService(1, 10).then((value) {
      this.setState(() {
        playRecordList = value.data;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _repeatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(children: [
      buildUserInfoWidget(),
      buildMenuWidget(),
      buildMyPlaylMenuWidget(),
      buildMySingerList(),
      buildRecordList()
    ]));
  }

  // 用户模块
  Widget buildUserInfoWidget() {
    UserInfoModel userInfo = Provider.of<UserInfoProvider>(context).userInfo;
    return Container(
      decoration: ThemeStyle.boxDecoration,
      margin: ThemeStyle.margin,
      width: MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
      padding: ThemeStyle.padding,
      child: Row(
        children: [
          ClipOval(
              child:userInfo.avater != null ? Image.network(
            //从全局的provider中获取用户信息
        "$HOST${userInfo.avater}",
            height: ThemeSize.bigAvater,
            width: ThemeSize.bigAvater,
            fit: BoxFit.cover,
          ) : Image.asset(
      "lib/assets/images/default_avater.png",
      width: ThemeSize.middleIcon,
      height: ThemeSize.middleIcon,
    )),
          SizedBox(width: ThemeSize.containerPadding),
          Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userInfo.username,
                      style: TextStyle(fontSize: ThemeSize.bigFontSize)),
                  SizedBox(height: ThemeSize.smallMargin),
                  Text(userInfo.sign ??"",
                      style: TextStyle(color: ThemeColors.subTitle))
                ],
              )),
          Image.asset("lib/assets/images/icon_edit.png",
              width: ThemeSize.middleIcon, height: ThemeSize.middleIcon)
        ],
      ),
    );
  }

  Widget buildMenuWidget() {
    return Container(
        decoration: ThemeStyle.boxDecoration,
        margin: ThemeStyle.margin,
        width:
            MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
        padding: ThemeStyle.padding,
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Image.asset("lib/assets/images/icon_menu_board.png",
                        width: ThemeSize.middleIcon,
                        height: ThemeSize.middleIcon),
                    SizedBox(height: ThemeSize.smallMargin),
                    const Text("歌单")
                  ],
                )),
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Image.asset("lib/assets/images/icon_menu_like.png",
                        width: ThemeSize.middleIcon,
                        height: ThemeSize.middleIcon),
                    SizedBox(height: ThemeSize.smallMargin),
                    const Text("喜欢")
                  ],
                )),
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Image.asset("lib/assets/images/icon_menu_collect.png",
                        width: ThemeSize.middleIcon,
                        height: ThemeSize.middleIcon),
                    SizedBox(height: ThemeSize.smallMargin),
                    const Text("收藏")
                  ],
                )),
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Image.asset("lib/assets/images/icon_menu_history.png",
                        width: ThemeSize.middleIcon,
                        height: ThemeSize.middleIcon),
                    SizedBox(height: ThemeSize.smallMargin),
                    const Text("收藏")
                  ],
                )),
          ],
        ));
  }

  Widget buildMyPlaylMenuWidget() {
    return Container(
        decoration: ThemeStyle.boxDecoration,
        margin: ThemeStyle.margin,
        width:
            MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
        padding: ThemeStyle.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("lib/assets/images/icon_down.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
                SizedBox(width: ThemeSize.smallMargin),
                const Text("我的歌单"),
                const Expanded(flex: 1, child: SizedBox()),
                Image.asset("lib/assets/images/icon_menu_add.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
              ],
            ),
            FutureBuilder(
                future: getFavoriteDirectoryService(0),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Container();
                  } else {
                    List<Widget> playMenuList = [];
                    snapshot.data?.data.forEach((item) {
                      FavoriteDirectoryModel favoriteDirectoryModel = FavoriteDirectoryModel.fromJson(item);
                      playMenuList.add(buildPlayMenuItem(favoriteDirectoryModel));
                    });
                    if (playMenuList.isEmpty) {
                      return Container();
                    } else {
                      return Column(children: playMenuList);
                    }
                  }
                })
          ],
        ));
  }

  // 创建我的歌单item
  Widget buildPlayMenuItem(FavoriteDirectoryModel favoriteDirectoryModel) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: ThemeSize.containerPadding),
      InkWell(child: Row(
        children: [
          favoriteDirectoryModel.cover != null
              ? ClipOval(
              child: Image.network(
                "$HOST${favoriteDirectoryModel.cover}",
                width: ThemeSize.bigAvater,
                height: ThemeSize.bigAvater,
              ))
              : Container(
              width: ThemeSize.bigAvater,
              height: ThemeSize.bigAvater,
              //超出部分，可裁剪
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: ThemeColors.colorBg,
                borderRadius: BorderRadius.circular(ThemeSize.bigAvater),
              ),
              child: Center(
                  child: Text(
                    favoriteDirectoryModel.name.substring(0, 1),
                    style: TextStyle(fontSize: ThemeSize.bigFontSize),
                  ))),
          SizedBox(width: ThemeSize.containerPadding),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(favoriteDirectoryModel.name),
                SizedBox(height: ThemeSize.smallMargin),
                Text("${favoriteDirectoryModel.total}首",
                    style: TextStyle(color: ThemeColors.subTitle))
              ],
            ),
          ),
          Image.asset(
            "lib/assets/images/icon_music_play.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          ),
          SizedBox(width: ThemeSize.containerPadding * 2),
          SizedBox(width: ThemeSize.containerPadding * 2),
          Image.asset(
            "lib/assets/images/icon_music_menu.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          )
        ],
      ),onTap: (){
        Routes.router.navigateTo(context, '/MusicFavoriteListPage?favoriteDirectoryModel=${Uri.encodeComponent(FavoriteDirectoryModel.stringify(favoriteDirectoryModel))}');
      },)

    ]);
  }

  // 我关注的歌手
  Widget buildMySingerList() {
    return Container(
        decoration: ThemeStyle.boxDecoration,
        margin: ThemeStyle.margin,
        width:
            MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
        padding: ThemeStyle.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("lib/assets/images/icon_down.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
                SizedBox(width: ThemeSize.smallMargin),
                const Text("我的关注的歌手"),
                const Expanded(flex: 1, child: SizedBox()),
                Image.asset("lib/assets/images/icon_menu_add.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
              ],
            ),
            FutureBuilder(
                future: getMyLikeMusicAuthorService(1, 3),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Container();
                  } else {
                    List<Widget> playMenuList = [];
                    snapshot.data?.data.forEach((item) {
                      MuiscMySingerModel mySingerModel =
                          MuiscMySingerModel.fromJson(item);
                      playMenuList.add(buildMySingerItem(mySingerModel));
                    });
                    if (playMenuList.isEmpty) {
                      return Container();
                    } else {
                      return Column(children: playMenuList);
                    }
                  }
                })
          ],
        ));
  }

  Widget buildMySingerItem(MuiscMySingerModel mySingerModel) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: ThemeSize.containerPadding),
      Row(
        children: [
          mySingerModel.avatar != null
              ? ClipOval(
                  child: Image.network(
                  mySingerModel.avatar!.contains("http")
                      ? mySingerModel.avatar!.replaceAll("{size}", "240")
                      : "$HOST${mySingerModel.avatar}",
                  width: ThemeSize.bigAvater,
                  height: ThemeSize.bigAvater,
                ))
              : Container(
                  width: ThemeSize.bigAvater,
                  height: ThemeSize.bigAvater,
                  //超出部分，可裁剪
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: ThemeColors.colorBg,
                    borderRadius: BorderRadius.circular(ThemeSize.bigAvater),
                  ),
                  child: Center(
                      child: Text(
                    mySingerModel.authorName.substring(0, 1),
                    style: TextStyle(fontSize: ThemeSize.bigFontSize),
                  ))),
          SizedBox(width: ThemeSize.containerPadding),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mySingerModel.authorName),
                SizedBox(height: ThemeSize.smallMargin),
                Text("${mySingerModel.total}首",
                    style: TextStyle(color: ThemeColors.subTitle))
              ],
            ),
          ),
          Image.asset(
            "lib/assets/images/icon_music_play.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          ),
          SizedBox(width: ThemeSize.containerPadding * 2),
          Image.asset(
            "lib/assets/images/icon_delete.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          ),
          SizedBox(width: ThemeSize.containerPadding * 2),
          Image.asset(
            "lib/assets/images/icon_music_menu.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          )
        ],
      )
    ]);
  }

  // 我关注的歌手
  Widget buildRecordList() {
    return Container(
        decoration: ThemeStyle.boxDecoration,
        margin: ThemeStyle.margin,
        width:
            MediaQuery.of(context).size.width - ThemeSize.containerPadding * 2,
        padding: ThemeStyle.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("lib/assets/images/icon_down.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
                SizedBox(width: ThemeSize.smallMargin),
                const Expanded(flex: 1, child: Text("最近播放的歌曲")),
                RotationTransition(
                    turns: _curveAnimation,
                    child: InkWell(
                      child: Image.asset(
                          "lib/assets/images/icon_music_refresh.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),
                      onTap: () {
                        _repeatController.forward();
                        _repeatController.repeat();
                        getMusicRecordService(1, 10).then((value) {
                          Future.delayed(const Duration(seconds: 1),(){
                            _repeatController.stop(canceled: false);
                          });
                          setState(() {
                            playRecordList = value.data;
                          });
                        });

                      },
                    ))
              ],
            ),
            Column(
              children: getRecordList(),
            )
            // FutureBuilder(
            //     future: getMusicRecordService(1, 10),
            //     builder: (context, snapshot) {
            //       if (snapshot.data == null) {
            //         return Container();
            //       } else {
            //         List<Widget> playMenuList = [];
            //         (snapshot.data["data"] as List).cast().forEach((item) {
            //           MusicModel musicModel = MusicModel.fromJson(item);
            //           playMenuList.add(buildRecordItem(musicModel));
            //         });
            //         if (playMenuList.length == 0) {
            //           return Container();
            //         } else {
            //           return Column(children: playMenuList);
            //         }
            //       }
            //     })
          ],
        ));
  }

  List<Widget> getRecordList() {
    return playRecordList.map((item) {
      MusicModel musicModel = MusicModel.fromJson(item);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: ThemeSize.containerPadding),
        Row(
          children: [
            ClipOval(
                child: Image.network(
              HOST + musicModel.cover,
              width: ThemeSize.bigAvater,
              height: ThemeSize.bigAvater,
            )),
            SizedBox(width: ThemeSize.containerPadding),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(musicModel.songName),
                  SizedBox(height: ThemeSize.smallMargin),
                  Text("听过${musicModel.times}次",
                      style: TextStyle(color: ThemeColors.subTitle))
                ],
              ),
            ),
            Image.asset(
              "lib/assets/images/icon_music_play.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
            SizedBox(width: ThemeSize.containerPadding * 2),
            Image.asset(
              "lib/assets/images/icon_delete.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
            SizedBox(width: ThemeSize.containerPadding * 2),
            Image.asset(
              "lib/assets/images/icon_music_menu.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            )
          ],
        )
      ]);
    }).toList();
  }
}
