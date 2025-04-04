import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/grpc/app/main/community/reply/v1/reply.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/reply.dart';
import 'package:PiliPlus/models/common/reply_type.dart';
import 'package:PiliPlus/models/video/reply/data.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/pages/video/detail/reply_new/reply_page.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/models/common/reply_sort_type.dart';
import 'package:PiliPlus/models/video/reply/item.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:get/get_navigation/src/dialog/dialog_route.dart';

abstract class ReplyController extends CommonController {
  String nextOffset = '';
  RxInt count = (-1).obs;

  Rx<ReplySortType> sortType = ReplySortType.time.obs;

  late final savedReplies = {};

  late final bool isLogin = Accounts.main.isLogin;

  CursorReply? cursor;
  late Rx<Mode> mode = Mode.MAIN_LIST_HOT.obs;
  late bool hasUpTop = false;

  late final antiGoodsReply = GStorage.antiGoodsReply;

  // comment antifraud
  late final _enableCommAntifraud = GStorage.enableCommAntifraud;
  late final _biliSendCommAntifraud = GStorage.biliSendCommAntifraud;
  bool get enableCommAntifraud =>
      _enableCommAntifraud || _biliSendCommAntifraud;
  dynamic get sourceId;

  @override
  void onInit() {
    super.onInit();
    int defaultReplySortIndex = GStorage.setting
        .get(SettingBoxKey.replySortType, defaultValue: 1) as int;
    if (defaultReplySortIndex == 2) {
      GStorage.setting.put(SettingBoxKey.replySortType, 0);
      defaultReplySortIndex = 0;
    }
    sortType.value = ReplySortType.values[defaultReplySortIndex];
    if (sortType.value == ReplySortType.time) {
      mode.value = Mode.MAIN_LIST_TIME;
    }
  }

  @override
  Future onRefresh() {
    cursor = null;
    nextOffset = '';
    return super.onRefresh();
  }

  @override
  bool customHandleResponse(Success response) {
    MainListReply replies = response.response;
    if (cursor == null) {
      count.value = replies.subjectControl.count.toInt();
      hasUpTop = replies.hasUpTop();
      if (replies.hasUpTop()) {
        replies.replies.insert(0, replies.upTop);
      }
    }
    cursor = replies.cursor;
    if (currentPage != 1 && loadingState.value is Success) {
      replies.replies
          .insertAll(0, (loadingState.value as Success).response.replies);
    }
    isEnd = replies.replies.isEmpty ||
        replies.cursor.isEnd ||
        replies.replies.length >= count.value;
    loadingState.value = LoadingState.success(replies);

    return true;
  }

  // 排序搜索评论
  queryBySort() {
    EasyThrottle.throttle('queryBySort', const Duration(seconds: 1), () {
      feedBack();
      switch (sortType.value) {
        case ReplySortType.time:
          sortType.value = ReplySortType.like;
          mode.value = Mode.MAIN_LIST_HOT;
          break;
        case ReplySortType.like:
          sortType.value = ReplySortType.time;
          mode.value = Mode.MAIN_LIST_TIME;
          break;
      }
      nextOffset = '';
      onReload();
    });
  }

  void onReply(
    BuildContext context, {
    dynamic oid,
    dynamic replyItem,
    int index = 0,
    ReplyType? replyType,
  }) {
    String? hint;
    try {
      if (loadingState.value is Success) {
        SubjectControl subjectControl =
            (loadingState.value as Success).response.subjectControl;
        if (subjectControl.hasSwitcherType() &&
            subjectControl.switcherType != 1 &&
            subjectControl.hasRootText()) {
          hint = subjectControl.rootText;
        }
      }
    } catch (_) {}
    dynamic key = oid ?? replyItem.oid + replyItem.id;
    Navigator.of(context)
        .push(
      GetDialogRoute(
        pageBuilder: (buildContext, animation, secondaryAnimation) {
          return ReplyPage(
            oid: oid ?? replyItem.oid.toInt(),
            root: oid != null ? 0 : replyItem.id.toInt(),
            parent: oid != null ? 0 : replyItem.id.toInt(),
            replyType: replyItem != null
                ? ReplyType.values[replyItem.type.toInt()]
                : replyType,
            replyItem: replyItem,
            initialValue: savedReplies[key],
            onSave: (reply) {
              savedReplies[key] = reply;
            },
            hint: hint,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.linear;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    )
        .then(
      (res) {
        if (res != null) {
          savedReplies[key] = null;
          ReplyInfo replyInfo = Utils.replyCast(res);
          MainListReply response = loadingState.value is Success
              ? (loadingState.value as Success).response
              : MainListReply();
          if (oid != null) {
            response.replies.insert(hasUpTop ? 1 : 0, replyInfo);
          } else {
            response.replies[index].replies.add(replyInfo);
          }
          count.value += 1;
          loadingState.value = LoadingState.success(response);
          if (enableCommAntifraud && context.mounted) {
            checkReply(
              context: context,
              oid: oid ?? replyItem.oid.toInt(),
              rpid: replyItem?.id.toInt(),
              replyType: replyItem?.type.toInt() ??
                  replyType?.index ??
                  ReplyType.video.index,
              replyId: replyInfo.id.toInt(),
              message: replyInfo.content.message,
              //
              root: replyInfo.root.toInt(),
              parent: replyInfo.parent.toInt(),
              ctime: replyInfo.ctime.toInt(),
              pictures: replyInfo.content.pictures
                  .map((item) => item.toProto3Json())
                  .toList(),
              mid: replyInfo.mid.toInt(),
            );
          }
        }
      },
    );
  }

  onMDelete(rpid, frpid) {
    MainListReply response = (loadingState.value as Success).response;
    if (frpid == null) {
      response.replies.removeWhere((item) {
        return item.id.toInt() == rpid;
      });
    } else {
      response.replies.map((item) {
        if (item.id == frpid) {
          return item..replies.removeWhere((reply) => reply.id.toInt() == rpid);
        } else {
          return item;
        }
      }).toList();
    }
    count.value -= 1;
    loadingState.value = LoadingState.success(response);
  }

  void onCheckReply(context, item) {
    try {
      if (item is ReplyInfo) {
        checkReply(
          context: context,
          oid: item.oid.toInt(),
          rpid: item.hasRoot() ? item.root.toInt() : null,
          replyType: item.type.toInt(),
          replyId: item.id.toInt(),
          message: item.content.message,
          //
          root: item.root.toInt(),
          parent: item.parent.toInt(),
          ctime: item.ctime.toInt(),
          pictures:
              item.content.pictures.map((item) => item.toProto3Json()).toList(),
          mid: item.mid.toInt(),
          //
          isManual: true,
        );
      } else if (item is ReplyItemModel) {
        checkReply(
          context: context,
          oid: item.oid,
          rpid: item.root == 0 ? null : item.root,
          replyType: item.type!,
          replyId: item.rpid!,
          message: item.content!.message!,
          //
          root: item.root,
          parent: item.parent,
          ctime: item.ctime,
          pictures: item.content?.pictures,
          mid: item.mid,
          //
          isManual: true,
        );
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  // ref https://github.com/freedom-introvert/biliSendCommAntifraud
  void checkReply({
    required BuildContext context,
    required dynamic oid,
    required dynamic rpid,
    required int replyType,
    required int replyId,
    required String message,
    dynamic root,
    dynamic parent,
    dynamic ctime,
    List? pictures,
    dynamic mid,
    bool isManual = false,
  }) async {
    // biliSendCommAntifraud
    if (Platform.isAndroid && _biliSendCommAntifraud) {
      try {
        final String cookieString = Accounts.main.cookieJar
            .toJson()
            .entries
            .map((i) => '${i.key}=${i.value}')
            .join(';');
        Utils.channel.invokeMethod(
          'biliSendCommAntifraud',
          {
            'action': 0,
            'oid': oid,
            'type': replyType,
            'rpid': replyId,
            'root': root,
            'parent': parent,
            'ctime': ctime,
            'comment_text': message,
            if (pictures?.isNotEmpty == true) 'pictures': jsonEncode(pictures),
            'source_id': '$sourceId',
            'uid': mid,
            'cookies': [cookieString],
          },
        );
      } catch (e) {
        debugPrint('biliSendCommAntifraud: $e');
      }
      return;
    }

    // CommAntifraud
    if (isManual.not) {
      await Future.delayed(const Duration(seconds: 5));
    }
    void showReplyCheckResult(String message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('评论检查结果'),
          content: SelectableText(message),
        ),
      );
    }

    if (context.mounted.not) return;
    // root reply
    if (rpid == null) {
      // no cookie check
      dynamic res = await ReplyHttp.replyList(
        isLogin: false,
        oid: oid,
        nextOffset: '',
        type: replyType,
        sort: ReplySortType.time.index,
        page: 1,
        enableFilter: false,
        antiGoodsReply: false,
      );
      if (context.mounted.not) return;
      if (res is Error) {
        SmartDialog.showToast('获取评论主列表时发生错误：${res.errMsg}');
        return;
      } else if (res is Success) {
        ReplyData replies = res.response;
        int index =
            replies.replies?.indexWhere((item) => item.rpid == replyId) ?? -1;
        if (index != -1) {
          // found
          if (context.mounted) {
            showReplyCheckResult(
              '无账号状态下找到了你的评论，评论正常！\n\n你的评论：$message',
            );
          }
        } else {
          // not found
          if (context.mounted.not) return;
          // cookie check
          dynamic res1 = await ReplyHttp.replyReplyList(
            isLogin: isLogin,
            oid: oid,
            root: rpid ?? replyId,
            pageNum: 1,
            type: replyType,
            filterBanWord: false,
            antiGoodsReply: false,
          );
          if (context.mounted.not) return;
          if (res1 is Error) {
            // not found
            if (context.mounted) {
              showReplyCheckResult(
                '无法找到你的评论。\n\n你的评论：$message',
              );
            }
          } else if (res1 is Success) {
            // found
            if (context.mounted.not) return;
            // no cookie check
            dynamic res2 = await ReplyHttp.replyReplyList(
              isLogin: false,
              oid: oid,
              root: rpid ?? replyId,
              pageNum: 1,
              type: replyType,
              filterBanWord: false,
              isCheck: true,
              antiGoodsReply: false,
            );
            if (context.mounted.not) return;
            if (res2 is Error) {
              // not found
              if (context.mounted) {
                showReplyCheckResult(
                  res2.errMsg.startsWith('12022')
                      ? '你的评论被shadow ban（仅自己可见）！\n\n你的评论: $message'
                      : '评论不可见(${res2.errMsg}): $message',
                );
              }
            } else if (res2 is Success) {
              // found
              if (context.mounted) {
                showReplyCheckResult(isManual
                    ? '无账号状态下找到了你的评论，评论正常！\n\n你的评论：$message'
                    : '''
你评论状态有点可疑，虽然无账号翻找评论区获取不到你的评论，但是无账号可通过
https://api.bilibili.com/x/v2/reply/reply?oid=$oid&pn=1&ps=20&root=${rpid ?? replyId}&type=$replyType
获取你的评论，疑似评论区被戒严或者这是你的视频。

你的评论：$message''');
              }
            }
          }
        }
      }
    } else {
      for (int i = 1; true; i++) {
        if (context.mounted.not) return;
        dynamic res3 = await ReplyHttp.replyReplyList(
          isLogin: false,
          oid: oid,
          root: rpid ?? replyId,
          pageNum: i,
          type: replyType,
          filterBanWord: false,
          isCheck: true,
          antiGoodsReply: false,
        );
        if (res3 is Error) {
          break;
        } else if (res3 is Success) {
          ReplyReplyData data = res3.response;
          if (data.replies.isNullOrEmpty) {
            break;
          }
          int index =
              data.replies?.indexWhere((item) => item.rpid == replyId) ?? -1;
          if (index == -1) {
            // not found
          } else {
            // found
            if (context.mounted) {
              showReplyCheckResult(
                '无账号状态下找到了你的评论，评论正常！\n\n你的评论：$message',
              );
            }
            return;
          }
        }
      }

      for (int i = 1; true; i++) {
        if (context.mounted.not) return;
        dynamic res4 = await ReplyHttp.replyReplyList(
          isLogin: true,
          oid: oid,
          root: rpid ?? replyId,
          pageNum: i,
          type: replyType,
          filterBanWord: false,
          isCheck: true,
          antiGoodsReply: false,
        );
        if (res4 is Error) {
          break;
        } else if (res4 is Success) {
          ReplyReplyData data = res4.response;
          if (data.replies.isNullOrEmpty) {
            break;
          }
          int index =
              data.replies?.indexWhere((item) => item.rpid == replyId) ?? -1;
          if (index == -1) {
            // not found
          } else {
            // found
            if (context.mounted) {
              showReplyCheckResult(
                '你的评论被shadow ban（仅自己可见）！\n\n你的评论: $message',
              );
            }
            return;
          }
        }
      }

      if (context.mounted) {
        showReplyCheckResult(
          '评论不可见: $message',
        );
      }
    }
  }

  void onToggleTop(index, oid, int type, bool isUpTop, int rpid) async {
    final res = await ReplyHttp.replyTop(
      oid: oid,
      type: type,
      rpid: rpid,
      isUpTop: isUpTop,
    );
    if (res['status']) {
      final data = (loadingState.value as Success).response;
      if (data is MainListReply) {
        data.replies[index].replyControl.isUpTop = !isUpTop;
        if (!isUpTop && index != 0) {
          data.replies[0].replyControl.isUpTop = false;
          final item = data.replies.removeAt(index);
          data.replies.insert(0, item);
        }
        loadingState.value = LoadingState.success(data);
      }
      SmartDialog.showToast('${isUpTop ? '取消' : ''}置顶成功');
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }
}
