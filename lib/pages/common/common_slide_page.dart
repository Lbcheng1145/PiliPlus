import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class CommonSlidePage extends StatefulWidget {
  const CommonSlidePage({super.key, this.enableSlide});

  final bool? enableSlide;
}

abstract class CommonSlidePageState<T extends CommonSlidePage>
    extends State<T> {
  Offset? downPos;
  bool? isSliding;
  late double padding = 0.0;

  late final enableSlide =
      widget.enableSlide != false && GStorage.slideDismissReplyPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return enableSlide
        ? Padding(
            padding: EdgeInsets.only(top: padding),
            child: buildPage(theme),
          )
        : buildPage(theme);
  }

  Widget buildPage(ThemeData theme);

  Widget buildList(ThemeData theme) => throw UnimplementedError();

  Widget slideList(ThemeData theme, [Widget? buildList]) => GestureDetector(
        onPanDown: (event) {
          if (event.localPosition.dx > 30) {
            isSliding = false;
          } else {
            downPos = event.localPosition;
          }
        },
        onPanUpdate: (event) {
          if (isSliding == false) {
            return;
          } else if (isSliding == null) {
            if (downPos != null) {
              Offset cumulativeDelta = event.localPosition - downPos!;
              if (cumulativeDelta.dx.abs() >= cumulativeDelta.dy.abs()) {
                isSliding = true;
                setState(() {
                  padding = event.localPosition.dx.abs();
                });
              } else {
                isSliding = false;
              }
            }
          } else if (isSliding == true) {
            setState(() {
              padding = event.localPosition.dx.abs();
            });
          }
        },
        onPanCancel: () {
          if (isSliding == true) {
            if (padding >= 100) {
              Get.back();
            } else {
              setState(() {
                padding = 0;
              });
            }
          }
          downPos = null;
          isSliding = null;
        },
        onPanEnd: (event) {
          if (isSliding == true) {
            if (padding >= 100) {
              Get.back();
            } else {
              setState(() {
                padding = 0;
              });
            }
          }
          downPos = null;
          isSliding = null;
        },
        child: buildList ?? this.buildList(theme),
      );
}
