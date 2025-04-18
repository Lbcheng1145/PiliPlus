import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/interactiveviewer_gallery/interactiveviewer_gallery.dart';
import 'package:PiliPlus/common/widgets/radio_widget.dart';
import 'package:PiliPlus/grpc/app/main/community/reply/v1/reply.pb.dart';
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/main.dart';
import 'package:PiliPlus/models/bangumi/info.dart';
import 'package:PiliPlus/models/common/search_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/live/item.dart';
import 'package:PiliPlus/models/user/fav_folder.dart';
import 'package:PiliPlus/pages/common/multi_select_controller.dart';
import 'package:PiliPlus/pages/dynamics/tab/controller.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/pages/video/detail/introduction/widgets/fav_panel.dart';
import 'package:PiliPlus/pages/video/detail/introduction/widgets/group_panel.dart';
import 'package:PiliPlus/pages/video/detail/introduction/widgets/menu_row.dart';
import 'package:PiliPlus/services/shutdown_timer_service.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/url_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'package:uuid/v4.dart';

import '../models/home/rcmd/result.dart';
import '../models/model_rec_video_item.dart';
import '../models/model_video.dart';

class Utils {
  static final Random random = Random();

  static const channel = MethodChannel("PiliPlus");

  static final _numRegExp = RegExp(r'([\d\.]+)([千万亿])?');

  static Future pushDynFromId(id, {bool off = false}) async {
    SmartDialog.showLoading();
    dynamic res = await DynamicsHttp.dynamicDetail(id: id);
    SmartDialog.dismiss();
    if (res['status']) {
      DynamicItemModel data = res['data'];
      if (data.basic?['comment_type'] == 12) {
        Utils.toDupNamed(
          '/htmlRender',
          parameters: {
            'url': 'www.bilibili.com/opus/$id',
            'title': '',
            'id': id,
            'dynamicType': 'opus'
          },
          off: off,
        );
      } else {
        Utils.toDupNamed(
          '/dynamicDetail',
          arguments: {
            'item': res['data'],
            'floor': 1,
            'action': 'detail',
          },
          off: off,
        );
      }
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  static void reportVideo(int aid) {
    Get.toNamed(
      '/webview',
      parameters: {'url': 'https://www.bilibili.com/appeal/?avid=$aid'},
    );
  }

  /// 定时关闭
  static void scheduleExit(BuildContext context, isFullScreen,
      [bool isLive = false]) {
    if (!context.mounted) {
      return;
    }
    const List<int> scheduleTimeChoices = [0, 15, 30, 45, 60];
    const TextStyle titleStyle = TextStyle(fontSize: 14);
    if (isLive) {
      shutdownTimerService.waitForPlayingCompleted = false;
    }
    Utils.showFSSheet(
      context,
      isFullScreen: () => isFullScreen,
      child: StatefulBuilder(
        builder: (_, setState) {
          return Theme(
            data: Theme.of(context),
            child: Material(
              color: Colors.transparent,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.only(left: 14, right: 14),
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    const Center(child: Text('定时关闭', style: titleStyle)),
                    const SizedBox(height: 10),
                    ...[
                      ...[
                        ...scheduleTimeChoices,
                        if (scheduleTimeChoices
                            .contains(
                                shutdownTimerService.scheduledExitInMinutes)
                            .not)
                          shutdownTimerService.scheduledExitInMinutes,
                      ]..sort(),
                      -1,
                    ].map(
                      (choice) => ListTile(
                        dense: true,
                        onTap: () {
                          if (choice == -1) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                String duration = '';
                                return AlertDialog(
                                  title: const Text('自定义时长'),
                                  content: TextField(
                                    autofocus: true,
                                    onChanged: (value) => duration = value,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'\d+')),
                                    ],
                                    decoration: const InputDecoration(
                                        suffixText: 'min'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: Get.back,
                                      child: Text(
                                        '取消',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        int choice =
                                            int.tryParse(duration) ?? 0;
                                        shutdownTimerService
                                            .scheduledExitInMinutes = choice;
                                        shutdownTimerService
                                            .startShutdownTimer();
                                        setState(() {});
                                      },
                                      child: Text('确定'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            Get.back();
                            shutdownTimerService.scheduledExitInMinutes =
                                choice;
                            shutdownTimerService.startShutdownTimer();
                          }
                        },
                        contentPadding: const EdgeInsets.only(),
                        title: Text(choice == -1
                            ? '自定义'
                            : choice == 0
                                ? "禁用"
                                : "$choice分钟后"),
                        trailing: shutdownTimerService.scheduledExitInMinutes ==
                                choice
                            ? Icon(
                                Icons.done,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: SizedBox(
                        width: 125,
                        child: Divider(height: 1),
                      ),
                    ),
                    if (isLive.not) ...[
                      const SizedBox(height: 10),
                      ListTile(
                        dense: true,
                        onTap: () {
                          shutdownTimerService.waitForPlayingCompleted =
                              !shutdownTimerService.waitForPlayingCompleted;
                          setState(() {});
                        },
                        contentPadding: const EdgeInsets.only(),
                        title: const Text("额外等待视频播放完毕", style: titleStyle),
                        trailing: Transform.scale(
                          alignment: Alignment
                              .centerRight, // 缩放Switch的大小后保持右侧对齐, 避免右侧空隙过大
                          scale: 0.8,
                          child: Switch(
                            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                                (Set<WidgetState> states) {
                              if (states.isNotEmpty &&
                                  states.first == WidgetState.selected) {
                                return const Icon(Icons.done);
                              }
                              return null;
                            }),
                            value: shutdownTimerService.waitForPlayingCompleted,
                            onChanged: (value) => setState(() =>
                                shutdownTimerService.waitForPlayingCompleted =
                                    value),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('倒计时结束:', style: titleStyle),
                        const Spacer(),
                        ActionRowLineItem(
                          onTap: () {
                            shutdownTimerService.exitApp = false;
                            setState(() {});
                            // Get.back();
                          },
                          text: " 暂停视频 ",
                          selectStatus: !shutdownTimerService.exitApp,
                        ),
                        const Spacer(),
                        // const SizedBox(width: 10),
                        ActionRowLineItem(
                          onTap: () {
                            shutdownTimerService.exitApp = true;
                            setState(() {});
                            // Get.back();
                          },
                          text: " 退出APP ",
                          selectStatus: shutdownTimerService.exitApp,
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void enterPip(Floating floating, int width, int height) {
    Rational aspectRatio = Rational(width, height);
    floating.enable(
      EnableManual(
        aspectRatio: aspectRatio.fitsInAndroidRequirements
            ? aspectRatio
            : height > width
                ? const Rational.vertical()
                : const Rational.landscape(),
      ),
    );
  }

  static ThemeData getThemeData({
    required ColorScheme colorScheme,
    required bool isDynamic,
    bool isDark = false,
    required FlexSchemeVariant variant,
  }) {
    final appFontWeight =
        GStorage.appFontWeight.clamp(-1, FontWeight.values.length - 1);
    final fontWeight =
        appFontWeight == -1 ? null : FontWeight.values[appFontWeight];
    late final textStyle = TextStyle(fontWeight: fontWeight);
    ThemeData themeData = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: fontWeight == null
          ? null
          : TextTheme(
              displayLarge: textStyle,
              displayMedium: textStyle,
              displaySmall: textStyle,
              headlineLarge: textStyle,
              headlineMedium: textStyle,
              headlineSmall: textStyle,
              titleLarge: textStyle,
              titleMedium: textStyle,
              titleSmall: textStyle,
              bodyLarge: textStyle,
              bodyMedium: textStyle,
              bodySmall: textStyle,
              labelLarge: textStyle,
              labelMedium: textStyle,
              labelSmall: textStyle,
            ),
      tabBarTheme:
          fontWeight == null ? null : TabBarTheme(labelStyle: textStyle),
      appBarTheme: AppBarTheme(
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: isDynamic ? null : colorScheme.surface,
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
          fontWeight: fontWeight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        surfaceTintColor: isDynamic ? colorScheme.onSurfaceVariant : null,
      ),
      snackBarTheme: SnackBarThemeData(
        actionTextColor: colorScheme.primary,
        backgroundColor: colorScheme.secondaryContainer,
        closeIconColor: colorScheme.secondary,
        contentTextStyle: TextStyle(color: colorScheme.secondary),
        elevation: 20,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(
            allowEnterRouteSnapshotting: false,
          ),
        },
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: isDynamic ? colorScheme.onSurfaceVariant : null,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        surfaceTintColor: isDynamic
            ? colorScheme.onSurfaceVariant
            : isDark
                ? colorScheme.onSurfaceVariant
                : null,
        shadowColor: Colors.transparent,
      ),
      // dialogTheme: DialogTheme(
      //   surfaceTintColor: isDark ? colorScheme.onSurfaceVariant : null,
      // ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        refreshBackgroundColor: colorScheme.onSecondary,
      ),
      dialogTheme: DialogTheme(
        titleTextStyle: TextStyle(
          fontSize: 18,
          color: colorScheme.onSurface,
          fontWeight: fontWeight,
        ),
      ),
    );
    if (isDark && GStorage.isPureBlackTheme) {
      themeData = Utils.darkenTheme(themeData);
    }
    if (isDark && GStorage.darkVideoPage) {
      MyApp.darkThemeData = themeData;
    }
    return themeData;
  }

  static final regExp =
      RegExp(r'(@(\d+[a-z]_?)*)(\..*)?$', caseSensitive: false);

  static String thumbnailImgUrl(String? src, [int? quality]) {
    if (src != null && quality != 100) {
      bool hasMatch = false;
      src = src.splitMapJoin(
        regExp,
        onMatch: (Match match) {
          hasMatch = true;
          String suffix = match.group(3) ?? '.webp';
          return '${match.group(1)}_${quality ?? GlobalData().imgQuality}q$suffix';
        },
        onNonMatch: (String str) {
          return str;
        },
      );
      if (hasMatch.not) {
        src += '@${quality ?? GlobalData().imgQuality}q.webp';
      }
    }
    return src.http2https;
  }

  static bool? _isIpad;

  static FutureOr<bool> isIpad() async {
    if (Platform.isIOS.not) {
      return false;
    }
    if (_isIpad != null) {
      return _isIpad!;
    }
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo info = await deviceInfo.iosInfo;
    _isIpad = info.model.toLowerCase().contains("ipad");
    return _isIpad!;
  }

  static void shareText(String text) async {
    try {
      Rect? sharePositionOrigin;
      if (await isIpad()) {
        sharePositionOrigin = Rect.fromLTWH(0, 0, Get.width, Get.height / 2);
      }
      Share.share(
        text,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  static void toViewPage(
    String page, {
    dynamic arguments,
    int? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    bool off = false,
  }) {
    if (off) {
      Get.offNamed(
        '/videoV?$page',
        arguments: arguments,
        id: id,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
      );
    } else {
      Get.toNamed(
        '/videoV?$page',
        arguments: arguments,
        id: id,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
      );
    }
  }

  static Future insertCreatedDyn(result) async {
    try {
      dynamic id = result['data']['dyn_id'];
      if (id != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        dynamic res = await DynamicsHttp.dynamicDetail(id: id);
        if (res['status']) {
          final ctr = Get.find<DynamicsTabController>(tag: 'all');
          if (ctr.loadingState.value is Success) {
            List<DynamicItemModel>? list =
                (ctr.loadingState.value as Success).response;
            if (list != null) {
              list.insert(0, res['data']);
              ctr.loadingState.refresh();
              return;
            }
          }
          ctr.loadingState.value = LoadingState.success([res['data']]);
        }
      }
    } catch (e) {
      debugPrint('create dyn $e');
    }
  }

  static Future checkCreatedDyn({id, dynText, isManual}) async {
    if (isManual == true || GStorage.enableCreateDynAntifraud) {
      try {
        if (id != null) {
          if (isManual != true) {
            await Future.delayed(const Duration(seconds: 5));
          }
          dynamic res =
              await DynamicsHttp.dynamicDetail(id: id, clearCookie: true);
          showDialog(
            context: Get.context!,
            builder: (context) => AlertDialog(
              title: Text('动态检查结果'),
              content: SelectableText(
                  '${res['status'] ? '无账号状态下找到了你的动态，动态正常！' : '你的动态被shadow ban（仅自己可见）！'}${dynText != null ? ' \n\n动态内容: $dynText' : ''}'),
            ),
          );
        }
      } catch (e) {
        debugPrint('check dyn error: $e');
      }
    }
  }

  // 动态点赞
  static Future onLikeDynamic(item, VoidCallback callback) async {
    feedBack();
    String dynamicId = item.idStr!;
    // 1 已点赞 2 不喜欢 0 未操作
    item.modules?.moduleStat ??= ModuleStatModel();
    item.modules?.moduleStat.like ??= Like();
    Like like = item.modules.moduleStat.like;
    int count = like.count == '点赞' ? 0 : int.parse(like.count ?? '0');
    bool status = like.status ?? false;
    int up = status ? 2 : 1;
    var res = await DynamicsHttp.likeDynamic(dynamicId: dynamicId, up: up);
    if (res['status']) {
      SmartDialog.showToast(!status ? '点赞成功' : '取消赞');
      if (up == 1) {
        item.modules.moduleStat.like.count = (count + 1).toString();
        item.modules.moduleStat.like.status = true;
      } else {
        if (count == 1) {
          item.modules.moduleStat.like.count = '点赞';
        } else {
          item.modules.moduleStat.like.count = (count - 1).toString();
        }
        item.modules.moduleStat.like.status = false;
      }
      callback();
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  static void showFSSheet(
    BuildContext context, {
    required Widget child,
    required Function isFullScreen,
    double? padding,
  }) {
    if (!context.mounted) {
      return;
    }
    Get.generalDialog(
      barrierLabel: '',
      barrierDismissible: true,
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        return MediaQuery.orientationOf(Get.context!) == Orientation.portrait
            ? SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Expanded(flex: 7, child: child),
                    if (isFullScreen() && padding != null)
                      SizedBox(height: padding),
                  ],
                ),
              )
            : SafeArea(
                child: Row(
                  children: [
                    const Spacer(),
                    Expanded(child: child),
                  ],
                ),
              );
      },
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin =
            MediaQuery.orientationOf(Get.context!) == Orientation.portrait
                ? Offset(0.0, 1.0)
                : Offset(1.0, 0.0);
        var tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      routeSettings: RouteSettings(arguments: Get.arguments),
    );
  }

  static darkenTheme(ThemeData themeData) {
    // return themeData;
    Color color = themeData.colorScheme.surfaceContainerHighest.darken(0.7);
    return themeData.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: themeData.appBarTheme.copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: themeData.cardTheme.copyWith(
        color: Colors.black,
      ),
      dialogTheme: themeData.dialogTheme.copyWith(
        backgroundColor: color,
      ),
      bottomSheetTheme:
          themeData.bottomSheetTheme.copyWith(backgroundColor: color),
      bottomNavigationBarTheme:
          themeData.bottomNavigationBarTheme.copyWith(backgroundColor: color),
      navigationBarTheme:
          themeData.navigationBarTheme.copyWith(backgroundColor: color),
      navigationRailTheme:
          themeData.navigationRailTheme.copyWith(backgroundColor: Colors.black),
      colorScheme: themeData.colorScheme.copyWith(
        primary: themeData.colorScheme.primary.darken(0.1),
        onPrimary: themeData.colorScheme.onPrimary.darken(0.1),
        primaryContainer: themeData.colorScheme.primaryContainer.darken(0.1),
        onPrimaryContainer:
            themeData.colorScheme.onPrimaryContainer.darken(0.1),
        inversePrimary: themeData.colorScheme.inversePrimary.darken(0.1),
        secondary: themeData.colorScheme.secondary.darken(0.1),
        onSecondary: themeData.colorScheme.onSecondary.darken(0.1),
        secondaryContainer:
            themeData.colorScheme.secondaryContainer.darken(0.1),
        onSecondaryContainer:
            themeData.colorScheme.onSecondaryContainer.darken(0.1),
        error: themeData.colorScheme.error.darken(0.1),
        surface: Colors.black,
        onSurface: themeData.colorScheme.onSurface.darken(0.15),
        surfaceTint: themeData.colorScheme.surfaceTint.darken(),
        inverseSurface: themeData.colorScheme.inverseSurface.darken(),
        onInverseSurface: themeData.colorScheme.onInverseSurface.darken(),
        surfaceContainer: themeData.colorScheme.surfaceContainer.darken(),
        surfaceContainerHigh:
            themeData.colorScheme.surfaceContainerHigh.darken(),
        surfaceContainerHighest:
            themeData.colorScheme.surfaceContainerHighest.darken(0.4),
      ),
    );
  }

  static void onCopyOrMove<R, T extends MultiSelectData>({
    required BuildContext context,
    required bool isCopy,
    required MultiSelectController<R, T> ctr,
    required dynamic mediaId,
    required dynamic mid,
  }) {
    VideoHttp.allFavFolders(mid).then((res) {
      if (context.mounted &&
          res['status'] &&
          (res['data'].list as List?)?.isNotEmpty == true) {
        List<FavFolderItemData> list = res['data'].list;
        dynamic checkedId;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${isCopy ? '复制' : '移动'}到'),
              contentPadding: const EdgeInsets.only(top: 5),
              content: SingleChildScrollView(
                child: Builder(
                  builder: (context) => Column(
                    children: List.generate(list.length, (index) {
                      return RadioWidget(
                        padding: const EdgeInsets.only(left: 14),
                        title: list[index].title ?? '',
                        groupValue: checkedId,
                        value: list[index].id,
                        onChanged: (value) {
                          checkedId = value;
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      );
                    }),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: Get.back,
                  child: Text(
                    '取消',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (checkedId != null) {
                      List resources = ((ctr.loadingState.value as Success)
                              .response as List<T>)
                          .where((e) => e.checked == true)
                          .toList();
                      SmartDialog.showLoading();
                      VideoHttp.copyOrMoveFav(
                        isCopy: isCopy,
                        isFav: ctr is! LaterController,
                        srcMediaId: mediaId,
                        tarMediaId: checkedId,
                        resources: resources
                            .map((item) => ctr is LaterController
                                ? item.aid
                                : '${item.id}:${item.type}')
                            .toList(),
                        mid: isCopy ? mid : null,
                      ).then((res) {
                        if (res['status']) {
                          ctr.handleSelect(false);
                          if (isCopy.not) {
                            List<T> dataList =
                                (ctr.loadingState.value as Success).response;
                            List<T> remainList = dataList
                                .toSet()
                                .difference(resources.toSet())
                                .toList();
                            ctr.loadingState.value =
                                LoadingState.success(remainList);
                          }
                          SmartDialog.dismiss();
                          SmartDialog.showToast('${isCopy ? '复制' : '移动'}成功');
                          Get.back();
                        } else {
                          SmartDialog.dismiss();
                          SmartDialog.showToast('${res['msg']}');
                        }
                      });
                    }
                  },
                  child: Text('确认'),
                ),
              ],
            );
          },
        );
      } else {
        SmartDialog.showToast('${res['msg']}');
      }
    });
  }

  static void showFavBottomSheet({
    required BuildContext context,
    required dynamic ctr,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      sheetAnimationStyle: AnimationStyle(curve: Curves.ease),
      constraints: BoxConstraints(
        maxWidth: min(640, min(Get.width, Get.height)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          minChildSize: 0,
          maxChildSize: 1,
          initialChildSize: 0.7,
          snap: true,
          expand: false,
          snapSizes: const [0.7],
          builder: (BuildContext context, ScrollController scrollController) {
            return FavPanel(
              ctr: ctr,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  static String buildShadersAbsolutePath(
      String baseDirectory, List<String> shaders) {
    List<String> absolutePaths = shaders.map((shader) {
      return path.join(baseDirectory, shader);
    }).toList();
    return absolutePaths.join(':');
  }

  static void pushDynDetail(item, floor, {action = 'all'}) async {
    feedBack();

    /// 点击评论action 直接查看评论
    if (action == 'comment') {
      Utils.toDupNamed(
        '/dynamicDetail',
        arguments: {
          'item': item,
          'floor': floor,
          'action': action,
        },
      );
      return;
    }

    debugPrint('pushDynDetail: ${item.type}');

    switch (item.type) {
      case 'DYNAMIC_TYPE_AV':
        if (item.modules.moduleDynamic.major.archive?.type == 2) {
          if (item.modules.moduleDynamic.major.archive.jumpUrl
              .startsWith('//')) {
            item.modules.moduleDynamic.major.archive.jumpUrl =
                'https:${item.modules.moduleDynamic.major.archive.jumpUrl}';
          }
          String? redirectUrl = await UrlUtils.parseRedirectUrl(
              item.modules.moduleDynamic.major.archive.jumpUrl, false);
          if (redirectUrl != null) {
            Utils.viewPgcFromUri(redirectUrl);
            return;
          }
        }

        try {
          String bvid = item.modules.moduleDynamic.major.archive.bvid;
          String cover = item.modules.moduleDynamic.major.archive.cover;
          int cid = await SearchHttp.ab2c(bvid: bvid);
          Utils.toViewPage(
            'bvid=$bvid&cid=$cid',
            arguments: {
              'pic': cover,
              'heroTag': Utils.makeHeroTag(bvid),
            },
            preventDuplicates: false,
          );
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;

      /// 专栏文章查看
      case 'DYNAMIC_TYPE_ARTICLE':
        String? url = item?.modules?.moduleDynamic?.major?.opus?.jumpUrl;
        if (url != null) {
          String? title = item?.modules?.moduleDynamic?.major?.opus?.title;
          if (url.contains('opus') || url.contains('read')) {
            RegExp digitRegExp = RegExp(r'\d+');
            Iterable<Match> matches = digitRegExp.allMatches(url);
            String number = matches.first.group(0)!;
            if (url.contains('read')) {
              number = 'cv$number';
            }
            Utils.toDupNamed('/htmlRender', parameters: {
              'url': url.startsWith('//') ? url.split('//').last : url,
              'title': title ?? '',
              'id': number,
              'dynamicType': url.split('//').last.split('/')[1]
            });
          } else {
            Utils.handleWebview('https:$url');
          }
        }

        break;
      case 'DYNAMIC_TYPE_PGC':
        debugPrint('番剧');
        SmartDialog.showToast('暂未支持的类型，请联系开发者');
        break;

      case 'DYNAMIC_TYPE_LIVE_RCMD':
        DynamicLiveModel liveRcmd = item.modules.moduleDynamic.major.liveRcmd;
        ModuleAuthorModel author = item.modules.moduleAuthor;
        LiveItemModel liveItem = LiveItemModel.fromJson({
          'title': liveRcmd.title,
          'uname': author.name,
          'cover': liveRcmd.cover,
          'mid': author.mid,
          'face': author.face,
          'roomid': liveRcmd.roomId,
          'watched_show': liveRcmd.watchedShow,
        });
        Utils.toDupNamed('/liveRoom?roomid=${liveItem.roomId}');
        break;

      /// 合集查看
      case 'DYNAMIC_TYPE_UGC_SEASON':
        DynamicArchiveModel ugcSeason =
            item.modules.moduleDynamic.major.ugcSeason;
        int aid = ugcSeason.aid!;
        String bvid = IdUtils.av2bv(aid);
        String cover = ugcSeason.cover!;
        int cid = await SearchHttp.ab2c(bvid: bvid);
        Utils.toViewPage(
          'bvid=$bvid&cid=$cid',
          arguments: {
            'pic': cover,
            'heroTag': Utils.makeHeroTag(bvid),
          },
          preventDuplicates: false,
        );
        break;

      /// 番剧查看
      case 'DYNAMIC_TYPE_PGC_UNION':
        debugPrint('DYNAMIC_TYPE_PGC_UNION 番剧');
        DynamicArchiveModel pgc = item.modules.moduleDynamic.major.pgc;
        if (pgc.epid != null) {
          Utils.viewBangumi(epId: pgc.epid);
        }
        break;
      case 'DYNAMIC_TYPE_MEDIALIST':
        if (item.modules?.moduleDynamic?.major?.medialist != null) {
          final String? url =
              item.modules.moduleDynamic.major.medialist['jump_url'];
          if (url?.contains('medialist/detail/ml') == true) {
            Get.toNamed(
              '/favDetail',
              parameters: {
                'heroTag':
                    '${item.modules.moduleDynamic.major.medialist['cover']}',
                'mediaId':
                    '${item.modules.moduleDynamic.major.medialist['id']}',
              },
            );
          } else if (url != null) {
            handleWebview(url.http2https);
          }
        }
        break;

      // 纯文字动态查看
      // case 'DYNAMIC_TYPE_WORD':
      // # 装扮/剧集点评/普通分享
      // case 'DYNAMIC_TYPE_COMMON_SQUARE':
      // 转发的动态
      // case 'DYNAMIC_TYPE_FORWARD':
      // 图文动态查看
      // case 'DYNAMIC_TYPE_DRAW':
      default:
        Utils.toDupNamed(
          '/dynamicDetail',
          arguments: {
            'item': item,
            'floor': floor,
          },
        );
        break;
    }
  }

  static void onHorizontalPreview(
    GlobalKey<ScaffoldState> key,
    transitionAnimationController,
    ctr,
    List<String> imgList,
    index,
    onClose,
  ) {
    key.currentState?.showBottomSheet(
      (context) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(ctr),
          child: InteractiveviewerGallery(
            sources: imgList.map((url) => SourceModel(url: url)).toList(),
            initIndex: index,
            setStatusBar: false,
            onClose: onClose,
          ),
        );
      },
      enableDrag: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      transitionAnimationController: transitionAnimationController,
      sheetAnimationStyle: AnimationStyle(duration: Duration.zero),
    );
  }

  static void inAppWebview(
    String url, {
    bool off = false,
  }) {
    if (GStorage.openInBrowser) {
      launchURL(url);
    } else {
      if (off) {
        Get.offNamed(
          '/webview',
          parameters: {'url': url},
          arguments: {'inApp': true},
        );
      } else {
        Get.toNamed(
          '/webview',
          parameters: {'url': url},
          arguments: {'inApp': true},
        );
      }
    }
  }

  static void handleWebview(
    String url, {
    bool off = false,
    bool inApp = false,
    Map? parameters,
  }) async {
    if (inApp.not && GStorage.openInBrowser) {
      if ((await PiliScheme.routePushFromUrl(url, selfHandle: true)).not) {
        launchURL(url);
      }
    } else {
      if (off) {
        Get.offNamed(
          '/webview',
          parameters: {
            'url': url,
            if (parameters != null) ...parameters,
          },
        );
      } else {
        PiliScheme.routePushFromUrl(url, parameters: parameters);
      }
    }
  }

  static bool viewPgcFromUri(String uri) {
    String? id = RegExp(r'(ep|ss)\d+').firstMatch(uri)?.group(0);
    if (id != null) {
      bool isSeason = id.startsWith('ss');
      id = id.substring(2);
      Utils.viewBangumi(
        seasonId: isSeason ? id : null,
        epId: isSeason ? null : id,
      );
      return true;
    }
    return false;
  }

  static void showCopyTextDialog(text) {
    Get.dialog(
      AlertDialog(
        content: SelectableText('$text'),
      ),
    );
  }

  static Future<dynamic> getWwebid(mid) async {
    try {
      dynamic response = await Request().get(
        '${HttpString.spaceBaseUrl}/$mid/dynamic',
        options: Options(
          extra: {'account': AnonymousAccount()},
        ),
      );
      dom.Document document = html_parser.parse(response.data);
      dom.Element? scriptElement =
          document.querySelector('script#__RENDER_DATA__');
      return jsonDecode(
          Uri.decodeComponent(scriptElement?.text ?? ''))['access_id'];
    } catch (e) {
      debugPrint('failed to get wwebid: $e');
      return null;
    }
  }

  static bool isStringNumeric(str) {
    RegExp numericRegex = RegExp(r'^[\d\.]+$');
    return numericRegex.hasMatch(str.toString());
  }

  static ReplyInfo replyCast(res) {
    Map? emote = res['content']['emote'];
    emote?.forEach((key, value) {
      value['size'] = value['meta']['size'];
    });
    return ReplyInfo.create()
      ..mergeFromProto3Json(
        res
          ..['id'] = res['rpid']
          ..['member']['name'] = res['member']['uname']
          ..['member']['face'] = res['member']['avatar']
          ..['member']['level'] = res['member']['level_info']['current_level']
          ..['member']['vipStatus'] = res['member']['vip']['vipStatus']
          ..['member']['vipType'] = res['member']['vip']['vipType']
          ..['member']['officialVerifyType'] =
              res['member']['official_verify']['type']
          ..['content']['emote'] = emote,
        ignoreUnknownFields: true,
      );
  }

  static bool isDefault(int attr) {
    return (attr & 2) == 0;
  }

  static String isPublicText(int attr) {
    return isPublic(attr) ? '公开' : '私密';
  }

  static bool isPublic(int attr) {
    return (attr & 1) == 0;
  }

  static Future actionRelationMod({
    required BuildContext context,
    required dynamic mid,
    required bool isFollow,
    required ValueChanged? callback,
    Map? followStatus,
  }) async {
    if (mid == null) {
      return;
    }
    feedBack();
    if (!isFollow) {
      var res = await VideoHttp.relationMod(
        mid: mid,
        act: 1,
        reSrc: 11,
      );
      SmartDialog.showToast(res['status'] ? "关注成功" : res['msg']);
      if (res['status']) {
        callback?.call(2);
      }
    } else {
      if (followStatus == null) {
        Map<String, dynamic> result = await UserHttp.hasFollow(mid);
        if (result['status']) {
          followStatus = result['data'];
        } else {
          SmartDialog.showToast(result['msg']);
          return;
        }
      }
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            bool isSpecialFollowed = followStatus!['special'] == 1;
            String text = isSpecialFollowed ? '移除特别关注' : '加入特别关注';
            return AlertDialog(
              clipBehavior: Clip.hardEdge,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    dense: true,
                    onTap: () async {
                      Get.back();
                      final res = await MemberHttp.specialAction(
                        fid: mid,
                        isAdd: !isSpecialFollowed,
                      );
                      if (res['status']) {
                        SmartDialog.showToast('$text成功');
                        callback?.call(2);
                      } else {
                        SmartDialog.showToast(res['msg']);
                      }
                    },
                    title: Text(
                      text,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    onTap: () async {
                      Get.back();
                      var result = await showModalBottomSheet<List?>(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        sheetAnimationStyle: AnimationStyle(curve: Curves.ease),
                        constraints: BoxConstraints(
                          maxWidth: min(640, min(Get.width, Get.height)),
                        ),
                        builder: (BuildContext context) {
                          return DraggableScrollableSheet(
                            minChildSize: 0,
                            maxChildSize: 1,
                            initialChildSize: 0.7,
                            snap: true,
                            expand: false,
                            snapSizes: const [0.7],
                            builder: (BuildContext context,
                                ScrollController scrollController) {
                              return GroupPanel(
                                mid: mid,
                                tags: followStatus!['tag'],
                                scrollController: scrollController,
                              );
                            },
                          );
                        },
                      );
                      followStatus!['tag'] = result;
                      if (result != null) {
                        callback?.call(2);
                      }
                    },
                    title: const Text(
                      '设置分组',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    onTap: () async {
                      Get.back();
                      var res = await VideoHttp.relationMod(
                        mid: mid,
                        act: 2,
                        reSrc: 11,
                      );
                      SmartDialog.showToast(
                          res['status'] ? "取消关注成功" : res['msg']);
                      if (res['status']) {
                        callback?.call(0);
                      }
                    },
                    title: const Text(
                      '取消关注',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }

  static String generateRandomString(int length) {
    const characters = '0123456789abcdefghijklmnopqrstuvwxyz';

    return String.fromCharCodes(Iterable.generate(length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  static String genAuroraEid(int uid) {
    if (uid == 0) {
      return ''; // Return null for a UID of 0
    }

    // 1. Convert UID to a byte array.
    var midByte = utf8.encode(uid.toString());

    // 2. XOR each byte with the corresponding byte from the key.
    const key = 'ad1va46a7lza';
    for (int i = 0; i < midByte.length; i++) {
      midByte[i] ^= key.codeUnitAt(i % key.length);
    }

    // 3. Perform Base64 encoding without padding.
    String base64Encoded =
        base64.encode(midByte).replaceAll('=', ''); // Remove padding

    // Return the resulting x-bili-aurora-eid.
    return base64Encoded;
  }

  // static String genRandomString(int length) {
  //   const characters = '0123456789abcdefghijklmnopqrstuvwxyz';
  //   Random random = Random();
  //   return List.generate(
  //           length, (index) => characters[random.nextInt(characters.length)])
  //       .join();
  // }

  static String genTraceId() {
    String randomId = generateRandomString(32);

    StringBuffer randomTraceId = StringBuffer(randomId.substring(0, 24));

    int ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (int i = 2; i >= 0; i--) {
      ts >>= 8;
      randomTraceId.write((ts & 0xFF).toRadixString(16).padLeft(2, '0'));
    }

    randomTraceId.write(randomId.substring(30, 32));

    return '${randomTraceId.toString()}:${randomTraceId.toString().substring(16, 32)}:0:0';
  }

  static void viewBangumi(
      {dynamic seasonId, dynamic epId, dynamic progress}) async {
    try {
      SmartDialog.showLoading(msg: '资源获取中');
      var result = await SearchHttp.bangumiInfo(seasonId: seasonId, epId: epId);
      SmartDialog.dismiss();
      if (result['status']) {
        BangumiInfoModel data = result['data'];

        // epId episode -> progress episode -> first episode
        EpisodeItem? episode;

        if (epId != null) {
          if (data.episodes?.isNotEmpty == true) {
            episode = data.episodes!.firstWhereOrNull(
              (item) {
                return item.epId.toString() == epId.toString();
              },
            );
          }
          if (episode == null && data.section?.isNotEmpty == true) {
            for (Section item in data.section!) {
              if (item.episodes?.isNotEmpty == true) {
                for (EpisodeItem item in item.episodes!) {
                  if (item.epId.toString() == epId.toString()) {
                    // view as normal video
                    Utils.toViewPage(
                      'bvid=${item.bvid}&cid=${item.cid}&seasonId=${data.seasonId}&epId=${item.epId}',
                      arguments: {
                        'pgcApi': true,
                        'pic': item.cover,
                        'heroTag': Utils.makeHeroTag(item.cid),
                        'videoType': SearchType.video,
                        if (progress != null) 'progress': int.tryParse(progress)
                      },
                      preventDuplicates: false,
                    );
                    return;
                  }
                }
              }
            }
          }
        }

        if (data.episodes.isNullOrEmpty) {
          SmartDialog.showToast('资源加载失败');
          return;
        }

        episode ??= data.userStatus?.progress?.lastEpId != null
            ? data.episodes!.firstWhereOrNull(
                  (item) => item.epId == data.userStatus?.progress?.lastEpId,
                ) ??
                data.episodes!.first
            : data.episodes!.first;
        Utils.toViewPage(
          'bvid=${episode.bvid}&cid=${episode.cid}&seasonId=${data.seasonId}&epId=${episode.epId}&type=${data.type}',
          arguments: {
            'pic': episode.cover,
            'heroTag': Utils.makeHeroTag(episode.cid),
            'videoType': SearchType.media_bangumi,
            'bangumiItem': data,
            if (progress != null) 'progress': int.tryParse(progress)
          },
          preventDuplicates: false,
        );
      } else {
        SmartDialog.showToast(result['msg']);
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('$e');
      debugPrint('$e');
    }
  }

  static void toDupNamed(
    String page, {
    dynamic arguments,
    Map<String, String>? parameters,
    bool off = false,
  }) {
    if (off) {
      Get.offNamed(
        page,
        arguments: arguments,
        parameters: parameters,
        preventDuplicates: false,
      );
    } else {
      Get.toNamed(
        page,
        arguments: arguments,
        parameters: parameters,
        preventDuplicates: false,
      );
    }
  }

  static Future copyText(
    String text, {
    bool needToast = true,
    String? toastText,
  }) async {
    Clipboard.setData(ClipboardData(text: text));
    if (needToast) {
      SmartDialog.showToast(toastText ?? '已复制');
    }
  }

  static launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        SmartDialog.showToast('Could not launch $url');
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  // static Future<String> getCookiePath() async {
  //   final Directory tempDir = await getApplicationSupportDirectory();
  //   final String tempPath = "${tempDir.path}/.plpl/";
  //   final Directory dir = Directory(tempPath);
  //   final bool b = await dir.exists();
  //   if (!b) {
  //     dir.createSync(recursive: true);
  //   }
  //   return tempPath;
  // }

  static int getUnit(String? unit) {
    switch (unit) {
      case '千':
        return 1000;
      case '万':
        return 10000;
      case '亿':
        return 100000000;
      default:
        return 1;
    }
  }

  static int parseNum(String numberStr) {
    if (numberStr == '-') return 0;
    try {
      final match = _numRegExp.firstMatch(numberStr)!;
      var number = double.parse(match.group(1)!);
      number *= getUnit(match.group(2));
      return number.toInt();
    } catch (e) {
      debugPrint('parse failed: "$numberStr" : $e');
      return 0;
    }
  }

  static String numFormat(dynamic number) {
    if (number == null) {
      return '00:00';
    }
    if (number is String) {
      number = int.tryParse(number) ?? number;
      if (number is String) {
        return number;
      }
    }

    String format(first, second) {
      double result = ((number / first) as double).toPrecision(1);
      int intRes = result.toInt();
      if (result == intRes) {
        return '$intRes$second';
      } else {
        return '$result$second';
      }
    }

    if (number >= 100000000) {
      return format(100000000, '亿');
    } else if (number >= 10000) {
      return format(10000, '万');
    } else {
      return number.toString();
    }
  }

  static String durationReadFormat(String duration) {
    List<String> durationParts = duration.split(':');

    if (durationParts.length == 3) {
      if (durationParts[0] != '00') {
        return '${int.parse(durationParts[0])}小时${durationParts[1]}分钟${durationParts[2]}秒';
      }
      durationParts.removeAt(0);
    }
    if (durationParts.length == 2) {
      if (durationParts[0] != '00') {
        return '${int.parse(durationParts[0])}分钟${durationParts[1]}秒';
      }
      durationParts.removeAt(0);
    }
    return '${int.parse(durationParts[0])}秒';
  }

  static String videoItemSemantics(BaseVideoItemModel videoItem) {
    StringBuffer semanticsLabel = StringBuffer();
    bool emptyStatCheck(int? stat) {
      return stat == null || stat <= 0;
    }

    if (videoItem is RecVideoItemAppModel) {
      if (videoItem.goto == 'picture') {
        semanticsLabel.write('动态,');
      } else if (videoItem.goto == 'bangumi') {
        semanticsLabel.write('番剧,');
      }
    }
    semanticsLabel.write(videoItem.title);

    if (!emptyStatCheck(videoItem.stat.view)) {
      semanticsLabel.write(',${Utils.numFormat(videoItem.stat.view)}');
      semanticsLabel.write(
          (videoItem is RecVideoItemAppModel && videoItem.goto == 'picture')
              ? '浏览'
              : '播放');
    }
    if (!emptyStatCheck(videoItem.stat.danmu)) {
      semanticsLabel.write(',${Utils.numFormat(videoItem.stat.danmu)}弹幕');
    }
    if ((videoItem is BaseRecVideoItemModel) && videoItem.rcmdReason != null) {
      semanticsLabel.write(',${videoItem.rcmdReason}');
    }
    if (!emptyStatCheck(videoItem.duration) && videoItem.duration > 0) {
      semanticsLabel.write(
          ',时长${Utils.durationReadFormat(Utils.timeFormat(videoItem.duration))}');
    }
    if (videoItem.pubdate != null) {
      semanticsLabel
          .write(',${Utils.dateFormat(videoItem.pubdate!, formatType: 'day')}');
    }
    if (videoItem.owner.name != '') {
      semanticsLabel.write(',Up主：${videoItem.owner.name}');
    }
    if (videoItem is BaseRecVideoItemModel && videoItem.isFollowed) {
      semanticsLabel.write(',已关注');
    }
    return semanticsLabel.toString();
  }

  static String timeFormat(dynamic time) {
    if (time is String && time.contains(':')) {
      return time;
    }
    if (time == null || time == 0) {
      return '00:00';
    }
    return formatDuration(time);
  }

  static String shortenChineseDateString(String date) {
    return date.contains("年")
        ? RegExp(r'\d+')
            .allMatches(date)
            .map((match) => match.group(0)?.length == 4
                ? match.group(0)!.substring(2)
                : match.group(0))
            .join('-')
        : date;
    // if (date.contains("年")) return '${date.split("年").first}年';
    // return date;
  }

  // 完全相对时间显示
  static String formatTimestampToRelativeTime(timeStamp) {
    var difference = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000));

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}年前';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 时间显示，刚刚，x分钟前
  static String dateFormat(timeStamp, {formatType = 'list'}) {
    if (timeStamp == null || timeStamp == 0 || timeStamp == '') {
      return '';
    }
    // 当前时间
    int time = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    // 对比
    int distance = (time - timeStamp).toInt();
    // 当前年日期
    String currentYearStr = 'MM月DD日 hh:mm';
    String lastYearStr = 'YY年MM月DD日 hh:mm';
    if (formatType == 'detail') {
      currentYearStr = 'MM-DD hh:mm';
      lastYearStr = 'YY-MM-DD hh:mm';
      return customStampStr(
          timestamp: timeStamp, date: lastYearStr, toInt: false);
    } else if (formatType == 'day') {
      if (distance <= 43200) {
        return customStampStr(
          timestamp: timeStamp,
          date: 'hh:mm',
          toInt: true,
        );
      }
      return customStampStr(
        timestamp: timeStamp,
        date: 'YY-MM-DD',
        toInt: true,
      );
    }
    if (distance <= 60) {
      return '刚刚';
    } else if (distance <= 3600) {
      return '${(distance / 60).floor()}分钟前';
    } else if (distance <= 43200) {
      return '${(distance / 60 / 60).floor()}小时前';
    } else if (DateTime.fromMillisecondsSinceEpoch(time * 1000).year ==
        DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000).year) {
      return customStampStr(
          timestamp: timeStamp, date: currentYearStr, toInt: false);
    } else {
      return customStampStr(
          timestamp: timeStamp, date: lastYearStr, toInt: false);
    }
  }

  // 时间戳转时间
  static String customStampStr({
    int? timestamp, // 为空则显示当前时间
    String? date, // 显示格式，比如：'YY年MM月DD日 hh:mm:ss'
    bool toInt = true, // 去除0开头
  }) {
    timestamp ??= (DateTime.now().millisecondsSinceEpoch / 1000).round();
    String timeStr =
        (DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)).toString();

    dynamic dateArr = timeStr.split(' ')[0];
    dynamic timeArr = timeStr.split(' ')[1];

    // ignore: non_constant_identifier_names
    String YY = dateArr.split('-')[0];
    // ignore: non_constant_identifier_names
    String MM = dateArr.split('-')[1];
    // ignore: non_constant_identifier_names
    String DD = dateArr.split('-')[2];

    String hh = timeArr.split(':')[0];
    String mm = timeArr.split(':')[1];
    String ss = timeArr.split(':')[2];

    ss = ss.split('.')[0];

    // 去除0开头
    if (toInt) {
      MM = (int.parse(MM)).toString();
      DD = (int.parse(DD)).toString();
      hh = (int.parse(hh)).toString();
      // mm = (int.parse(mm)).toString();
    }

    if (date == null) {
      return timeStr;
    }

    date = date
        .replaceAll('YY', YY)
        .replaceAll('MM', MM)
        .replaceAll('DD', DD)
        .replaceAll('hh', hh)
        .replaceAll('mm', mm)
        .replaceAll('ss', ss);
    // if (int.parse(YY) == DateTime.now().year &&
    //     int.parse(MM) == DateTime.now().month) {
    //   // 当天
    //   if (int.parse(DD) == DateTime.now().day) {
    //     return '今天';
    //   }
    // }
    return date;
  }

  static String makeHeroTag(v) {
    return v.toString() + random.nextInt(9999).toString();
  }

  static String formatDuration(num seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    num remainingSeconds = seconds % 60;
    if (remainingSeconds is double) {
      remainingSeconds = remainingSeconds.toPrecision(3);
    }

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    if (hours > 0) {
      String hoursStr = hours.toString().padLeft(2, '0');
      return "$hoursStr:$minutesStr:$secondsStr";
    } else {
      return "$minutesStr:$secondsStr";
    }
  }

  static int duration(String duration) {
    List timeList = duration.split(':');
    int len = timeList.length;
    if (len == 2) {
      return int.parse(timeList[0]) * 60 + int.parse(timeList[1]);
    }
    if (len == 3) {
      return int.parse(timeList[0]) * 3600 +
          int.parse(timeList[1]) * 60 +
          int.parse(timeList[2]);
    }
    return 0;
  }

  static int findClosestNumber(int target, List<int> numbers) {
    List<int> filterNums = numbers.where((number) => number <= target).toList();
    return filterNums.isNotEmpty
        ? filterNums.reduce((a, b) => a > b ? a : b)
        : numbers.reduce((a, b) => a > b ? b : a);
  }

  // 检查更新
  static Future checkUpdate([bool isAuto = true]) async {
    if (BuildConfig.isDebug) return;
    SmartDialog.dismiss();
    try {
      dynamic res = await Request().get(Api.latestApp, extra: {'ua': 'mob'});
      if (res.data.isEmpty) {
        if (isAuto.not) {
          SmartDialog.showToast('检查更新失败，GitHub接口未返回数据，请检查网络');
        }
        return;
      }
      DateTime latest = DateTime.parse(res.data[0]['created_at']);
      DateTime current = DateTime.parse('${BuildConfig.buildTime}Z');
      current = current.copyWith(hour: current.hour - 8);
      if (current.compareTo(latest) >= 0) {
        if (isAuto.not) {
          SmartDialog.showToast('已是最新版本');
        }
      } else {
        SmartDialog.show(
          animationType: SmartAnimationType.centerFade_otherSlide,
          builder: (context) {
            return AlertDialog(
              title: const Text('🎉 发现新版本 '),
              content: SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${res.data[0]['tag_name']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('${res.data[0]['body']}'),
                      TextButton(
                        onPressed: () {
                          launchURL(
                              'https://github.com/bggRGjQaUbCoE/PiliPlus/commits/main');
                        },
                        child: Text(
                          "点此查看完整更新(即commit)内容",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    SmartDialog.dismiss();
                    GStorage.setting.put(SettingBoxKey.autoUpdate, false);
                  },
                  child: Text(
                    '不再提醒',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: SmartDialog.dismiss,
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onDownload(res.data[0]);
                  },
                  child: const Text('Github'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('failed to check update: $e');
    }
  }

  // 下载适用于当前系统的安装包
  static Future onDownload(data) async {
    await SmartDialog.dismiss();
    try {
      void download(plat) {
        if (data['assets'].isNotEmpty) {
          for (dynamic i in data['assets']) {
            if (i['name'].contains(plat)) {
              launchURL(i['browser_download_url']);
              break;
            }
          }
        }
      }

      if (Platform.isAndroid) {
        // 获取设备信息
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        // [arm64-v8a]
        download(androidInfo.supportedAbis.first);
      } else {
        download('ios');
      }
    } catch (_) {
      launchURL('https://github.com/bggRGjQaUbCoE/PiliPlus/releases/latest');
    }
  }

  static void appSign(Map<String, dynamic> params,
      [String appkey = Constants.appKey, String appsec = Constants.appSec]) {
    params['appkey'] = appkey;
    var searchParams = Uri(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString()))).query;
    var sortedQueryString = (searchParams.split('&')..sort()).join('&');

    params['sign'] = md5
        .convert(utf8.encode(sortedQueryString + appsec))
        .toString(); // 获取MD5哈希值
  }

  static List<int> generateRandomBytes(int minLength, int maxLength) {
    return List<int>.generate(
      minLength + random.nextInt(maxLength - minLength + 1),
      (_) => 0x26 + random.nextInt(0x59), // dm_img_str不能有`%`
    );
  }

  static String base64EncodeRandomString(int minLength, int maxLength) {
    final randomBytes = generateRandomBytes(minLength, maxLength);
    final randomBase64 = base64.encode(randomBytes);
    return randomBase64.substring(0, randomBase64.length - 2);
  }

  static String getFileName(String uri, {bool fileExt = true}) {
    final i0 = uri.lastIndexOf('/') + 1;
    final i1 = fileExt ? uri.length : uri.lastIndexOf('.');
    return uri.substring(i0, i1);
  }

  static String genBuvid3() {
    return '${const UuidV4().generate().toUpperCase()}${random.nextInt(100000).toString().padLeft(5, "0")}infoc';
  }
}
