import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/refresh_indicator.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/space_fav/datum.dart';
import 'package:PiliPlus/models/space_fav/list.dart';
import 'package:PiliPlus/pages/member_favorite/controller.dart';
import 'package:PiliPlus/pages/member_favorite/widget/item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MemberFavorite extends StatefulWidget {
  const MemberFavorite({
    super.key,
    required this.heroTag,
    required this.mid,
  });

  final String? heroTag;
  final int mid;

  @override
  State<MemberFavorite> createState() => _MemberFavoriteState();
}

class _MemberFavoriteState extends State<MemberFavorite>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final _controller = Get.put(
    MemberFavoriteCtr(mid: widget.mid),
    tag: widget.heroTag,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => _buildBody(_controller.loadingState.value));
  }

  Widget _buildBody(LoadingState loadingState) {
    final theme = Theme.of(context);
    return switch (loadingState) {
      Loading() => loadingWidget,
      Success() => (loadingState.response as List?)?.isNotEmpty == true
          ? refreshIndicator(
              onRefresh: _controller.onRefresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _buildItem(theme, _controller.first.value, true),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _buildItem(theme, _controller.second.value, false),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80 + MediaQuery.of(context).padding.bottom,
                    ),
                  )
                ],
              ),
            )
          : scrollErrorWidget(
              onReload: _controller.onReload,
            ),
      Error() => scrollErrorWidget(
          errMsg: loadingState.errMsg,
          onReload: _controller.onReload,
        ),
    };
  }

  Theme _buildItem(ThemeData theme, SpaceFavData data, bool isFirst) {
    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        dense: true,
        initiallyExpanded: true,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: data.name,
                style: const TextStyle(fontSize: 14),
              ),
              TextSpan(
                text: ' ${data.mediaListResponse?.count}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        children: [
          ...(data.mediaListResponse?.list as List<FavList>).map(
            (item) => SizedBox(
              height: 98,
              child: MemberFavItem(
                item: item,
                callback: (res) {
                  if (res == true) {
                    _controller.first.value.mediaListResponse?.list
                        ?.remove(item);
                    _controller.first.refresh();
                  }
                },
              ),
            ),
          ),
          Obx(
            () => (isFirst
                    ? _controller.firstEnd.value
                    : _controller.secondEnd.value)
                ? const SizedBox.shrink()
                : _buildLoadMoreItem(theme, isFirst),
          ),
        ],
      ),
    );
  }

  ListTile _buildLoadMoreItem(ThemeData theme, bool isFirst) {
    return ListTile(
      dense: true,
      onTap: () {
        if (isFirst) {
          _controller.userfavFolder();
        } else {
          _controller.userSubFolder();
        }
      },
      title: Text(
        '查看更多内容',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
