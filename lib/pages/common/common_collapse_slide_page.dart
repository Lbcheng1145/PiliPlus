import 'package:PiliPlus/pages/common/common_slide_page.dart';
import 'package:flutter/material.dart';

abstract class CommonCollapseSlidePage extends CommonSlidePage {
  const CommonCollapseSlidePage({super.key, super.enableSlide});
}

abstract class CommonCollapseSlidePageState<T extends CommonCollapseSlidePage>
    extends CommonSlidePageState<T> {
  late bool _isInit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInit = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInit) {
      return CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
      );
    }

    return super.build(context);
  }
}
