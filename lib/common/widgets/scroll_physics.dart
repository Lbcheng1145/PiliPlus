import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';

Widget videoTabBarView({
  required List<Widget> children,
  TabController? controller,
}) =>
    TabBarView(
      physics: const CustomTabBarViewClampingScrollPhysics(),
      controller: controller,
      children: children,
    );

Widget tabBarView({
  required List<Widget> children,
  TabController? controller,
}) =>
    TabBarView(
      physics: const CustomTabBarViewScrollPhysics(),
      controller: controller,
      children: children,
    );

class CustomTabBarViewScrollPhysics extends ScrollPhysics {
  const CustomTabBarViewScrollPhysics({super.parent});

  @override
  CustomTabBarViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomTabBarViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => CustomSpringDescription();
}

class CustomTabBarViewClampingScrollPhysics extends ClampingScrollPhysics {
  const CustomTabBarViewClampingScrollPhysics({super.parent});

  @override
  CustomTabBarViewClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomTabBarViewClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => CustomSpringDescription();
}

class MemberVideoScrollPhysics extends AlwaysScrollableScrollPhysics {
  const MemberVideoScrollPhysics({super.parent});

  @override
  MemberVideoScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MemberVideoScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    if (newPosition.maxScrollExtent < oldPosition.maxScrollExtent) {
      return 0;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}

class CustomSpringDescription implements SpringDescription {
  static final List<double> springDescription = Pref.springDescription;

  @override
  final mass = springDescription[0];

  @override
  final stiffness = springDescription[1];

  @override
  final damping = springDescription[2];

  CustomSpringDescription._();

  static final _instance = CustomSpringDescription._();

  factory CustomSpringDescription() => _instance;

  /// Defaults to 0.
  @override
  double bounce = 0.0;

  /// Defaults to 0.5 seconds.
  @override
  Duration duration = const Duration(milliseconds: 500);
}
