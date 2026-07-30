import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart';

import '../../../constant/constant.dart';
import '../../../themes/app_them_data.dart';
import '../provider/restaurant_details_provider.dart';

Widget buildFloatingActionButton(
  RestaurantDetailsProvider controller,
  _showTitle,
  _scrollController,
  _MenuModal,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: Constant.animationDuration,
        child: IgnorePointer(
          ignoring: !_showTitle,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppThemeData.primary300,
              borderRadius: BorderRadius.circular(28),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppThemeData.grey50,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      FloatingActionButton(
        onPressed: () => _MenuModal.show(context),
        backgroundColor: Colors.black,
        child: SvgPicture.asset(
          'assets/images/menu.svg',
          width: 44,
          height: 44,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    ],
  );
}
