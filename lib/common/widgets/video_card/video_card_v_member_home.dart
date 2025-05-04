import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/space/item.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';

// 视频卡片 - 垂直布局
class VideoCardVMemberHome extends StatelessWidget {
  final SpaceItem videoItem;

  const VideoCardVMemberHome({
    super.key,
    required this.videoItem,
  });

  Future<void> onPushDetail(heroTag) async {
    String? goto = videoItem.goto;
    switch (goto) {
      case 'bangumi':
        PageUtils.viewBangumi(epId: videoItem.param);
        break;
      case 'av':
        if (videoItem.isPgc == true && videoItem.uri?.isNotEmpty == true) {
          if (PageUtils.viewPgcFromUri(videoItem.uri!)) {
            return;
          }
        }
        String? aid = videoItem.param;
        String? bvid = videoItem.bvid;
        if (aid == null && bvid == null) {
          return;
        }
        int? cid = videoItem.firstCid;
        cid ??= await SearchHttp.ab2c(aid: aid, bvid: bvid);
        PageUtils.toVideoPage(
          'bvid=${bvid ?? IdUtils.av2bv(int.parse(aid!))}&cid=$cid',
          arguments: {
            'pic': videoItem.cover,
            'heroTag': heroTag,
          },
        );
        break;
      default:
        if (videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => onPushDetail(Utils.makeHeroTag(videoItem.bvid)),
        onLongPress: () => imageSaveDialog(
          title: videoItem.title,
          cover: videoItem.cover,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: StyleString.aspectRatio,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  double maxWidth = boxConstraints.maxWidth;
                  double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: videoItem.cover,
                        width: maxWidth,
                        height: maxHeight,
                      ),
                      if ((videoItem.duration ?? -1) > 0)
                        PBadge(
                          bottom: 6,
                          right: 7,
                          size: 'small',
                          type: 'gray',
                          text: Utils.timeFormat(videoItem.duration),
                        )
                    ],
                  );
                },
              ),
            ),
            videoContent(context, videoItem)
          ],
        ),
      ),
    );
  }
}

Widget videoContent(BuildContext context, SpaceItem videoItem) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: Text(
        '${videoItem.title}\n',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          height: 1.38,
        ),
      ),
    ),
  );
}
