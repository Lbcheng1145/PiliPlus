import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/models/msg/account.dart';
import 'package:PiliPlus/models/msg/session.dart';

import '../../models/msg/msgfeed_unread.dart';
import '../../utils/storage.dart';

class WhisperController extends GetxController {
  RxList<SessionList> sessionList = <SessionList>[].obs;
  RxList<AccountListModel> accountList = <AccountListModel>[].obs;
  bool isLoading = false;
  Rx<MsgFeedUnread> msgFeedUnread = MsgFeedUnread().obs;
  RxList msgFeedTop = [
    {
      "name": "回复我的",
      "icon": Icons.message_outlined,
      "route": "/replyMe",
      "enabled": true,
      "value": 0
    },
    {
      "name": "@我",
      "icon": Icons.alternate_email_outlined,
      "route": "/atMe",
      "enabled": true,
      "value": 0
    },
    {
      "name": "收到的赞",
      "icon": Icons.favorite_border_outlined,
      "route": "/likeMe",
      "enabled": true,
      "value": 0
    },
    {
      "name": "系统通知",
      "icon": Icons.notifications_none_outlined,
      "route": "/sysMsg",
      "enabled": true,
      "value": 0
    },
  ].obs;

  Future queryMsgFeedUnread() async {
    var res = await MsgHttp.msgFeedUnread();
    if (res['status']) {
      msgFeedUnread.value = MsgFeedUnread.fromJson(res['data']);
      msgFeedTop[0]["value"] = msgFeedUnread.value.reply;
      msgFeedTop[1]["value"] = msgFeedUnread.value.at;
      msgFeedTop[2]["value"] = msgFeedUnread.value.like;
      msgFeedTop[3]["value"] = msgFeedUnread.value.sys_msg;
      if (GStorage.setting
          .get(SettingBoxKey.disableLikeMsg, defaultValue: false)) {
        msgFeedTop[2]["value"] = -1;
        msgFeedTop[2]["enabled"] = false;
      }
      // 触发更新
      msgFeedTop.refresh();
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  Future onRemove(int index) async {
    var res = await MsgHttp.removeMsg(sessionList[index].talkerId);
    if (res['status']) {
      sessionList.removeAt(index);
      SmartDialog.showToast('删除成功');
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  Future onSetTop(int index) async {
    bool isTop = sessionList[index].topTs != 0;
    var res = await MsgHttp.setTop(
      sessionList[index].talkerId,
      isTop ? 1 : 0,
    );
    if (res['status']) {
      List<SessionList> list = sessionList.map((item) {
        if (item.talkerId == sessionList[index].talkerId) {
          return item..topTs = isTop ? 0 : 1;
        } else {
          return item;
        }
      }).toList();
      if (!isTop) {
        SessionList item = list.removeAt(index);
        list.insert(0, item);
      }
      sessionList.value = list;
      SmartDialog.showToast('${isTop ? '移除' : ''}置顶成功');
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  Future querySessionList(String? type) async {
    if (isLoading) return;
    var res = await MsgHttp.sessionList(
      endTs: type == 'onLoad' ? sessionList.last.sessionTs : null,
    );
    if (res['status']) {
      List<SessionList>? sessionList = res['data'];
      if (sessionList != null) {
        if (sessionList.isNotEmpty) {
          await queryAccountList(sessionList);
          // 将 accountList 转换为 Map 结构
          Map<int, dynamic> accountMap = {};
          for (var j in accountList) {
            accountMap[j.mid!] = j;
          }

          // 遍历 sessionList，通过 mid 查找并赋值 accountInfo
          for (var i in sessionList) {
            var accountInfo = accountMap[i.talkerId];
            if (accountInfo != null) {
              i.accountInfo = accountInfo;
            }
            if (i.talkerId == 844424930131966) {
              i.accountInfo = AccountListModel(
                name: 'UP主小助手',
                face:
                    'https://message.biliimg.com/bfs/im/489a63efadfb202366c2f88853d2217b5ddc7a13.png',
              );
            }
          }
        }

        if (type == 'onLoad') {
          this.sessionList.addAll(sessionList);
        } else {
          this.sessionList.value = sessionList;
        }
      }
    }
    isLoading = false;
    return res;
  }

  Future queryAccountList(List<SessionList> sessionList) async {
    List<int?> midsList = sessionList.map((e) => e.talkerId).toList();
    var res = await MsgHttp.accountList(midsList.join(','));
    if (res['status']) {
      accountList.value = res['data'];
    }
  }

  Future onLoad() async {
    querySessionList('onLoad');
  }

  Future onRefresh() async {
    querySessionList('onRefresh');
  }
}
