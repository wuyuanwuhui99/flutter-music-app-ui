import 'dart:async';

import 'package:flutter/material.dart';
import '../router/index.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import './MusicHomePage.dart';
import './MusicRecommentPage.dart';
import './MusicCirclePage.dart';
import './MusicUserPage.dart';
import '../provider/PlayerMusicProvider.dart';
import '../model/MusicModel.dart';
import '../utils/LocalStorageUtils.dart';
import '../component/MusicAvaterComponent.dart';
import '../common/constant.dart';

class MusicIndexPage extends StatefulWidget {
  const MusicIndexPage({super.key});

  @override
  _MusicIndexPageState createState() => _MusicIndexPageState();
}

class _MusicIndexPageState extends State<MusicIndexPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  /// 会重复播放的控制器
  late AnimationController _repeatController;
  bool playing = false;

  /// 非线性动画
  late Animation<double> _curveAnimation;
  int _currentIndex = 0;
  List<Widget?> pages = [null, null, null, null];
  List<String> normalImgUrls = [
    "lib/assets/images/icon_home.png",
    "lib/assets/images/icon_recomment.png",
    "lib/assets/images/icon_music_circle.png",
    "lib/assets/images/icon_user.png"
  ];
  List<String> selectedImgUrls = [
    "lib/assets/images/icon_home_active.png",
    "lib/assets/images/icon_recomment_active.png",
    "lib/assets/images/icon_music_circle_active.png",
    "lib/assets/images/icon_user_active.png"
  ];
  List<String> titles = ["首页", "推荐", "音乐圈", "我的"];
  late MusicModel musicModel;
  late StreamSubscription onPlayerStateChangedListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  ///@author: wuwenqiang
  ///@description: 进入当前页面时
  ///@date: 2024-06-18 21:57
  @override
  void didPush() {
    super.didPush();
    onPlayerStateChangedListener?.resume(); // 恢复监听音乐播放进度
  }

  ///@author: wuwenqiang
  ///@description: 从其他页面返回当前页面走这里
  ///@date: 2024-06-18 21:57
  @override
  void didPopNext() {
    super.didPopNext();
    onPlayerStateChangedListener?.resume(); // 恢复监听音乐播放进度
  }

  ///@author: wuwenqiang
  ///@description: 退出当前页面，返回上一级页面
  ///@date: 2024-06-18 21:57
  @override
  void didPop() {
    super.didPop();
    onPlayerStateChangedListener.cancel(); // 取消监听音乐播放进度
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repeatController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 创建一个从0到360弧度的补间动画 v * 2 * π
    _curveAnimation =
        Tween<double>(begin: 0, end: 1).animate(_repeatController);
    _repeatController.stop(canceled: false);
    // usePlayState();
    useStorage();
  }

  useStorage() {
    PlayerMusicProvider provider =
        Provider.of<PlayerMusicProvider>(context, listen: false);
    LocalStorageUtils.getPlayMusic().then((value) {
      if (value != null) {
        provider.setPlayMusic(value, false);
      }
    });
    LocalStorageUtils.getLoopMode().then((value) {
      provider.setLoopMode(value);
    });
    LocalStorageUtils.getMusicList().then((value) {
      provider.setMusicList(value);
    });
  }

  /// 获取播放状态
  usePlayState() {
    AudioPlayer player =
        Provider.of<PlayerMusicProvider>(context, listen: false).player;
    onPlayerStateChangedListener = player.onPlayerStateChanged.listen((event) {
      if (event.index == 2) {
        // 暂停播放
        _repeatController.stop(canceled: false);
      } else {
        // 恢复播放
        _repeatController.forward();
        _repeatController.repeat();
      }
    });
  }

  final _pageController = PageController();

  Widget _getPage() {
    if (pages[_currentIndex] == null) {
      if (_currentIndex == 0) {
        pages[_currentIndex] = const MusicHomePage();
      } else if (_currentIndex == 1) {
        pages[_currentIndex] = const MusicRecommentPage();
      } else if (_currentIndex == 2) {
        pages[_currentIndex] = const MusicCirclePage();
      } else if (_currentIndex == 3) {
        pages[_currentIndex] = const MusicUserPage();
      }
    }
    return pages[_currentIndex]!;
  }

  Widget bottomAppBarItem(int index) {
    //设置默认未选中的状态
    TextStyle style = TextStyle(color: ThemeColors.grey);
    String imgUrl = normalImgUrls[index];
    if (_currentIndex == index) {
      //选中的话
      style = TextStyle(color: ThemeColors.orange);
      imgUrl = selectedImgUrls[index];
    }
    //构造返回的Widget
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: <Widget>[
          Image.asset(imgUrl,
              width: ThemeSize.middleIcon, height: ThemeSize.middleIcon),
          SizedBox(height: ThemeSize.smallMargin),
          Text(
            titles[index],
            style: style,
          )
        ],
      ),
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MusicModel? musicModel =
        Provider.of<PlayerMusicProvider>(context).musicModel;
    return Scaffold(
        backgroundColor: ThemeColors.colorBg,
        body: SafeArea(
            top: true,
            child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _pageChanged,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _getPage();
                })),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        //悬浮按钮
        floatingActionButton: SizedBox(
          height: ThemeSize.minPlayIcon,
          width: ThemeSize.minPlayIcon,
          child: musicModel != null
              ? InkWell(
                  child: RotationTransition(
                    turns: _curveAnimation,
                    child: MusicAvaterComponent(
                        type: 'music',
                        name: '',
                        avater: musicModel.cover,
                        size: ThemeSize.minPlayIcon),
                  ),
                  onTap: () {
                    Routes.router.navigateTo(context, '/MusicPlayerPage');
                  })
              : Icon(Icons.music_note,
                  color: ThemeColors.colorBg, size: ThemeSize.bigIcon),
        ),
        bottomNavigationBar: BottomAppBar(
            height: ThemeSize.bottomBarHeight,
            color: ThemeColors.colorWhite,
            shape: const CircularNotchedRectangle(),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  bottomAppBarItem(0),
                  bottomAppBarItem(1),
                  const SizedBox(width: 50),
                  bottomAppBarItem(2),
                  bottomAppBarItem(3)
                ])));
  }

  void _pageChanged(int index) {
    setState(() {
      if (_currentIndex != index) _currentIndex = index;
    });
  }

  void onTabTapped(int index) {
    _pageController.jumpToPage(index);
  }
}
